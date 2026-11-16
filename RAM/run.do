vlib work
vlog -f src_files.list +define+SIM +cover -covercells
vsim -voptargs=+acc work.RAM_top -classdebug -uvmcontrol=all -cover -assertdebug
add wave -r /RAM_top/ramif/*
do wave.do
run -all
wave zoom range 0 ns 600 ns
coverage save RAM.ucdb -onexit
## vcover report RAM.ucdb -details -annotate -output RAM.txt