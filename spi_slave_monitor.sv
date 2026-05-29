package spi_slave_monitor_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import spi_slave_seq_item_package::*;
    import shared_pkg::*;
    
class spi_slave_monitor extends uvm_monitor;
    `uvm_component_utils(spi_slave_monitor);
    
    virtual spi_slave_if monitor_interface;
    spi_slave_seq_item monitored_item;
    uvm_analysis_port #(spi_slave_seq_item) monitor_analysis_port;
    
    function new(string name = "spi_slave_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor_analysis_port = new("monitor_analysis_port", this);
    endfunction
    
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            monitored_item = spi_slave_seq_item::type_id::create("monitored_item");
            @(negedge monitor_interface.clk);
            
            // Capture all interface signals
            monitored_item.rst_n = monitor_interface.rst_n;
            monitored_item.MOSI = monitor_interface.MOSI;
            monitored_item.SS_n = monitor_interface.SS_n;
            monitored_item.MISO = monitor_interface.MISO;
            monitored_item.MISO_ref = monitor_interface.MISO_ref;
            monitored_item.tx_valid = monitor_interface.tx_valid;
            monitored_item.tx_data = monitor_interface.tx_data;
            monitored_item.rx_valid = monitor_interface.rx_valid;
            monitored_item.rx_data = monitor_interface.rx_data;
            monitored_item.rx_valid_ref = monitor_interface.rx_valid_ref;
            monitored_item.rx_data_ref = monitor_interface.rx_data_ref;

            monitor_analysis_port.write(monitored_item);
            `uvm_info("MONITOR_RUN", monitored_item.convert2string_stimulus(), UVM_HIGH)
        end
    endtask
    
endclass
endpackage