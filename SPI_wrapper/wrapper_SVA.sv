module wrapper_SVA (wrapper_if.DUT wrapperif);

    //------------------------- read data frame tracker -------------------------//
    // Only the wrapper pins are used. A frame is one SS_n high cycle followed by SS_n low cycles:
    // low cycle 1 is ignored by the slave, low cycles 2..4 carry {command bit, din[9], din[8]},
    // and 3'b111 means "read data" (the only frame in which the slave drives MISO).
    int         low_cycles;     // consecutive SS_n low cycles of the current frame
    logic [2:0] cmd_bits;       // command bits received so far
    bit         read_data_op;   // a read data frame is in progress (stays high for the first SS_n high cycle)

    always_ff @(posedge wrapperif.clk) begin
        if (!wrapperif.rst_n) begin
            low_cycles   <= 0;
            cmd_bits     <= 3'b000;
            read_data_op <= 1'b0;
        end
        else if (wrapperif.SS_n) begin
            low_cycles   <= 0;
            read_data_op <= 1'b0;
        end
        else begin
            low_cycles <= low_cycles + 1;
            case (low_cycles)
                1: cmd_bits[2] <= wrapperif.MOSI;
                2: cmd_bits[1] <= wrapperif.MOSI;
                3: begin
                       cmd_bits[0] <= wrapperif.MOSI;
                       if ({cmd_bits[2:1], wrapperif.MOSI} == 3'b111) read_data_op <= 1'b1;
                   end
                default: ;
            endcase
        end
    end

    //-------------------------------- properties --------------------------------//

    // 1) Reset: MISO is inactive (low) in the cycle after reset is sampled
    property p_reset_miso_low;
        @(posedge wrapperif.clk)
        !wrapperif.rst_n |=> (wrapperif.MISO == 1'b0);
    endproperty

    // 2) Outside a read data operation MISO holds its value: it can only change
    //    while the slave is shifting read data out (a reset is allowed to clear it, see 1)
    property p_miso_stable_non_read_data;
        @(posedge wrapperif.clk) disable iff (!wrapperif.rst_n)
        !read_data_op |=> $stable(wrapperif.MISO);
    endproperty

    a_reset_miso_low             : assert property (p_reset_miso_low);
    a_miso_stable_non_read_data  : assert property (p_miso_stable_non_read_data);

    c_reset_miso_low             : cover property (p_reset_miso_low);
    c_miso_stable_non_read_data  : cover property (p_miso_stable_non_read_data);

    // the stability check is only meaningful if a read data frame really happens and MISO moves in it
    c_miso_changes_in_read_data  : cover property (
        @(posedge wrapperif.clk) disable iff (!wrapperif.rst_n)
        read_data_op && !$stable(wrapperif.MISO));

endmodule
