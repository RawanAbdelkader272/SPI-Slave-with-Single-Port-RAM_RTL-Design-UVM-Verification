package spi_slave_env_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import spi_slave_agent_pkg::*;
    import spi_slave_scoreboard_pkg::*;
    import spi_slave_collector_package::*;
    
class spi_slave_env extends uvm_env;
    `uvm_component_utils(spi_slave_env);
    
    spi_slave_scoreboard scoreboard_component;
    spi_slave_coverage coverage_component;
    spi_slave_agent agent_component;
    
    function new(string name = "spi_slave_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent_component = spi_slave_agent::type_id::create("agent_component", this);
        scoreboard_component = spi_slave_scoreboard::type_id::create("scoreboard_component", this);
        coverage_component = spi_slave_coverage::type_id::create("coverage_component", this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        agent_component.agent_analysis_port.connect(scoreboard_component.scoreboard_export);
        agent_component.agent_analysis_port.connect(coverage_component.coverage_export);
    endfunction
endclass
endpackage