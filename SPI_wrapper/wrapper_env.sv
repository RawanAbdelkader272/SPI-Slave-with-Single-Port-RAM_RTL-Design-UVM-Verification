package wrapper_env_pkg;
    import wrapper_seq_item_pkg::*;
    import wrapper_sequencer_pkg::*;
    import wrapper_agent_pkg::*;
    import wrapper_coverage_collector_pkg::*;
    import wrapper_scoreboard_pkg::*;
    import spi_slave_agent_pkg::*;
    import spi_slave_collector_package::*;
    import RAM_agent_pkg::*;
    import RAM_coverage_collector_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    class wrapper_env extends uvm_env;
        `uvm_component_utils (wrapper_env)

        //wrapper  
        wrapper_agent wrapper_agt;
        wrapper_scoreboard wrapper_sb;
        wrapper_coverage_collector wrapper_cov;

        //slave (passive: coverage only, the wrapper scoreboard checks the whole path)
        spi_slave_agent slave_agt;
        spi_slave_coverage slave_cov;

        //RAM
        RAM_agent ram_agt;
        RAM_coverage_collector ram_cov;
    
        // construction
        function new (string name = "wrapper_env", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            // wrapper package
            wrapper_agt = wrapper_agent::type_id::create("wrapper_agt",this);            
            wrapper_sb = wrapper_scoreboard::type_id::create("wrapper_sb", this);
            wrapper_cov = wrapper_coverage_collector::type_id::create("wrapper_cov", this);
            // slave package
            slave_agt = spi_slave_agent::type_id::create("slave_agt",this);            
            slave_cov = spi_slave_coverage::type_id::create("slave_cov", this);
            // ram package            
            ram_agt = RAM_agent::type_id::create("ram_agt",this);            
            ram_cov = RAM_coverage_collector::type_id::create("ram_cov", this);
        endfunction

        function void connect_phase (uvm_phase phase);
            wrapper_agt.agt_ap.connect(wrapper_sb.sb_export);
            wrapper_agt.agt_ap.connect(wrapper_cov.cov_export);
            slave_agt.agent_analysis_port.connect(slave_cov.coverage_export);
            ram_agt.agt_ap.connect(ram_cov.cov_export);       
        endfunction
    endclass
endpackage