package wrapper_seq_item_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import wrapper_shared_pkg::*;

class wrapper_seq_item extends uvm_sequence_item;
    `uvm_object_utils(wrapper_seq_item)

    // inputs
    rand logic      rst_n;
    rand logic      SS_n;
    rand bit [0:10] random_array;  // [0] = command bit, [1:2] = din[9:8], [3:10] = din[7:0]
    logic           MOSI;          // bit driven in this cycle (taken from random_array)
    // output
    logic           MISO;

    // stimulus state (not rand, kept by the item across cycles)
    seq_mode_e mode     = READ_WRITE;
    cmd_e      prev_cmd = RD_DATA;  // start so the first operation is legal in every mode
    int        cycle    = 0;        // position inside the frame, 0 = the SS_n high cycle

    function new(string name = "wrapper_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("%s reset = 0b%0b, mosi = %b, miso = %b, ss_n = %b",
                         super.convert2string(), rst_n, MOSI, MISO, SS_n);
    endfunction

    function string convert2string_stimulus();
        return $sformatf("reset = 0b%0b, mosi = %b, ss_n = %b", rst_n, MOSI, SS_n);
    endfunction

//------------------------------ constraints start ------------------------\\

    // 1- reset mostly deasserted
    constraint reset_constraint {
        rst_n dist {1 := 98, 0 := 2};
    }

    // 2- SS_n high for one cycle, then low for 13 cycles (23 for read data);
    //    the frame length itself is handled by 'cycle' in post_randomize()
    constraint ss_n_constraint {
        SS_n == (cycle == 0);
    }

    // 3- the 3 bits that reach CHK_CMD (command bit + din[9:8]) are a valid combination
    constraint mosi_data_constraint {
        if (cycle == 0) {
            random_array[0:2] inside {3'b000, 3'b001, 3'b110, 3'b111};
        }
    }

    // 4,5- operation ordering, decided once per frame
    constraint order_constraint {
        if (cycle == 0) {
            if (mode == WRITE_ONLY) {
                // write address is followed by write address or write data
                random_array[1:2] inside {WR_ADDR, WR_DATA};
            }
            else if (mode == READ_ONLY) {
                // read address is always followed by read data, and read data by read address
                if (prev_cmd == RD_ADDR) random_array[1:2] == RD_DATA;
                else                     random_array[1:2] == RD_ADDR;
            }
            else { // READ_WRITE
                if      (prev_cmd == WR_ADDR)  random_array[1:2] inside {WR_ADDR, WR_DATA};
                else if (prev_cmd == WR_DATA)  random_array[1:2] dist {RD_ADDR := 60, WR_ADDR := 40};
                else if (prev_cmd == RD_ADDR)  random_array[1:2] == RD_DATA;
                else                           random_array[1:2] dist {WR_ADDR := 60, RD_ADDR := 40};
            }
        }
    }

//------------------------------ constraints end ---------------------------\\

    // the array changes only at the start of a frame
    function void pre_randomize();
        random_array.rand_mode(cycle == 0);
    endfunction

    function void post_randomize();
        // frame cycle 1 is ignored by the slave (IDLE -> CHK_CMD), cycles 2..12 carry
        // the 11 bits, the last low cycle is only used to raise rx_valid
        if (cycle >= 2 && cycle <= 12) MOSI = random_array[cycle - 2];
        else                           MOSI = 0;

        if (!rst_n) begin
            // reset aborts the frame and restarts the ordering
            prev_cmd = RD_DATA;
            cycle    = 0;
        end
        else begin
            if (cycle == 0) prev_cmd = cmd_e'(random_array[1:2]);
            cycle++;
            if (cycle == ((random_array[0:2] == 3'b111) ? READ_FRAME_CYCLES : FRAME_CYCLES))
                cycle = 0;
        end
    endfunction

endclass
endpackage
