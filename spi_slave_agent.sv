package spi_slave_agent_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import spi_slave_seq_item_package::*;
    import spi_slave_config_pkg::*;
    import spi_slave_driver_pkg::*;
    import spi_slave_monitor_pkg::*;
    import spi_slave_sequencer_package::*;

class spi_slave_agent extends uvm_agent;
    `uvm_component_utils(spi_slave_agent)
      
    spi_slave_config agent_config;
    spi_slave_driver driver;
    spi_slave_sequencer sequencer;
    spi_slave_monitor monitor;
    uvm_analysis_port #(spi_slave_seq_item) agent_analysis_port;

    function new(string name = "spi_slave_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(spi_slave_config)::get(this, "", "CFG", agent_config)) begin
            `uvm_fatal("AGENT_BUILD", "Configuration object retrieval failed")
        end
        sequencer = spi_slave_sequencer::type_id::create("sequencer", this);
        driver = spi_slave_driver::type_id::create("driver", this);
        monitor = spi_slave_monitor::type_id::create("monitor", this);
        agent_analysis_port = new("agent_analysis_port", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.driver_interface = agent_config.config_interface;
        monitor.monitor_interface = agent_config.config_interface;
        driver.seq_item_port.connect(sequencer.seq_item_export);
        monitor.monitor_analysis_port.connect(agent_analysis_port);
    endfunction
endclass
endpackage