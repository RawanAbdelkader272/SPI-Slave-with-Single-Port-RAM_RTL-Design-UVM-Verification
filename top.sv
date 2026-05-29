import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_slave_test_pkg::*;
import spi_slave_seq_item_package::*;
import shared_pkg::*;

module top();
    bit clk;
    initial begin 
        forever #2 clk = ~clk;
    end
    
    spi_slave_if slave_interface(clk);
    
    // Design Under Test with interface connection
    SLAVE DUT(slave_interface);
    
    // Reference model with individual signal connections for comparison
    SPI_Slave reference_dut(
        .MOSI(slave_interface.MOSI),
        .SS_n(slave_interface.SS_n),
        .clk(slave_interface.clk),
        .rst_n(slave_interface.rst_n),
        .rx_data(slave_interface.rx_data_ref),
        .tx_valid(slave_interface.tx_valid),
        .tx_data(slave_interface.tx_data),
        .MISO(slave_interface.MISO_ref),
        .rx_valid(slave_interface.rx_valid_ref)
    );
    
    initial begin 
        uvm_config_db #(virtual spi_slave_if)::set(null, "uvm_test_top", "SPI_IF", slave_interface);
        run_test("spi_slave_test");
    end
endmodule