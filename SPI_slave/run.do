vlib work
vlog -f src_files.list +define+SIM +cover -covercells
vsim -voptargs=+acc work.top -classdebug -uvmcontrol=all -cover
do wave.do
run -all
wave zoom range 0ns 300ns
coverage save spi_slave.ucdb -onexit
## vcover report spi_slave.ucdb -details -annotate -output spi_slave.txt
