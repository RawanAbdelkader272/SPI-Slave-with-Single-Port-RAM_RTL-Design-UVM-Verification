package wrapper_reset_sequence_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import wrapper_seq_item_pkg::*;
    import wrapper_shared_pkg::*;

    class wrapper_reset_sequence extends uvm_sequence #(wrapper_seq_item);
        `uvm_object_utils(wrapper_reset_sequence)

        wrapper_seq_item seq_item;

        function new(string name = "wrapper_reset_sequence");
            super.new(name);
        endfunction

        task body();
            seq_item = wrapper_seq_item::type_id::create("seq_item");

            // reset is forced here, not randomized
            seq_item.reset_constraint.constraint_mode(0);

            repeat (2) begin
                start_item(seq_item);
                // SS_n is high (frame position 0) and the ordering state restarts in post_randomize()
                assert(seq_item.randomize() with { rst_n == 0; });
                finish_item(seq_item);
            end
        endtask
    endclass
endpackage
