package wrapper_test_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import wrapper_config_obj_pkg::*;
    import spi_slave_config_pkg::*;
    import RAM_config_obj_pkg::*;
    import wrapper_env_pkg::*;
    import wrapper_reset_sequence_pkg::*;
    import wrapper_write_only_sequence_pkg::*;
    import wrapper_read_only_sequence_pkg::*;
    import wrapper_write_read_sequence_pkg::*;

    class wrapper_test extends uvm_test;
        `uvm_component_utils(wrapper_test)

        wrapper_env        env;

        // one config object per agent: only the wrapper agent is active,
        // the SPI slave and the RAM agents just watch the internal signals
        wrapper_config_obj wrapper_cfg;
        spi_slave_config   slave_cfg;
        RAM_config_obj     ram_cfg;

        wrapper_reset_sequence      reset_seq;
        wrapper_write_only_sequence write_only_seq;
        wrapper_read_only_sequence  read_only_seq;
        wrapper_write_read_sequence write_read_seq;

        function new(string name = "wrapper_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            env            = wrapper_env::type_id::create("env", this);
            wrapper_cfg    = wrapper_config_obj::type_id::create("wrapper_cfg");
            slave_cfg      = spi_slave_config::type_id::create("slave_cfg");
            ram_cfg        = RAM_config_obj::type_id::create("ram_cfg");

            reset_seq      = wrapper_reset_sequence::type_id::create("reset_seq");
            write_only_seq = wrapper_write_only_sequence::type_id::create("write_only_seq");
            read_only_seq  = wrapper_read_only_sequence::type_id::create("read_only_seq");
            write_read_seq = wrapper_write_read_sequence::type_id::create("write_read_seq");

            // virtual interfaces, set by wrapper_top
            if (!uvm_config_db #(virtual wrapper_if)::get(this, "", "WRAPPER_IF", wrapper_cfg.wrapper_vif))
                `uvm_fatal("build_phase", "Test - Unable to get the virtual interface of the wrapper from the uvm_config_db")
            if (!uvm_config_db #(virtual spi_slave_if)::get(this, "", "SPI_SLAVE_IF", slave_cfg.config_interface))
                `uvm_fatal("build_phase", "Test - Unable to get the virtual interface of the SPI slave from the uvm_config_db")
            if (!uvm_config_db #(virtual RAM_if)::get(this, "", "RAM_IF", ram_cfg.RAM_vif))
                `uvm_fatal("build_phase", "Test - Unable to get the virtual interface of the RAM from the uvm_config_db")

            wrapper_cfg.is_active = UVM_ACTIVE;
            slave_cfg.is_active   = UVM_PASSIVE;
            ram_cfg.is_active     = UVM_PASSIVE;

            // the keys are the ones each component asks for in its build_phase
            uvm_config_db #(wrapper_config_obj)::set(this, "env.wrapper_agt", "CFG",   wrapper_cfg);
            uvm_config_db #(wrapper_config_obj)::set(this, "env.wrapper_sb",  "CFG_W", wrapper_cfg);  // scoreboard drives MISO_ref / mismatch
            uvm_config_db #(spi_slave_config)  ::set(this, "env.slave_agt",   "CFG_S", slave_cfg);
            uvm_config_db #(RAM_config_obj)    ::set(this, "env.ram_agt",     "CFG_R", ram_cfg);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            phase.raise_objection(this);

            // 1) reset: every block starts from a known state
            `uvm_info("run_phase", "Phase 1: reset", UVM_LOW)
            reset_seq.start(env.wrapper_agt.sqr);

            // 2) write only: fills the RAM, so the read phases find real data
            `uvm_info("run_phase", "Phase 2: write only (write address / write data)", UVM_LOW)
            write_only_seq.start(env.wrapper_agt.sqr);

            // 3) reset again (clears the slave's read-address flag), then read only
            `uvm_info("run_phase", "Phase 3: reset, then read only (read address / read data)", UVM_LOW)
            reset_seq.start(env.wrapper_agt.sqr);
            read_only_seq.start(env.wrapper_agt.sqr);

            // 4) reset again, then random write / read mix
            `uvm_info("run_phase", "Phase 4: reset, then write and read", UVM_LOW)
            reset_seq.start(env.wrapper_agt.sqr);
            write_read_seq.start(env.wrapper_agt.sqr);

            // 5) final reset: clears any pending "write address -> write data" obligation
            `uvm_info("run_phase", "Phase 5: final reset", UVM_LOW)
            reset_seq.start(env.wrapper_agt.sqr);

            // let the last cycles reach the monitors, scoreboards and coverage
            repeat (5) @(negedge wrapper_cfg.wrapper_vif.clk);

            `uvm_info("run_phase", "Stimulus Generation End", UVM_LOW)
            phase.drop_objection(this);
        endtask
    endclass
endpackage