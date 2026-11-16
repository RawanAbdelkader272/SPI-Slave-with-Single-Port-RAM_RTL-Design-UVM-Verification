module RAM (RAM_if.DUT ramif);

reg [7:0] MEM [255:0];

reg [7:0] Rd_Addr, Wr_Addr;

always @(posedge ramif.clk) begin
    if (!ramif.rst_n) begin
        ramif.dout <= 8'h00;
        ramif.tx_valid <= 0;
        Rd_Addr <= 8'h00;
        Wr_Addr <= 8'h00;
    end
    else begin                                          
        if (ramif.rx_valid) begin
            case (ramif.din[9:8])  
                2'b00 : Wr_Addr <= ramif.din[7:0];
                2'b01 : MEM[Wr_Addr] <= ramif.din[7:0];
                2'b10 : Rd_Addr <= ramif.din[7:0];
                2'b11 : ramif.dout <= MEM[Rd_Addr];
                default : ramif.dout <= 8'h00;
            endcase
        end
        ramif.tx_valid <= (ramif.din[9] && ramif.din[8] && ramif.rx_valid)? 1'b1 : 1'b0;
    end
end

endmodule