package spi_slave_driver_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import spi_slave_seq_item_package::*;
    import shared_pkg::*;
    
class spi_slave_driver extends uvm_driver #(spi_slave_seq_item);
    `uvm_component_utils(spi_slave_driver);
    
    virtual spi_slave_if driver_interface;
    spi_slave_seq_item current_item;
    
    function new(string name = "spi_slave_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin 
            current_item = spi_slave_seq_item::type_id::create("current_item");
            seq_item_port.get_next_item(current_item);
            
            // Drive signals to interface
            driver_interface.rst_n = current_item.rst_n;
            driver_interface.SS_n = current_item.SS_n;
            driver_interface.MOSI = current_item.MOSI;
            driver_interface.tx_valid = current_item.tx_valid;
            driver_interface.tx_data = current_item.tx_data;
            
            @(negedge driver_interface.clk);
            seq_item_port.item_done();
            
            `uvm_info("DRIVER_RUN", current_item.convert2string_stimulus(), UVM_HIGH)
        end
    endtask
    
endclass
endpackage