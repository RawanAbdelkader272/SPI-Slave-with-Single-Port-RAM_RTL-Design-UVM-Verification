package RAM_agent_pkg;
    import RAM_config_obj_pkg::*;
    import RAM_driver_pkg::*;
    import RAM_monitor_pkg::*;
    import RAM_seq_item_pkg::*;
    import RAM_sequencer_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    class RAM_agent extends uvm_agent;
        `uvm_component_utils(RAM_agent)

        RAM_config_obj RAM_cfg;   // configuration object
        RAM_driver drv;           // driver (only built when the agent is active)
        RAM_monitor mon;          // monitor
        RAM_sequencer sqr;        // sequencer (only built when the agent is active)

        uvm_analysis_port #(RAM_seq_item) agt_ap;   // connects the scoreboard and the coverage collector

        function new (string name = "RAM_agent", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if(!uvm_config_db #(RAM_config_obj)::get(this,"","CFG_R", RAM_cfg)) begin   // CFG_R is specific to the RAM agent
                `uvm_fatal("build_phase","agent error");
            end
            // only create the driver and the sequencer if this is the active agent
            if (RAM_cfg.is_active == UVM_ACTIVE) begin
                drv = RAM_driver::type_id::create("driver", this);
                sqr = RAM_sequencer::type_id::create("sqr", this);
            end
            // the monitor and the agent analysis port are always created
            mon    = RAM_monitor::type_id::create("mon", this);
            agt_ap = new("agt_ap", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            // connect the driver only if this is the active agent
            if (RAM_cfg.is_active == UVM_ACTIVE) begin
                drv.RAM_vif = RAM_cfg.RAM_vif;
                drv.seq_item_port.connect(sqr.seq_item_export);
            end
            // always connect the monitor
            mon.RAM_vif = RAM_cfg.RAM_vif;
            mon.mon_ap.connect(agt_ap);
        endfunction
    endclass
endpackage