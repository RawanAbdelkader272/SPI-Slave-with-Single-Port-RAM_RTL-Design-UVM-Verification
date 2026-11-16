package RAM_test_pkg;
    import RAM_config_obj_pkg::*;
    import RAM_env_pkg::*;
    import RAM_reset_seq_pkg::*;
    import RAM_main_seq_pkg::*;
    import RAM_shared_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class RAM_test extends uvm_test;
        `uvm_component_utils(RAM_test)

        RAM_env        env;
        RAM_config_obj RAM_cfg;
        RAM_reset_seq  reset_seq;
        RAM_main_seq   main_seq;

        function new(string name = "RAM_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env       = RAM_env::type_id::create("env", this);
            RAM_cfg   = RAM_config_obj::type_id::create("RAM_cfg");
            reset_seq = RAM_reset_seq::type_id::create("reset_seq");
            main_seq  = RAM_main_seq::type_id::create("main_seq");

            if (!uvm_config_db #(virtual RAM_if)::get(this, "", "RAM_V", RAM_cfg.RAM_vif))
                `uvm_fatal("build_phase", "Test - Unable to get the virtual interface of the RAM from the uvm_config_db")
            uvm_config_db #(RAM_config_obj)::set(this, "*", "CFG", RAM_cfg);
        endfunction

        task run_phase(uvm_phase phase);
            // write first, so the read phases find real data in the memory
            seq_mode_e modes[3] = '{WRITE_ONLY, READ_ONLY, READ_WRITE};

            super.run_phase(phase);
            phase.raise_objection(this);

            foreach (modes[i]) begin
                `uvm_info("run_phase", $sformatf("Phase %0d: reset, then %s", i, modes[i].name()), UVM_LOW)
                reset_seq.start(env.agt.sqr);
                main_seq.mode = modes[i];
                main_seq.start(env.agt.sqr);
            end

            // final reset: clears any pending "write address -> write data" obligation
            reset_seq.start(env.agt.sqr);
            `uvm_info("run_phase", "Stimulus Generation End", UVM_LOW)

            phase.drop_objection(this);
        endtask
    endclass
endpackage