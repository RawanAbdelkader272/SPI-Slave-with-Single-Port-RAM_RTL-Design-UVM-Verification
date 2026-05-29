package spi_slave_test_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import spi_slave_env_pkg::*;
    import spi_slave_reset_sequence_package::*;
    import spi_slave_main_sequence_package::*;
    import spi_slave_config_pkg::*;
    
class spi_slave_test extends uvm_test;
    `uvm_component_utils(spi_slave_test);
    
    spi_slave_env test_environment;
    spi_slave_config test_configuration;
    spi_slave_reset_sequence reset_sequence;
    spi_slave_main_sequence main_test_sequence;
    
    function new(string name = "spi_slave_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        test_environment = spi_slave_env::type_id::create("test_environment", this);
        test_configuration = spi_slave_config::type_id::create("test_configuration", this);
        reset_sequence = spi_slave_reset_sequence::type_id::create("reset_sequence", this);
        main_test_sequence = spi_slave_main_sequence::type_id::create("main_test_sequence", this);

        if (!uvm_config_db #(virtual spi_slave_if)::get(this, "", "SPI_IF", test_configuration.config_interface))
            `uvm_fatal("TEST_CONFIG", "Virtual interface configuration failed")
        
        uvm_config_db #(spi_slave_config)::set(this, "*", "CFG", test_configuration);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);
        
        `uvm_info("TEST_EXECUTION", "Starting reset sequence", UVM_LOW)
        reset_sequence.start(test_environment.agent_component.sequencer);
        `uvm_info("TEST_EXECUTION", "Reset sequence completed", UVM_LOW)
        
        `uvm_info("TEST_EXECUTION", "Beginning main stimulus generation", UVM_LOW)
        main_test_sequence.start(test_environment.agent_component.sequencer);
        `uvm_info("TEST_EXECUTION", "Stimulus generation finished", UVM_LOW)
        
        phase.drop_objection(this);
    endtask
endclass: spi_slave_test
endpackage