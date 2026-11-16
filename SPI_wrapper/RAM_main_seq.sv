package RAM_main_seq_pkg;
    import RAM_seq_item_pkg::*;
    import RAM_shared_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class RAM_main_seq extends uvm_sequence #(RAM_seq_item);
        `uvm_object_utils(RAM_main_seq);
        RAM_seq_item seq_item;
        
        seq_mode_e mode = READ_WRITE;

        function new(string name = "RAM_main_seq");
            super.new(name);
        endfunction

        task body;
            cmd_e prev = RD_DATA; 

            repeat(2000)begin
                seq_item = RAM_seq_item::type_id::create("seq_item");
                seq_item.mode     = mode;
                seq_item.prev_cmd = prev;

                start_item(seq_item);
                assert(seq_item.randomize());
                finish_item(seq_item);

                prev = seq_item.prev_cmd; 
            end
        endtask
    endclass
endpackage