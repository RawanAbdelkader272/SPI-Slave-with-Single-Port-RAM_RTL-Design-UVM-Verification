package wrapper_shared_pkg;
    typedef enum bit [1:0] {WR_ADDR = 2'b00, WR_DATA = 2'b01,
                            RD_ADDR = 2'b10, RD_DATA = 2'b11} cmd_e;
    typedef enum {WRITE_ONLY, READ_ONLY, READ_WRITE} seq_mode_e;

    // one SS_n high cycle + 13 SS_n low cycles
    parameter int FRAME_CYCLES      = 14;
    // one SS_n high cycle + 23 SS_n low cycles (read data)
    parameter int READ_FRAME_CYCLES = 24;
endpackage
