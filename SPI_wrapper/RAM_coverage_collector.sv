package RAM_coverage_collector_pkg;
    import RAM_seq_item_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class RAM_coverage_collector extends uvm_component;
        `uvm_component_utils(RAM_coverage_collector)

        uvm_analysis_export   #(RAM_seq_item) cov_export;
        uvm_tlm_analysis_fifo #(RAM_seq_item) cov_fifo;

        RAM_seq_item RAM_item_cov;

        //-------------------------------- covergroup --------------------------------//
        covergroup RAM_din_ordering_cg;

            // 1) Transaction ordering on din[9:8] (accepted operations only)
            cp_din_cmd : coverpoint RAM_item_cov.din[9:8]
                         iff (RAM_item_cov.rst_n && RAM_item_cov.rx_valid) {
                bins wr_addr            = {2'b00};
                bins wr_data            = {2'b01};
                bins rd_addr            = {2'b10};
                bins rd_data            = {2'b11};

                bins wr_addr_to_wr_data = (2'b00 => 2'b01);
                bins rd_addr_to_rd_data = (2'b10 => 2'b11);
                bins full_seq           = (2'b00 => 2'b01 => 2'b10 => 2'b11);
            }

            // 2) Cross coverage (spec): rx_valid high, and read data with tx_valid high
            cp_din_val : coverpoint RAM_item_cov.din[9:8] iff (RAM_item_cov.rst_n) {
                bins wr_addr = {2'b00};
                bins wr_data = {2'b01};
                bins rd_addr = {2'b10};
                bins rd_data = {2'b11};
            }

            cp_rx_valid_high : coverpoint RAM_item_cov.rx_valid {
                bins high = {1'b1};
            }

            cp_tx_valid_high : coverpoint RAM_item_cov.tx_valid {
                bins high = {1'b1};
            }

            cross_din_rx_valid : cross cp_din_val, cp_rx_valid_high;

            cross_rd_data_tx_valid : cross cp_din_val, cp_tx_valid_high {
                ignore_bins not_rd_data = binsof(cp_din_val) intersect {2'b00, 2'b01, 2'b10};
            }

            // 3) Added: every command with rx_valid low as well as high (idle cycles)
            cp_rx_valid : coverpoint RAM_item_cov.rx_valid iff (RAM_item_cov.rst_n) {
                bins low  = {1'b0};
                bins high = {1'b1};
            }

            cross_din_rx_valid_all : cross cp_din_val, cp_rx_valid;

        endgroup
        //----------------------------------------------------------------------------//

        function new(string name = "RAM_coverage_collector", uvm_component parent = null);
            super.new(name, parent);
            RAM_din_ordering_cg = new();
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
                cov_fifo.get(RAM_item_cov);
                RAM_din_ordering_cg.sample();
            end
        endtask

    endclass
endpackage