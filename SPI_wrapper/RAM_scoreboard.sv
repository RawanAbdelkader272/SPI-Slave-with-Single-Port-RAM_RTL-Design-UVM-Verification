package RAM_scoreboard_pkg;
    import RAM_seq_item_pkg::*;
    import RAM_config_obj_pkg::*;    
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class RAM_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(RAM_scoreboard)

        uvm_analysis_export   #(RAM_seq_item) sb_export;
        uvm_tlm_analysis_fifo #(RAM_seq_item) sb_fifo;

        RAM_seq_item seq_item_sb;
        RAM_config_obj cfg;

        // reference model state
        logic [7:0] ref_mem [256];
        logic [7:0] w_addr;
        logic [7:0] r_addr;
        logic [7:0] dout_ref;
        logic       tx_valid_ref;
        logic [3:0] tx_cnt_ref;   // tx_valid is high for 9 cycles after a read data command

        int error_count;
        int correct_count;

        function new(string name = "RAM_scoreboard", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            sb_export = new("sb_export", this);
            sb_fifo   = new("sb_fifo", this);
            if (!uvm_config_db #(RAM_config_obj)::get(this, "", "CFG", cfg))
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

        //------------------------- reference model (approved) -------------------------//
        function void ref_model(RAM_seq_item item);
            if (!item.rst_n) begin
                dout_ref     = 8'h00;
                tx_valid_ref = 1'b0;
                tx_cnt_ref   = 4'd0;
                r_addr       = 8'h00;
                w_addr       = 8'h00;
            end
            else begin
                if (item.rx_valid && (item.din[9:8] == 2'b11)) begin
                    tx_valid_ref = 1'b1;
                    tx_cnt_ref   = 4'd8;
                end
                else begin
                    tx_valid_ref = (tx_cnt_ref != 4'd0);
                    if (tx_cnt_ref != 4'd0) tx_cnt_ref = tx_cnt_ref - 4'd1;
                end
                if (item.rx_valid) begin
                    case (item.din[9:8])
                        2'b00:   w_addr          = item.din[7:0];
                        2'b01:   ref_mem[w_addr] = item.din[7:0];
                        2'b10:   r_addr          = item.din[7:0];
                        2'b11: begin
                            dout_ref     = ref_mem[r_addr];
                        end
                    endcase
                end
            end
            
            cfg.RAM_vif.dout_ref     = dout_ref;
            cfg.RAM_vif.tx_valid_ref = tx_valid_ref;

        endfunction

        //--------------------------------- checker ---------------------------------//
        function void compare(RAM_seq_item item);
             cfg.RAM_vif.mismatch = (item.dout !== dout_ref) || (item.tx_valid !== tx_valid_ref);

            if ((item.dout !== dout_ref) || (item.tx_valid !== tx_valid_ref)) begin
                error_count++;
                `uvm_error("SB", $sformatf("Mismatch: DUT dout=0x%0h tx_valid=%0b | REF dout=0x%0h tx_valid=%0b | %s",
                           item.dout, item.tx_valid, dout_ref, tx_valid_ref, item.convert2string()))
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