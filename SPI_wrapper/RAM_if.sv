interface RAM_if(clk);

    input clk;

    // inputs
    logic [9:0] din;
    bit         rst_n, rx_valid;

    // outputs
    logic [7:0] dout;
    bit         tx_valid;

    // testbench debug signals (driven by the scoreboard, never by the DUT)
    logic [7:0] dout_ref;
    bit         tx_valid_ref;
    bit         mismatch;

    modport DUT (input clk, din, rst_n, rx_valid, output dout, tx_valid);
endinterface