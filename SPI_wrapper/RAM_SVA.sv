module RAM_SVA (RAM_if.DUT ramif);

    // accepted operations (the RAM only acts on din when rx_valid is high)
    sequence s_wr_addr;  ramif.rx_valid && ramif.din[9:8] == 2'b00; endsequence
    sequence s_wr_data;  ramif.rx_valid && ramif.din[9:8] == 2'b01; endsequence
    sequence s_rd_addr;  ramif.rx_valid && ramif.din[9:8] == 2'b10; endsequence
    sequence s_rd_data;  ramif.rx_valid && ramif.din[9:8] == 2'b11; endsequence

    // Reset: outputs must be low in the cycle after reset is sampled
    property p_reset_outputs_low;
        @(posedge ramif.clk)
        !ramif.rst_n |=> (ramif.dout == 8'b0 && ramif.tx_valid == 1'b0);
    endproperty

    // tx_valid only rises as a consequence of an accepted read-data command
    property p_tx_valid_only_after_read_data;
        @(posedge ramif.clk) disable iff (!ramif.rst_n)
        $rose(ramif.tx_valid) |-> $past(ramif.rx_valid && ramif.din[9:8] == 2'b11);
    endproperty

    // After an accepted read-data command, tx_valid rises in the next cycle
    property p_tx_valid_rises_after_read_data;
        @(posedge ramif.clk) disable iff (!ramif.rst_n)
        (ramif.rx_valid && ramif.din[9:8] == 2'b11) |=> ramif.tx_valid;
    endproperty

    // After an accepted read-data command tx_valid stays high for 9 cycles (1 + 8 shifted bits)
    property p_tx_valid_high_9_cycles;
        @(posedge ramif.clk) disable iff (!ramif.rst_n)
        (ramif.rx_valid && ramif.din[9:8] == 2'b11) |=> ramif.tx_valid[*9];
    endproperty

    // ... and falls right after, unless a new read-data command restarted the window
    property p_tx_valid_falls_after_9_cycles;
        @(posedge ramif.clk) disable iff (!ramif.rst_n)
        ((ramif.rx_valid && ramif.din[9:8] == 2'b11) ##1 !(ramif.rx_valid && ramif.din[9:8] == 2'b11)[*9])
        |=> !ramif.tx_valid;
    endproperty

   // Write address: the very next operation is a write address or a write data
    property p_wr_addr_then_wr_addr_or_wr_data;
        @(posedge ramif.clk) disable iff (!ramif.rst_n)
        s_wr_addr |=> (s_wr_addr or s_wr_data);
    endproperty

    // Write address: a write data must eventually arrive
    property p_wr_addr_eventually_wr_data;
        @(posedge ramif.clk) disable iff (!ramif.rst_n)
        s_wr_addr |=> strong(##[0:$] s_wr_data);
    endproperty

    // Read address: the very next operation is a read data
    property p_rd_addr_then_rd_data;
        @(posedge ramif.clk) disable iff (!ramif.rst_n)
        s_rd_addr |=> s_rd_data;
    endproperty

    a_wr_addr_then_wr_addr_or_wr_data : assert property (p_wr_addr_then_wr_addr_or_wr_data);
    a_wr_addr_eventually_wr_data      : assert property (p_wr_addr_eventually_wr_data);
    a_rd_addr_then_rd_data            : assert property (p_rd_addr_then_rd_data);

    c_wr_addr_then_wr_addr_or_wr_data : cover property (p_wr_addr_then_wr_addr_or_wr_data);
    c_wr_addr_eventually_wr_data      : cover property (p_wr_addr_eventually_wr_data);
    c_rd_addr_then_rd_data            : cover property (p_rd_addr_then_rd_data);


    a_reset_outputs_low: assert property (p_reset_outputs_low);
    a_tx_valid_only_after_read_data  : assert property (p_tx_valid_only_after_read_data);
    a_tx_valid_rises_after_read_data : assert property (p_tx_valid_rises_after_read_data);
    a_tx_valid_high_9_cycles         : assert property (p_tx_valid_high_9_cycles);
    a_tx_valid_falls_after_9_cycles  : assert property (p_tx_valid_falls_after_9_cycles);

    c_reset_outputs_low: cover  property (p_reset_outputs_low);
    c_tx_valid_only_after_read_data  : cover  property (p_tx_valid_only_after_read_data);
    c_tx_valid_rises_after_read_data: cover property (p_tx_valid_rises_after_read_data);
    c_tx_valid_high_9_cycles         : cover property (p_tx_valid_high_9_cycles);
    c_tx_valid_falls_after_9_cycles  : cover property (p_tx_valid_falls_after_9_cycles);


endmodule