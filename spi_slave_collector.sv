package spi_slave_collector_package;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import spi_slave_seq_item_package::*;
    import shared_pkg::*;
    
class spi_slave_coverage extends uvm_component;
    `uvm_component_utils(spi_slave_coverage)

    uvm_analysis_export #(spi_slave_seq_item) coverage_export;
    uvm_tlm_analysis_fifo #(spi_slave_seq_item) coverage_fifo;
    spi_slave_seq_item coverage_item;
    
    covergroup functional_coverage;
        receiver_data: coverpoint coverage_item.rx_data[9:8];
        ss_n_general_cases : coverpoint coverage_item.SS_n {
            bins transaction_complete = (1 => 0[*13] => 1);
        }
        ss_n_read_operations : coverpoint coverage_item.SS_n {
            bins read_transaction = (1 => 0[*23] => 1);
        }
        ss_n_active : coverpoint coverage_item.SS_n {
            bins slave_select_active = {0};
        }
        mosi_patterns: coverpoint coverage_item.MOSI {
            bins write_address_cmd = (0 => 0 => 0);
            bins write_data_cmd = (0 => 0 => 1);
            bins read_address_cmd = (1 => 1 => 0);
            bins read_data_cmd = (1 => 1 => 1);
        }
        cross_mosi_ss_combinations : cross mosi_patterns, ss_n_active {
            option.cross_auto_bin_max = 0;
            bins write_addr_active = binsof(ss_n_active.slave_select_active) && binsof(mosi_patterns.write_address_cmd);
            bins write_data_active = binsof(ss_n_active.slave_select_active) && binsof(mosi_patterns.write_data_cmd);
            bins read_addr_active = binsof(ss_n_active.slave_select_active) && binsof(mosi_patterns.read_address_cmd);
            bins read_data_active = binsof(ss_n_active.slave_select_active) && binsof(mosi_patterns.read_data_cmd);
        }
    endgroup

    function new(string name = "spi_slave_coverage", uvm_component parent = null);
        super.new(name, parent);
        functional_coverage = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        coverage_export = new("coverage_export", this);
        coverage_fifo = new("coverage_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        coverage_export.connect(coverage_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin 
            coverage_fifo.get(coverage_item);
            functional_coverage.sample();
        end
    endtask

endclass
endpackage