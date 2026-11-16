package wrapper_agent_pkg;
    import wrapper_config_obj_pkg::*;
    import wrapper_driver_pkg::*;
    import wrapper_monitor_pkg::*;
    import wrapper_seq_item_pkg::*;
    import wrapper_sequencer_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class wrapper_agent extends uvm_agent;
        `uvm_component_utils(wrapper_agent)

        wrapper_config_obj wrapper_cfg;
        wrapper_driver     drv;
        wrapper_monitor    mon;
        wrapper_sequencer  sqr;

        uvm_analysis_port #(wrapper_seq_item) agt_ap;

        function new (string name = "wrapper_agent", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if(!uvm_config_db #(wrapper_config_obj)::get(this,"","CFG", wrapper_cfg)) begin
                `uvm_fatal("build_phase","agent error");
            end
            // the monitor is always built, the driver and the sequencer only when the agent is active
            mon    = wrapper_monitor::type_id::create("mon", this);
            agt_ap = new("agt_ap", this);
            if (wrapper_cfg.is_active == UVM_ACTIVE) begin
                drv = wrapper_driver::type_id::create("drv", this);
                sqr = wrapper_sequencer::type_id::create("sqr", this);
            end
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            mon.wrapper_vif = wrapper_cfg.wrapper_vif;
            mon.mon_ap.connect(agt_ap);
            if (wrapper_cfg.is_active == UVM_ACTIVE) begin
                drv.wrapper_vif = wrapper_cfg.wrapper_vif;
                drv.seq_item_port.connect(sqr.seq_item_export);
            end
        endfunction
    endclass
endpackage
