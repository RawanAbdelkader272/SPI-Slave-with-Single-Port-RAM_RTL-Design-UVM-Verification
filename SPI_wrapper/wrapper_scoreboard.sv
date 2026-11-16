package wrapper_scoreboard_pkg;
    import wrapper_seq_item_pkg::*;
    import wrapper_config_obj_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class wrapper_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(wrapper_scoreboard)

        uvm_analysis_export   #(wrapper_seq_item) sb_export;
        uvm_tlm_analysis_fifo #(wrapper_seq_item) sb_fifo;

        wrapper_seq_item  seq_item_sb;
        wrapper_config_obj cfg;

        //---------------- golden model state ----------------//
        typedef enum logic [2:0] {ST_IDLE = 3'b000, ST_CHK_CMD = 3'b001, ST_WRITE = 3'b010,
                                  ST_READ_ADDR = 3'b011, ST_READ_DATA = 3'b100} state_e;

        // SPI slave part
        state_e     cs;
        logic       address_read_flag;
        logic [3:0] bit_counter;
        logic [9:0] rx_data;
        logic       rx_valid;
        logic       MISO_ref;
        // RAM part
        logic [7:0] ref_mem [256];
        logic [7:0] w_addr;
        logic [7:0] r_addr;
        logic [7:0] dout_ref;
        logic       tx_valid_ref;
        logic [3:0] tx_cnt_ref;   // tx_valid is high for 9 cycles after a read data command

        bit model_valid;   // set by the first reset, nothing is compared before it

        int error_count;
        int correct_count;

        function new(string name = "wrapper_scoreboard", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            sb_export = new("sb_export", this);
            sb_fifo   = new("sb_fifo", this);
            if (!uvm_config_db #(wrapper_config_obj)::get(this, "", "CFG_W", cfg))
                `uvm_fatal("SB", "Unable to get the config object")
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            sb_export.connect(sb_fifo.analysis_export);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                sb_fifo.get(seq_item_sb);
                ref_model(seq_item_sb);
                compare(seq_item_sb);
            end
        endtask

        //------------------------- golden model -------------------------//
        // Cycle accurate model of the SPI slave connected to the RAM. One call = one clock edge.
        // The item holds the pins sampled at the negedge: the inputs of the cycle that just ended
        // and the MISO that this cycle produced, so the model is stepped with the item's inputs
        // and compared with the item's MISO afterwards.
        function void ref_model(wrapper_seq_item item);
            state_e     ns;
            logic [9:0] o_rx_data;
            logic       o_rx_valid, o_tx_valid;
            logic [7:0] o_dout;

            // pins not driven yet (before the first item): nothing to model
            if ($isunknown({item.rst_n, item.SS_n, item.MOSI})) return;

            if (!item.rst_n) begin
                cs                = ST_IDLE;
                rx_data           = 10'h000;
                rx_valid          = 1'b0;
                address_read_flag = 1'b0;
                MISO_ref          = 1'b0;
                bit_counter       = 4'd0;
                dout_ref          = 8'h00;
                tx_valid_ref      = 1'b0;
                tx_cnt_ref        = 4'd0;
                r_addr            = 8'h00;
                w_addr            = 8'h00;
                model_valid       = 1'b1;
            end
            else if (model_valid) begin
                // values that both blocks see just before the clock edge
                o_rx_data  = rx_data;
                o_rx_valid = rx_valid;
                o_tx_valid = tx_valid_ref;
                o_dout     = dout_ref;

                // slave: next state (from the current state, flag and pins)
                case (cs)
                    ST_IDLE:      ns = item.SS_n ? ST_IDLE : ST_CHK_CMD;
                    ST_CHK_CMD:   begin
                                      if (item.SS_n)        ns = ST_IDLE;
                                      else if (!item.MOSI)  ns = ST_WRITE;
                                      else                  ns = address_read_flag ? ST_READ_DATA : ST_READ_ADDR;
                                  end
                    default:      ns = item.SS_n ? ST_IDLE : cs;   // WRITE, READ_ADDR, READ_DATA
                endcase

                // RAM
                if (o_rx_valid && (o_rx_data[9:8] == 2'b11)) begin
                    tx_valid_ref = 1'b1;
                    tx_cnt_ref   = 4'd8;
                end
                else begin
                    tx_valid_ref = (tx_cnt_ref != 4'd0);
                    if (tx_cnt_ref != 4'd0) tx_cnt_ref = tx_cnt_ref - 4'd1;
                end
                if (o_rx_valid) begin
                    case (o_rx_data[9:8])
                        2'b00:   w_addr          = o_rx_data[7:0];
                        2'b01:   ref_mem[w_addr] = o_rx_data[7:0];
                        2'b10:   r_addr          = o_rx_data[7:0];
                        2'b11:   dout_ref        = ref_mem[r_addr];
                    endcase
                end

                // slave: serial to parallel and parallel to serial
                case (cs)
                    ST_IDLE: rx_valid = 1'b0;
                    ST_CHK_CMD: bit_counter = 4'd10;
                    ST_WRITE: begin
                        if (bit_counter > 0) begin
                            rx_data[bit_counter-1] = item.MOSI;
                            bit_counter            = bit_counter - 1;
                        end
                        else rx_valid = 1'b1;
                    end
                    ST_READ_ADDR: begin
                        if (bit_counter > 0) begin
                            rx_data[bit_counter-1] = item.MOSI;
                            bit_counter            = bit_counter - 1;
                        end
                        else begin
                            rx_valid          = 1'b1;
                            address_read_flag = 1'b1;
                        end
                    end
                    ST_READ_DATA: begin
                        if (o_tx_valid) begin
                            if (bit_counter > 0) begin
                                MISO_ref    = o_dout[bit_counter-1];
                                bit_counter = bit_counter - 1;
                            end
                            else begin
                                address_read_flag = 1'b0;
                                rx_valid          = 1'b0;
                            end
                        end
                        else begin
                            if (bit_counter > 0) begin
                                rx_data[bit_counter-1] = item.MOSI;
                                bit_counter            = bit_counter - 1;
                            end
                            else begin
                                rx_valid    = 1'b1;
                                bit_counter = 4'd9;
                            end
                        end
                    end
                endcase
                cs = ns;
            end

            cfg.wrapper_vif.MISO_ref = MISO_ref;
        endfunction

        //--------------------------------- checker ---------------------------------//
        function void compare(wrapper_seq_item item);
            if (!model_valid) return;   // no reset yet, DUT outputs are still unknown
            cfg.wrapper_vif.mismatch = (item.MISO !== MISO_ref);

            if (item.MISO !== MISO_ref) begin
                error_count++;
                `uvm_error("SB", $sformatf("Mismatch: DUT MISO=%0b | REF MISO=%0b | %s",
                           item.MISO, MISO_ref, item.convert2string()))
            end
            else begin
                correct_count++;
                `uvm_info("SB", $sformatf("Match: %s", item.convert2string()), UVM_HIGH)
            end
        endfunction

        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("SB", $sformatf("Correct comparisons: %0d", correct_count), UVM_MEDIUM)
            `uvm_info("SB", $sformatf("Failed comparisons:  %0d", error_count),   UVM_MEDIUM)
        endfunction

    endclass
endpackage