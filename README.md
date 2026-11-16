# SPI Slave with Single Port RAM - RTL Design & UVM Verification

The project implements and verify **SPI slave connected to a single-port RAM** through an SPI wrapper. The slave and the RAM are each verified on their own, then verified together through the wrapper using only the pins a real master would use (`MOSI`, `MISO`, `SS_n`, `clk`, `rst_n`).

- **Supervised by:** Eng. Kareem Waseem, Co-founder & Digital Verification Team Lead, Sylvaris AI

## Documentation

- [`SPI Slave with Single Port RAM - RTL Design & UVM Verification.pdf`](SPI_Slave_with_Single_Port_RAM.pdf): project requirements and specification.
- Full verification report (design specification, verification plans, assertions, coverage, waveform analysis and results for all three levels): see the documentation PDF in this repository.

## Repository structure

The project folder contains three sub-folders, one per verification level, plus the requirements document:

```text
.
├── RAM/                                Single-port RAM: Design and UVM testbench
├── SPI_slave/                          SPI slave: Design and UVM testbench
├── SPI_wrapper/                        Wrapper + full integration testbench  <-- run the project from here
```

## Design overview

The master sends **1 control bit + 10 bits** per frame, MSB first, framed by `SS_n`. The first three bits select the command:

| Command | First 3 bits on `MOSI` | Action |
|---|---|---|
| Write address | `000` | Stores the 8-bit write address |
| Write data | `001` | Writes the byte at the stored write address |
| Read address | `110` | Stores the 8-bit read address |
| Read data | `111` | Reads the byte; the slave shifts it out on `MISO`, MSB first |

There is no `SCLK` pin: the slave runs on the system clock and one bit is transferred per clock cycle. `SS_n` is low for 13 cycles in write and read-address frames and 23 cycles in read-data frames, followed by one high cycle. After a read data command, `tx_valid` is high for 9 cycles (1 + 8).

## How to run

Run the full project from the **`SPI_wrapper`** folder with QuestaSim.

```tcl
cd SPI_wrapper
do run.do
```

`run.do` contains:

```tcl
vlib work
vlog -sv -f src_files.list +define+SIM +cover -covercells
vsim -voptargs=+acc work.wrapper_top -classdebug -uvmcontrol=all -cover
do wave.do
run -all
wave zoom range 0ns 600ns
coverage save wrapper.ucdb -onexit
```

Generate the coverage report:

```tcl
vcover report wrapper.ucdb -details -annotate -output wrapper.txt
```

To run the slave or RAM testbench on its own, open QuestaSim in `SPI_slave/` or `RAM/` and run the `run.do` in that folder.

## Contact
Rawan Abdelkader · E-mail: rawan.abdelkader2722@gmail.com

