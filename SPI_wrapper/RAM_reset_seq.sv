package RAM_reset_seq_pkg;
    import RAM_seq_item_pkg::*;
    import RAM_shared_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class RAM_reset_seq extends uvm_sequence #(RAM_seq_item);
        `uvm_object_utils(RAM_reset_seq);
        RAM_seq_item seq_item;
        
        // constructor 
        function new(string name = "RAM_reset_seq");
            super.new(name);
        endfunction

        virtual task body();
            RAM_seq_item seq_item = RAM_seq_item::type_id::create("seq_item");
            start_item(seq_item);
                seq_item.rst_n    = 0;
                seq_item.rx_valid = 0;
                seq_item.din      = 10'b0;
                seq_item.prev_cmd = RD_DATA;   // restart the ordering state
            finish_item(seq_item);
        endtask
    endclass
endpackage