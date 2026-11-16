// Interface of the DUT pins: the only things the active agent can drive/see
interface wrapper_if (input bit clk);

    // inputs to the wrapper
    logic MOSI, SS_n, rst_n;

    // output of the wrapper
    logic MISO;

    // written by the scoreboard, only to look at the golden model in the waveform
    logic MISO_ref;
    logic mismatch;

    modport DUT (input clk, MOSI, SS_n, rst_n, output MISO);

endinterface : wrapper_if