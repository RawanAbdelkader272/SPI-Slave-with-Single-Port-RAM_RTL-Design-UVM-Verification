# SPI Slave with Single-Port RAM | RTL Design & UVM Verification

![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue)
![UVM](https://img.shields.io/badge/Verification-UVM-green)
![Simulator](https://img.shields.io/badge/Simulator-QuestaSim-orange)

## Overview
This project implements and verify SPI (Serial Peripheral Interface) Slave module integrated with a single-port RAM. The design is written in SystemVerilog and verified using a structured UVM (Universal Verification Methodology). 

The SPI Slave core operates as a peripheral device, receiving commands and data from an SPI master, decoding operations, and interfacing with a synchronous single-port RAM for read/write transactions. A comprehensive verification environment ensures protocol compliance, data integrity, and robust corner-case handling.

## Documentation
For a detailed breakdown of the design architecture, verification plan, bug reports, waveform analysis, and coverage metrics, refer to the official project report:
📑 **[SPI Slave with Single Port RAM - RTL Design & Verification.pdf](./SPI%20Slave%20with%20Single%20Port%20RAM%20-%20RTL%20Design%20&%20Verification.pdf)**

## System Architecture
The system consists of two primary hardware blocks communicating via control and data signals:
- **SPI Slave Core**: FSM-driven peripheral that handles serial-to-parallel and parallel-to-serial conversion, command decoding, and RAM interface control.
- **Single-Port RAM Backend**: Stores and retrieves data based on address/payload received from the slave.

### Interface Signals
| Signal     | Width | Direction   | Description                          |
|------------|-------|-------------|--------------------------------------|
| `clk`      | 1     | Input       | System clock                         |
| `rst_n`    | 1     | Input       | Synchronous active-low reset         |
| `SS_n`     | 1     | Input       | Chip Select (active-low)             |
| `MOSI`     | 1     | Input       | Master Out Slave In (serial data)    |
| `MISO`     | 1     | Output      | Master In Slave Out (serial data)    |
| `tx_data`  | 8     | Input       | Parallel data to shift out           |
| `tx_valid` | 1     | Input       | Asserted when `tx_data` is ready     |
| `rx_data`  | 10    | Output      | Address + payload shifted from master|
| `rx_valid` | 1     | Output      | Single-cycle pulse on valid reception|



