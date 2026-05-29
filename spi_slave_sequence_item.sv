package spi_slave_seq_item_package;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import shared_pkg::*;
    
class spi_slave_seq_item extends uvm_sequence_item;
    `uvm_object_utils(spi_slave_seq_item);
    
    // Signal declarations
    rand logic [7:0] tx_data;
    rand logic SS_n;
    rand logic rst_n;
    rand logic tx_valid;
    rand bit [0:10] random_array;
    
    logic [9:0] rx_data, rx_data_ref;
    logic rx_valid, MISO, MISO_ref, rx_valid_ref;
    logic MOSI;

    function new(string name = "spi_slave_seq_item");
        super.new(name);
    endfunction
    
    // Reset constraint
    constraint reset_constraint {
        rst_n dist {1 :/ 98, 0 :/ 2};
    }
    
    // SS_n constraint for all cases except read data
    constraint ss_n_general_cases {
        if (random_array[0:2] inside {3'b000, 3'b001, 3'b110} && transaction_counter % 14 != 0) {
            SS_n == 0;
        }
        else {
            SS_n == 1;
        }
    }
    
    // SS_n constraint specifically for read data
    constraint ss_n_read_data_case {
        if (random_array[0:2] inside {3'b111} && read_operation_count % 24 != 0) {
            SS_n == 0;
        }
        else {
            SS_n == 1;
        }
    }
    
    // tx_valid constraint for read data operations
    constraint tx_valid_control {
        if (random_array[0:2] == 3'b111 && read_operation_count == 23) {
            tx_valid == 1;
        }
        if (random_array[0:2] != 3'b111) {
            tx_valid == 0;
        }
    }
    
    // Random array constraint for MOSI generation
    constraint mosi_data_constraint {
        if (previous_SS_state && !SS_n) {
            random_array[0:2] inside {3'b000, 3'b001, 3'b110, 3'b111};
        }
    }
    
    function void post_randomize();
        previous_SS_state = SS_n;
        if (transaction_counter < 11)
            MOSI = random_array[transaction_counter];
    endfunction
    
    function void update_transaction_counter();
        transaction_counter++;
        if (transaction_counter == 14)
            transaction_counter = 0;
    endfunction

    function void update_read_operation_counter();
        read_operation_count++;
        if (read_operation_count == 24)
            read_operation_count = 0;
    endfunction
    
    function string convert2string();
        return $sformatf("%s reset = 0b%0b, mosi = %b, miso = %b, ss_n = %b", 
                        super.convert2string(), rst_n, MOSI, MISO, SS_n);
    endfunction
    
    function string convert2string_stimulus();
        return $sformatf("reset = 0b%0b, mosi = %b, ss_n = %b", 
                        rst_n, MOSI, SS_n);
    endfunction
    
endclass
endpackage