package spi_slave_scoreboard_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import spi_slave_seq_item_package::*; 
    
class spi_slave_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_slave_scoreboard);
    
    uvm_analysis_export #(spi_slave_seq_item) scoreboard_export;
    uvm_tlm_analysis_fifo #(spi_slave_seq_item) scoreboard_fifo;
    spi_slave_seq_item scoreboard_item;
    int error_counter = 0;
    int success_counter = 0;
    
    function new(string name = "spi_slave_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        scoreboard_export = new("scoreboard_export", this);
        scoreboard_fifo = new("scoreboard_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        scoreboard_export.connect(scoreboard_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            scoreboard_fifo.get(scoreboard_item);
            if (scoreboard_item.MISO != scoreboard_item.MISO_ref || 
                scoreboard_item.rx_valid != scoreboard_item.rx_valid_ref || 
                scoreboard_item.rx_data != scoreboard_item.rx_data_ref) begin
                
                `uvm_error("SCOREBOARD_CHECK", $sformatf("Mismatch detected! DUT Output: %s Reference Output: MISO=0b%0b",
                    scoreboard_item.convert2string(), scoreboard_item.MISO_ref))
                error_counter++;
            end
            else begin
                `uvm_info("SCOREBOARD_CHECK", $sformatf("Transaction verified successfully: %s",
                    scoreboard_item.convert2string()), UVM_HIGH)
                success_counter++;
            end
        end
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("FINAL_REPORT", $sformatf("Successful transactions: %0d", success_counter), UVM_MEDIUM)
        `uvm_info("FINAL_REPORT", $sformatf("Failed transactions: %0d", error_counter), UVM_MEDIUM)
    endfunction
    
endclass
endpackage