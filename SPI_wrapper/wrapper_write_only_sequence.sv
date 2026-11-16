package wrapper_write_only_sequence_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import wrapper_seq_item_pkg::*;
    import wrapper_shared_pkg::*;

    class wrapper_write_only_sequence extends uvm_sequence #(wrapper_seq_item);
        `uvm_object_utils(wrapper_write_only_sequence)

        wrapper_seq_item seq_item;

        int num_frames = 500;   // number of SPI frames (a reset in the middle aborts a frame and counts as one)

        function new(string name = "wrapper_write_only_sequence");
            super.new(name);
        endfunction

        task body();
            seq_item = wrapper_seq_item::type_id::create("seq_item");

            seq_item.mode = WRITE_ONLY;   // write address -> write address or write data
            seq_item.reset_constraint.constraint_mode(1);   // reset mostly deasserted

            repeat (num_frames) begin
                // one frame = 14 clock cycles (24 for read data), one item per clock cycle;
                // the item returns to position 0 when the frame ends, so sequences never stop mid-frame
                do begin
                    start_item(seq_item);
                    assert(seq_item.randomize());
                    finish_item(seq_item);
                end while (seq_item.cycle != 0);
            end
        endtask
    endclass
endpackage
