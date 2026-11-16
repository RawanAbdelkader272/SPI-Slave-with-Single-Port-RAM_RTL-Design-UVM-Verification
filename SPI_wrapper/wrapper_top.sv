import uvm_pkg::*;
`include "uvm_macros.svh"
import wrapper_test_pkg::*;

module wrapper_top();
    bit clk;
    initial forever #10 clk = ~clk;

    // the three interfaces of the diagram live here, at the top
    wrapper_if   wrapperif  (clk);   
    spi_slave_if spi_slaveif(clk);  
    RAM_if       ramif      (clk);  

    WRAPPER DUT (wrapperif);

    // passive interfaces are only ever read by their monitors
    initial begin
        uvm_config_db #(virtual wrapper_if)  ::set(null, "uvm_test_top", "WRAPPER_IF",   wrapperif);
        uvm_config_db #(virtual spi_slave_if)::set(null, "uvm_test_top", "SPI_SLAVE_IF", spi_slaveif);
        uvm_config_db #(virtual RAM_if)      ::set(null, "uvm_test_top", "RAM_IF",       ramif);
        run_test("wrapper_test");
    end

    // SPI slave 
    assign spi_slaveif.rst_n    = wrapperif.rst_n;
    assign spi_slaveif.MOSI     = wrapperif.MOSI;
    assign spi_slaveif.SS_n     = wrapperif.SS_n;
    assign spi_slaveif.MISO     = wrapperif.MISO;
    assign spi_slaveif.tx_valid = DUT.tx_valid;
    assign spi_slaveif.tx_data  = DUT.tx_data_dout;
    assign spi_slaveif.rx_valid = DUT.rx_valid;
    assign spi_slaveif.rx_data  = DUT.rx_data_din;

    // RAM 
    assign ramif.rst_n          = wrapperif.rst_n;
    assign ramif.rx_valid       = DUT.rx_valid;
    assign ramif.din            = DUT.rx_data_din;
    assign ramif.tx_valid       = DUT.tx_valid;
    assign ramif.dout           = DUT.tx_data_dout;
    // RAM_SVA is not bound here: its two 'next operation' assertions assume back-to-back ops (standalone RAM test only)
    // wrapper assertions: reset clears MISO, MISO stable outside read data
    bind WRAPPER wrapper_SVA wrapper_assertions (wrapperif);

endmodule