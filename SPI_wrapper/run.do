vlib work
vlog -f src_files.list +define+SIM +cover -covercells
vsim -voptargs=+acc work.wrapper_top -classdebug -uvmcontrol=all -cover
do wave.do
run -all
wave zoom range 0ns 600ns
coverage save wrapper.ucdb -onexit
## vcover report wrapper.ucdb -details -annotate -output wrapper.txt