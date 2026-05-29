package spi_slave_reset_sequence_package;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import spi_slave_seq_item_package::*;
    
class spi_slave_reset_sequence extends uvm_sequence #(spi_slave_seq_item);
    `uvm_object_utils(spi_slave_reset_sequence);
    
    spi_slave_seq_item reset_item;
    
    function new(string name = "spi_slave_reset_sequence");
        super.new(name);
    endfunction
    
    task body();
        reset_item = spi_slave_seq_item::type_id::create("reset_item");
        start_item(reset_item);
        
        // Apply reset conditions
        reset_item.rst_n = 1;
        reset_item.rx_valid = 0;
        reset_item.tx_valid = 0;
        reset_item.SS_n = 1;
        
        finish_item(reset_item);
    endtask
    
endclass
endpackage