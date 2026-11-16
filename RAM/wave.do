# wave.do
delete wave *

# ---- map din[9:8] to the command names ----
radix define RAM_CMD {
    2'b00 "WR_ADDR",
    2'b01 "WR_DATA",
    2'b10 "RD_ADDR",
    2'b11 "RD_DATA",
    -default hexadecimal
}

# ---- clock and reset ----
add wave -noupdate -divider {CLOCK / RESET}
add wave -noupdate -label clk   -color Gray70 /RAM_top/ramif/clk
add wave -noupdate -label rst_n -color Orange /RAM_top/ramif/rst_n

# ---- inputs (what the driver applies) ----
add wave -noupdate -divider {INPUTS}
add wave -noupdate -label rx_valid                             /RAM_top/ramif/rx_valid
add wave -noupdate -label {cmd = din[9:8]} -radix RAM_CMD -color Yellow {/RAM_top/ramif/din[9:8]}
add wave -noupdate -label {payload = din[7:0]} -radix hexadecimal         {/RAM_top/ramif/din[7:0]}

# ---- outputs (what the DUT answers) ----
add wave -noupdate -divider {OUTPUTS}
add wave -noupdate -label tx_valid -color Cyan                 /RAM_top/ramif/tx_valid
add wave -noupdate -label dout     -radix hexadecimal -color Cyan /RAM_top/ramif/dout

# ---- reference model (from the scoreboard) ----
add wave -noupdate -divider {REFERENCE MODEL}
add wave -noupdate -label tx_valid_ref -color Green  /RAM_top/ramif/tx_valid_ref
add wave -noupdate -label dout_ref     -radix hexadecimal -color Green /RAM_top/ramif/dout_ref
add wave -noupdate -label MISMATCH     -color Red    /RAM_top/ramif/mismatch

# ---- DUT internals ----
add wave -noupdate -divider {DUT INTERNALS}
add wave -noupdate -label Wr_Addr -radix hexadecimal /RAM_top/DUT/Wr_Addr
add wave -noupdate -label Rd_Addr -radix hexadecimal /RAM_top/DUT/Rd_Addr

add wave /RAM_top/DUT/RAM_assertions/a_wr_addr_then_wr_addr_or_wr_data /RAM_top/DUT/RAM_assertions/a_wr_addr_eventually_wr_data /RAM_top/DUT/RAM_assertions/a_rd_addr_then_rd_data /RAM_top/DUT/RAM_assertions/a_reset_outputs_low /RAM_top/DUT/RAM_assertions/a_tx_valid_low_non_read /RAM_top/DUT/RAM_assertions/a_tx_valid_rises_after_read_data /RAM_top/DUT/RAM_assertions/a_tx_valid_falls_after_rise

# ---- window settings ----
configure wave -namecolwidth 230
configure wave -valuecolwidth 90
configure wave -justifyvalue left
configure wave -timelineunits ns
configure wave -signalnamewidth 1
update