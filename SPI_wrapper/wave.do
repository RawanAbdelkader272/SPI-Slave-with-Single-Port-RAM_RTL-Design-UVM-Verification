# wave.do - SPI Wrapper (SPI slave + RAM)
# open the Wave window first (it may not exist yet)
view wave
catch {delete wave *}

# FSM state names (encodings from SPI_slave.sv)
radix define SPI_STATE {
    3'b000 "IDLE",
    3'b001 "WRITE",
    3'b010 "CHK_CMD",
    3'b011 "READ_ADD",
    3'b100 "READ_DATA",
    -default hexadecimal
}

# ---- clock and reset ----
add wave -noupdate -divider {CLOCK / RESET}
add wave -noupdate -label clk   -color Gray70 /wrapper_top/wrapperif/clk
add wave -noupdate -label rst_n -color Orange /wrapper_top/wrapperif/rst_n

# ---- wrapper inputs (what the driver applies) ----
add wave -noupdate -divider {WRAPPER INPUTS}
add wave -noupdate -label SS_n -color Yellow /wrapper_top/wrapperif/SS_n
add wave -noupdate -label MOSI -color Yellow /wrapper_top/wrapperif/MOSI

# ---- wrapper output vs golden model ----
add wave -noupdate -divider {WRAPPER OUTPUT / GOLDEN MODEL}
add wave -noupdate -label MISO     -color Cyan  /wrapper_top/wrapperif/MISO
add wave -noupdate -label MISO_ref -color Green /wrapper_top/wrapperif/MISO_ref
add wave -noupdate -label MISMATCH -color Red   /wrapper_top/wrapperif/mismatch

# ---- internal wires: slave -> RAM and RAM -> slave ----
add wave -noupdate -divider {SLAVE -> RAM}
add wave -noupdate -label rx_valid -color Cyan -radix hexadecimal /wrapper_top/DUT/rx_valid
add wave -noupdate -label rx_data_din          -radix hexadecimal /wrapper_top/DUT/rx_data_din
add wave -noupdate -divider {RAM -> SLAVE}
add wave -noupdate -label tx_valid -color Cyan /wrapper_top/DUT/tx_valid
add wave -noupdate -label tx_data_dout         -radix hexadecimal /wrapper_top/DUT/tx_data_dout

# ---- SPI slave internals ----
add wave -noupdate -divider {SLAVE INTERNALS}
add wave -noupdate -label state             -radix SPI_STATE /wrapper_top/DUT/SLAVE_instance/cs
add wave -noupdate -label bit_counter       -radix unsigned  /wrapper_top/DUT/SLAVE_instance/counter
add wave -noupdate -label received_address                   /wrapper_top/DUT/SLAVE_instance/received_address

# ---- RAM internals ----
add wave -noupdate -divider {RAM INTERNALS}
add wave -noupdate -label Wr_Addr -radix hexadecimal /wrapper_top/DUT/RAM_instance/Wr_Addr
add wave -noupdate -label Rd_Addr -radix hexadecimal /wrapper_top/DUT/RAM_instance/Rd_Addr

# ---- wrapper assertions ----
add wave -noupdate -divider {WRAPPER ASSERTIONS}
add wave -noupdate -label read_data_op /wrapper_top/DUT/wrapper_assertions/read_data_op
add wave -label a_reset_miso_low /wrapper_top/DUT/wrapper_assertions/a_reset_miso_low
add wave -label a_miso_stable /wrapper_top/DUT/wrapper_assertions/a_miso_stable_non_read_data

# ---- SPI slave assertions (compiled with +define+SIM) ----
add wave -noupdate -divider {SLAVE ASSERTIONS}
add wave -label SL_reset /wrapper_top/DUT/SLAVE_instance/assert__check_reset_property
add wave -label SL_rx_valid /wrapper_top/DUT/SLAVE_instance/assert__check_rx_valid_property
add wave -label SL_idle_trans /wrapper_top/DUT/SLAVE_instance/assert__check_idle_transition
add wave -label SL_write_trans /wrapper_top/DUT/SLAVE_instance/assert__check_write_transition
add wave -label SL_read_addr_trans /wrapper_top/DUT/SLAVE_instance/assert__check_read_addr_transition
add wave -label SL_read_data_trans /wrapper_top/DUT/SLAVE_instance/assert__check_read_data_transition
add wave -label SL_write_to_idle /wrapper_top/DUT/SLAVE_instance/assert__check_write_to_idle
add wave -label SL_read_addr_to_idle /wrapper_top/DUT/SLAVE_instance/assert__check_read_addr_to_idle
add wave -label SL_read_data_to_idle /wrapper_top/DUT/SLAVE_instance/assert__check_read_data_to_idle


# ---- window settings ----
configure wave -namecolwidth 200
configure wave -valuecolwidth 90
configure wave -justifyvalue left
configure wave -timelineunits ns
update
