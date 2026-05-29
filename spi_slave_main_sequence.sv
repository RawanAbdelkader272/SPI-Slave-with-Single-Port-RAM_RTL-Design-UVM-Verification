package spi_slave_main_sequence_package;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import spi_slave_seq_item_package::*;
    import shared_pkg::*;
    
class spi_slave_main_sequence extends uvm_sequence #(spi_slave_seq_item);
    `uvm_object_utils(spi_slave_main_sequence);
    
    spi_slave_seq_item sequence_item;
    
    function new(string name = "spi_slave_main_sequence");
        super.new(name);
    endfunction
    
    task body();
        sequence_item = spi_slave_seq_item::type_id::create("sequence_item");
        
        // First sequence block: general operations
        repeat(1000) begin
            start_item(sequence_item);
            
            // Configure constraints for general cases
            sequence_item.reset_constraint.constraint_mode(1);
            sequence_item.ss_n_general_cases.constraint_mode(1);
            sequence_item.mosi_data_constraint.constraint_mode(1);
            sequence_item.ss_n_read_data_case.constraint_mode(0);
            sequence_item.tx_valid_control.constraint_mode(0);
            
            if (transaction_counter == 0) begin
                sequence_item.random_array.rand_mode(1);
                $display("Random Array = %b, Time = %t, Counter = %d",
                        sequence_item.random_array, $time, transaction_counter);
            end
            else begin 
                sequence_item.random_array.rand_mode(0);
            end
            
            assert(sequence_item.randomize() with {
                sequence_item.random_array[0:2] inside {3'b000, 3'b001, 3'b110};
            });
            
            sequence_item.update_transaction_counter();
            finish_item(sequence_item);
        end

        // Second sequence block: read data operations
        repeat(1000) begin
            start_item(sequence_item);
            
            // Configure constraints for read data cases
            sequence_item.reset_constraint.constraint_mode(1);
            sequence_item.ss_n_general_cases.constraint_mode(0);
            sequence_item.mosi_data_constraint.constraint_mode(0);
            sequence_item.ss_n_read_data_case.constraint_mode(1);
            sequence_item.tx_valid_control.constraint_mode(1);
            
            if (read_operation_count == 0) begin
                sequence_item.random_array.rand_mode(1);
                $display("Random Array = %b, Time = %t, Counter = %d",
                        sequence_item.random_array, $time, read_operation_count);
            end
            else begin 
                sequence_item.random_array.rand_mode(0);
            end
            
            assert(sequence_item.randomize() with {
                sequence_item.random_array[0:2] inside {3'b111};
            });
            
            sequence_item.update_read_operation_counter();
            finish_item(sequence_item);
        end 
    endtask

endclass
endpackage