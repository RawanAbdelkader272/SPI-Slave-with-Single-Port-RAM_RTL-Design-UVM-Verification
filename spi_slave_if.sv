interface spi_slave_if (input bit clk);
    // Input signals to DUT
    logic           MOSI, rst_n, SS_n, tx_valid;
    logic     [7:0] tx_data;
    
    // Output signals from DUT  
    logic   [9:0] rx_data;
    logic       rx_valid, MISO;
    
    // Reference model outputs for comparison
    logic   [9:0] rx_data_ref;
    logic       rx_valid_ref, MISO_ref;
    
    modport DUT(
        input clk, MOSI, rst_n, SS_n, tx_data, tx_valid,
        output MISO, rx_data, rx_valid
    );
    
endinterface : spi_slave_if