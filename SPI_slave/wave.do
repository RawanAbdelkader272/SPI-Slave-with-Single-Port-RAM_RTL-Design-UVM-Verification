# wave.do - SPI Slave
delete wave *

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
add wave -noupdate -label clk   -color Gray70 /top/slave_interface/clk
add wave -noupdate -label rst_n -color Orange /top/slave_interface/rst_n

# ---- inputs (what the driver applies) ----
add wave -noupdate -divider {INPUTS}
add wave -noupdate -label SS_n      -color Yellow /top/slave_interface/SS_n
add wave -noupdate -label MOSI      -color Yellow /top/slave_interface/MOSI
add wave -noupdate -label tx_valid                /top/slave_interface/tx_valid
add wave -noupdate -label tx_data   -radix hexadecimal /top/slave_interface/tx_data

# ---- DUT outputs ----
add wave -noupdate -divider {DUT OUTPUTS}
add wave -noupdate -label MISO     -color Cyan /top/slave_interface/MISO
add wave -noupdate -label rx_valid -color Cyan /top/slave_interface/rx_valid
add wave -noupdate -label rx_data  -color Cyan -radix hexadecimal /top/slave_interface/rx_data

# ---- reference model outputs ----
add wave -noupdate -divider {REFERENCE MODEL}
add wave -noupdate -label MISO_ref     -color Green /top/slave_interface/MISO_ref
add wave -noupdate -label rx_valid_ref -color Green /top/slave_interface/rx_valid_ref
add wave -noupdate -label rx_data_ref  -color Green -radix hexadecimal /top/slave_interface/rx_data_ref
catch {add wave -noupdate -label MISMATCH -color Red -expr {(/top/slave_interface/MISO != /top/slave_interface/MISO_ref) | (/top/slave_interface/rx_valid != /top/slave_interface/rx_valid_ref) | (/top/slave_interface/rx_data != /top/slave_interface/rx_data_ref)}}

# ---- DUT internals ----
add wave -noupdate -divider {DUT INTERNALS}
add wave -noupdate -label state             -radix SPI_STATE /top/DUT/cs
add wave -noupdate -label bit_counter       -radix unsigned  /top/DUT/counter
add wave -noupdate -label received_address                   /top/DUT/received_address

add wave /top/DUT/assert__check_reset_property /top/DUT/assert__check_rx_valid_property /top/DUT/assert__check_idle_transition /top/DUT/assert__check_write_transition /top/DUT/assert__check_read_addr_transition /top/DUT/assert__check_read_data_transition /top/DUT/assert__check_write_to_idle /top/DUT/assert__check_read_addr_to_idle /top/DUT/assert__check_read_data_to_idle


# ---- window settings ----
configure wave -namecolwidth 200
configure wave -valuecolwidth 90
configure wave -justifyvalue left
configure wave -timelineunits ns
update