package spi_slave_config_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
class spi_slave_config extends uvm_object;
    `uvm_object_utils(spi_slave_config)
    
    virtual spi_slave_if config_interface;
    
    function new(string name = "spi_slave_config");
        super.new(name);
    endfunction
    
endclass
endpackage