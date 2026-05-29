vlib work
vlog -f src_files.list +define+SIM +cover -covercells
vsim -voptargs=+acc work.top -classdebug -uvmcontrol=all -cover
add wave -r /top/slave_interface/*
run -all
coverage save spi.ucdb -onexit
## vcover report spi.ucdb -details -annotate -output spi.txt