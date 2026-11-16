module RAM #(
    parameter MEM_DEPTH = 256,
    parameter ADDR_SIZE = 8
) (RAM_if.DUT ramif);

reg [7:0] MEM [MEM_DEPTH-1:0];

reg [ADDR_SIZE-1:0] Rd_Addr, Wr_Addr;

// tx_valid is HIGH for 9 clock cycles after a read data command (1 + 8 bits shifted out by the slave).
// tx_cnt counts the 8 cycles that follow the first one.
reg [3:0] tx_cnt;

always @(posedge ramif.clk) begin
    if (!ramif.rst_n) begin
        ramif.dout <= 8'h00;
        ramif.tx_valid <= 0;
        tx_cnt <= 4'd0;
        Rd_Addr <= {ADDR_SIZE{1'b0}};
        Wr_Addr <= {ADDR_SIZE{1'b0}};
    end
    else begin
        if (ramif.rx_valid) begin
            case (ramif.din[9:8])
                2'b00 : Wr_Addr <= ramif.din[ADDR_SIZE-1:0];
                2'b01 : MEM[Wr_Addr] <= ramif.din[7:0];
                2'b10 : Rd_Addr <= ramif.din[ADDR_SIZE-1:0];
                2'b11 : ramif.dout <= MEM[Rd_Addr];
                default : ramif.dout <= 8'h00;
            endcase
        end

        if (ramif.rx_valid && ramif.din[9:8] == 2'b11) begin
            // read data command: start (or restart) the 9 cycle window
            ramif.tx_valid <= 1'b1;
            tx_cnt         <= 4'd8;
        end
        else begin
            ramif.tx_valid <= (tx_cnt != 4'd0);
            if (tx_cnt != 4'd0) tx_cnt <= tx_cnt - 4'd1;
        end
    end
end

endmodule