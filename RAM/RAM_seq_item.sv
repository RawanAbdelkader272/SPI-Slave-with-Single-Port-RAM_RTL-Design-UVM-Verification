package RAM_seq_item_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import shared_pkg::*;

class RAM_seq_item extends uvm_sequence_item;
`uvm_object_utils(RAM_seq_item)

// inputs
    rand logic [9:0] din;
    rand bit         rst_n;
    rand bit         rx_valid;
// outputs
    logic [7:0] dout;
    bit         tx_valid;

    // ordering state (not rand, kept by the sequence across items)
    seq_mode_e mode     = READ_WRITE;
    cmd_e      prev_cmd = RD_DATA;   // start so the first op is legal in every mode

    function new(string name = "RAM_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "%s rst_n = 0b%0b , rx_valid = 0b%0b , din = 0b%010b , dout = 0b%08b , tx_valid = 0b%0b",
            super.convert2string(), rst_n, rx_valid, din, dout, tx_valid
        );
    endfunction

    function string convert2string_stimulus();
        return $sformatf(
            "%s rst_n = 0b%0b , rx_valid = 0b%0b , din = 0b%010b",
            super.convert2string(), rst_n, rx_valid, din
        );
    endfunction

//------------------------------ constraints start ------------------------\\

    // reset mostly deasserted
    constraint rst_c { rst_n dist {1 := 95, 0 := 5}; }

    // rx_valid mostly asserted; always asserted right after an address operation
    constraint rx_valid_c {
        if (prev_cmd inside {WR_ADDR, RD_ADDR}) rx_valid == 1;
        else rx_valid dist {1 := 90, 0 := 10};
    }

    // operation ordering applies to accepted operations only;
    // an idle cycle (rx_valid = 0) carries a fully random din
    constraint order_c {
        solve rx_valid before din;
        if (rx_valid) {
            if (mode == WRITE_ONLY) {
                din[9:8] inside {WR_ADDR, WR_DATA};
            }
            else if (mode == READ_ONLY) {
                if (prev_cmd == RD_ADDR) din[9:8] == RD_DATA;
                else                     din[9:8] == RD_ADDR;
            }
            else { // READ_WRITE
                if      (prev_cmd == WR_ADDR) din[9:8] inside {WR_ADDR, WR_DATA};
                else if (prev_cmd == WR_DATA) din[9:8] dist {RD_ADDR := 60, WR_ADDR := 40};
                else if (prev_cmd == RD_ADDR) din[9:8] == RD_DATA;
                else                          din[9:8] dist {WR_ADDR := 60, RD_ADDR := 40};
            }
        }
    }

    function void post_randomize();
        if (!rst_n)        prev_cmd = RD_DATA;          // reset restarts the sequence
        else if (rx_valid) prev_cmd = cmd_e'(din[9:8]); // only accepted operations advance the state
    endfunction

//------------------------------ constraints end ---------------------------\\
endclass
endpackage