package wrapper_coverage_collector_pkg;
    import wrapper_seq_item_pkg::*;
    import wrapper_shared_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class wrapper_coverage_collector extends uvm_component;
        `uvm_component_utils(wrapper_coverage_collector)

        uvm_analysis_export   #(wrapper_seq_item) cov_export;
        uvm_tlm_analysis_fifo #(wrapper_seq_item) cov_fifo;

        wrapper_seq_item item_cov;

        //---------------- frame tracking (one item = one clock cycle) ----------------//
        // low cycle 1 is ignored by the slave, low cycles 2..4 carry {command bit, din[9], din[8]}
        int         low_cycles;       // consecutive SS_n low cycles of the current frame
        logic [2:0] cmd_code;         // the 3 command bits of the current frame
        bit         read_window;      // inside a read data frame (command bits already received)
        bit         miso_seen;        // MISO was high at least once in the current read data frame
        bit         rst_mid_frame;    // a reset arrives while a frame is in progress
        bit         frame_done;       // a frame just ended, the frame coverpoints count
        cmd_e       frame_cmd;        // the finished frame
        int         frame_len;        // SS_n low cycles of the finished frame
        bit         frame_miso_seen;  // MISO was high in the finished frame

        //-------------------------------- covergroup --------------------------------//
        // sampled every clock cycle, the frame coverpoints (4, 5, 6) only count when a frame just ended
        covergroup wrapper_cg;

            // 1) reset mostly deasserted, and also asserted while idle and in the middle of a frame
            cp_rst : coverpoint item_cov.rst_n {
                bins asserted    = {0};
                bins deasserted  = {1};
                bins assert_edge = (1 => 0);
                bins release_edge = (0 => 1);
            }

            cp_rst_context : coverpoint rst_mid_frame iff (!item_cov.rst_n) {
                bins reset_while_idle      = {0};
                bins reset_during_a_frame  = {1};
            }

            // 2) SS_n: low for 13 cycles (23 for read data) and high for one cycle between frames
            cp_ss_n_general : coverpoint item_cov.SS_n {
                bins transaction_complete = (1 => 0[*13] => 1);
            }

            cp_ss_n_read : coverpoint item_cov.SS_n {
                bins read_transaction = (1 => 0[*23] => 1);
            }

            cp_ss_n_active : coverpoint item_cov.SS_n {
                bins slave_select_active = {0};
            }

            // 3) MISO while a read data frame is in progress
            cp_miso_read : coverpoint item_cov.MISO iff (read_window && !item_cov.SS_n && item_cov.rst_n) {
                bins low  = {0};
                bins high = {1};
                bins rise = (0 => 1);
                bins fall = (1 => 0);
            }

            // 4) operations and their ordering (frame after frame)
            cp_cmd : coverpoint frame_cmd iff (frame_done) {
                bins wr_addr = {WR_ADDR};
                bins wr_data = {WR_DATA};
                bins rd_addr = {RD_ADDR};
                bins rd_data = {RD_DATA};

                bins wr_addr_to_wr_addr = (WR_ADDR => WR_ADDR);
                bins wr_addr_to_wr_data = (WR_ADDR => WR_DATA);
                bins wr_data_to_wr_addr = (WR_DATA => WR_ADDR);
                bins wr_data_to_rd_addr = (WR_DATA => RD_ADDR);
                bins rd_addr_to_rd_data = (RD_ADDR => RD_DATA);
                bins rd_data_to_rd_addr = (RD_DATA => RD_ADDR);
                bins rd_data_to_wr_addr = (RD_DATA => WR_ADDR);
                bins full_seq           = (WR_ADDR => WR_DATA => RD_ADDR => RD_DATA);
            }

            cp_cmd_val : coverpoint frame_cmd iff (frame_done) {
                bins wr_addr = {WR_ADDR};
                bins wr_data = {WR_DATA};
                bins rd_addr = {RD_ADDR};
                bins rd_data = {RD_DATA};
            }

            // 5) frame length: 13 low cycles, 23 for read data
            cp_frame_len : coverpoint frame_len iff (frame_done) {
                bins normal    = {13};
                bins read_data = {23};
                bins other     = default;
            }

            cross_cmd_len : cross cp_cmd_val, cp_frame_len {
                ignore_bins rd_data_short = binsof(cp_cmd_val.rd_data) && binsof(cp_frame_len.normal);
                ignore_bins others_long   = !binsof(cp_cmd_val.rd_data) && binsof(cp_frame_len.read_data);
            }

            // 6) read data frames in which the slave really sent data (MISO high at least once)
            cp_miso_seen : coverpoint frame_miso_seen iff (frame_done && frame_cmd == RD_DATA) {
                bins no_data_bit = {0};
                bins data_bit    = {1};
            }

        endgroup
        //----------------------------------------------------------------------------//

        function new(string name = "wrapper_coverage_collector", uvm_component parent = null);
            super.new(name, parent);
            wrapper_cg = new();
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            cov_export = new("cov_export", this);
            cov_fifo   = new("cov_fifo", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            cov_export.connect(cov_fifo.analysis_export);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                cov_fifo.get(item_cov);
                track_frame(item_cov);
                wrapper_cg.sample();
            end
        endtask

        // follows the frames the slave sees, the same way the DUT counts them
        function void track_frame(wrapper_seq_item item);
            frame_done = 0;
            // pins not driven yet
            if ($isunknown({item.rst_n, item.SS_n, item.MOSI})) return;

            rst_mid_frame = (low_cycles > 0);

            if (!item.rst_n) begin
                // reset: the slave is back in IDLE, the frame in progress is lost
                low_cycles = 0;
                read_window = 0;
                miso_seen = 0;
            end
            else if (item.SS_n) begin
                // SS_n high: a frame that went past its command bits is finished
                if (low_cycles >= 4) begin
                    frame_cmd       = cmd_e'(cmd_code[1:0]);
                    frame_len       = low_cycles;
                    frame_miso_seen = miso_seen;
                    frame_done      = 1;
                end
                low_cycles  = 0;
                read_window = 0;
                miso_seen   = 0;
            end
            else begin
                low_cycles++;
                case (low_cycles)
                    2: cmd_code[2] = item.MOSI;
                    3: cmd_code[1] = item.MOSI;
                    4: cmd_code[0] = item.MOSI;
                    default: ;
                endcase
                if (low_cycles >= 4 && cmd_code == 3'b111) read_window = 1;
                if (read_window && item.MISO === 1'b1) miso_seen = 1;
            end
        endfunction

    endclass
endpackage