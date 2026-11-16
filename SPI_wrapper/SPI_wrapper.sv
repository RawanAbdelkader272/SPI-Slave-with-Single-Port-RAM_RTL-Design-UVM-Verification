module WRAPPER (wrapper_if.DUT wrapperif);

    logic [9:0] rx_data_din;
    logic [7:0] tx_data_dout;
    logic       rx_valid, tx_valid;
    
    spi_slave_if spi_slaveif (wrapperif.clk);
    RAM_if       ramif       (wrapperif.clk);


    // Wrapper pins -> slave
    assign spi_slaveif.rst_n    = wrapperif.rst_n;
    assign spi_slaveif.MOSI     = wrapperif.MOSI;
    assign spi_slaveif.SS_n     = wrapperif.SS_n;
    assign wrapperif.MISO       = spi_slaveif.MISO;


    // Slave -> internal wires -> RAM
    assign rx_data_din          = spi_slaveif.rx_data;
    assign rx_valid             = spi_slaveif.rx_valid;
    assign ramif.rst_n          = wrapperif.rst_n;
    assign ramif.din            = rx_data_din;
    assign ramif.rx_valid       = rx_valid;

    // RAM -> internal wires -> slave
    assign tx_data_dout         = ramif.dout;
    assign tx_valid             = ramif.tx_valid;
    assign spi_slaveif.tx_data  = tx_data_dout;
    assign spi_slaveif.tx_valid = tx_valid;

    SLAVE SLAVE_instance (spi_slaveif);
    RAM   RAM_instance   (ramif);

endmodule