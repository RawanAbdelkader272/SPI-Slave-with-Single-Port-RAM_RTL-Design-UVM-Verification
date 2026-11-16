package wrapper_driver_pkg;
    import wrapper_seq_item_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class wrapper_driver extends uvm_driver #(wrapper_seq_item);
        `uvm_component_utils(wrapper_driver)

        virtual wrapper_if wrapper_vif;   // virtual interface
        wrapper_seq_item   stim_seq_item; // sequence item

        function new(string name = "wrapper_driver", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                stim_seq_item = wrapper_seq_item::type_id::create("stim_seq_item");
                seq_item_port.get_next_item(stim_seq_item);

                // one item = one clock cycle, only the three input pins are driven
                wrapper_vif.rst_n = stim_seq_item.rst_n;
                wrapper_vif.SS_n  = stim_seq_item.SS_n;
                wrapper_vif.MOSI  = stim_seq_item.MOSI;

                // print before item_done: the sequence reuses the item and re-randomizes it right after
                `uvm_info("run_phase", stim_seq_item.convert2string_stimulus(), UVM_HIGH)

                @(negedge wrapper_vif.clk);
                seq_item_port.item_done();
            end
        endtask
    endclass
endpackage
