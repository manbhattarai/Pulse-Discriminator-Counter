# Photon Counter - Time-of-Flight Measurement System

[![Platform](https://img.shields.io/badge/Platform-Red%20Pitaya-red)](https://redpitaya.com/)
[![FPGA](https://img.shields.io/badge/FPGA-Zynq--7010-blue)](https://www.xilinx.com/)



## Overview
This module implements a photon signal discrimination and counting hardware on a Red Pitaya board for a time-of-flight like measurement. 
A C-code software is implemented to interface with the hardware that returns number of counts as a function of bin index. 

## Features

- Real-time photon counting at 250 MHz processing rate
- 14-bit threshold-based discrimination
- 3000 time bins with 10 µs resolution
- Robust clock domain crossing with custom FIFO
- AXI GPIO interface for software control
- Analog output monitoring (DAC)
- Configurable discriminator pulse width (8-64 ns)

## Hardware Requirements

- **Board:** Red Pitaya STEMlab 125-14 Xilinx Zynq-7010 (xc7z010clg400-1)
- **Development Tools:** 
  - Vivado 2020.2 or later
  - GCC compiler (on Red Pitaya)
- **External Connections:**
  - PMT or pulse source → RF Input 1
  - Trigger signal (10 Hz) → DIO4_P
  - Optional: Oscilloscope monitoring on DIO5_N, DIO0_N
 
## System Architecture

Here's a brief description of the implementation.

A rising edge of a trigger signal (YAG_trigger at say 10 Hz) initiates a counting sequence. The counting is performed in time bins of width 10 &micro;s. Thus a 100 kHz clock signal, internally generated and referred to as the bin-clock, is used to count and index bins. Within each bin the number of input pulses received are counted using a 250 MHz clock (derived from the ADC clock). The counting is continuously performed till the bin number reaches 3000 (relevant in the experiment) and the data is temporarily stored in a memory implemented within the fabric. On the falling edge of the trigger signal, the software which directly interfaces with AXI GPIO ports, can be used to read-out the counts vs bin-index data. An analog output monitor of the counter data is also generated at the DAC output port of the Red Pitaya.

The FPGA logic is designed to robustly handle clock domain crossing. A clock domain crossing, in this context, occurs when the adc read rate and the FPGA processing clock rates are different. A simple FIFO, designed solely for this application, capable of transferring data across clock domain crossing is integrated into the design. The FIFO has a AXI GPIO readable full/empty port, and is designed to work with continuous stream of incoming data.

In the current design, the ADC clock is operating at 125 MHz (max achievable in the Red Pitaya 125-14 board), and the fpga logic is deliberately run at a different clock to demonstrate the robust implementation of the system. To demonstrate the max clock speed at which the FPGA logic still meets the  timing constraints, the FPGA is successfully operated at 250 MHz.
The FPGA could also be operated at a slower rate, in which case the FIFO will buffer the data transfer between the ADC and the FPGA logic stages. However this would normally require implementing a deeper FIFO to ensure no incoming data in the duration of interest is missed.

A minimal schematic of this design is shown here, along with test result obtained for each module.
![Alt text](./asset/PhotonCounter_RP_TOF.jpg)
(The NIM disc signal is derived from a NIM discriminator and pulse converter unit, displayed here for comparision with the RP based discriminator.)


## Input/Output 
The relevant I/O pins and ports on the board are
| Name | Pin/Port |  Type | Description |
| -------- | -------- | -------- | -------- |
| YAG_Trigger | DIO4_P | Input | External trigger signal. Synchronous with the YAG trigger(or the trigger representing a beginning of a counting sequence) used for the experiment. Counting begins at the rising edge of the trigger signal and lasts for 30 ms (corresponding to 3000 bin width each 10 us). |
| Discriminator Monitor| DIO5_N  | Output | Generates a TTL pulse when the threshold condition is met.  |
| YAG_Trigger Monitor| DIO0_N  | Output | Outputs the YAG_Trigger singal. Only meant for diagnostics. |
| Pulse Input | RF Input 1 | Input | PMT pulse signal. Typically a negative pulse. |
| Counter Analog Out | RF Output 1 | Output | Count vs bin number generated as an analog signal sampled out at about 5.86 MSps. |

The design contains AXI GPIOs that can be accessed by software. A sample C code is provided.
| Name | Memory Address |  Type | Description |
| -------- | -------- | -------- | -------- |
| axi_gpio_0 | 0x4120_0000 | Input |12 bit. Memory address to read the content of the counter RAM |
| axi_gpio_1 | 0x4121_0000  | Output | 14 bit. Threshold value (unsigned input, interpreted as 14-bit 2's complement by hardware). Values 0-8191 represent positive thresholds, values 8192-16383 represent negative thresholds. Threshold is met when \|signal\| > \|threshold\| |
| axi_gpio_2| 0x4122_0000  | Input | 8 bit. Count value at the memory address specified by axi_gpio_0  |
| axi_gpio_3 | 0x4123_0000 | Output | 1 bit. Read the YAG_trigger signal |
| pll_locked_out| 0x4124_0000 | Output | 1 bit. Read the locked state of the PLL. 1 represents locked, and 0 unlocked. |
| empty_full| 0x4125_0000 | Output | 2 bit. FIFO empty and full signal. Bit 0 represnts if full, and Bit 1 represnets if empty. |
| axi_gpio_4| 0x4126_0000 | Output | 1 bit. TTL signal that goes high when the signal meets the threshold condition. |
| disc_width| 0x4127_0000 | Input |2 bit. Discriminator pulse width setting (see table below)   |

**Discriminator Width Settings:**

| Value | Clock Cycles | Duration @ 250 MHz |
|-------|--------------|-------------------|
| 0 | 2 | 8 ns |
| 1 | 4 | 16 ns |
| 2 | 8 | 32 ns |
| 3 | 16 | 64 ns |

## Installation & Usage
Copy the bitstream file to the Red Pitaya (e.g. via `scp`) and load the FPGA bitstream file onto the device with the following command on the terminal.
<div>
  <button class="copy-button" onclick="copyToClipboard(this.parentElement.nextElementSibling.textContent)"></button>
  <pre><code>cat ultimate_counter_250MHz_github.bit > /dev/xdevcfg</code></pre>
</div>
The provided C code <i>counter_clock.c</i> can be used to read the count values as a function of bin number. Bin number goes from 1-3001, any intermediate values may be used as needed.
Compile the C readout program,
<div>
  <button class="copy-button" onclick="copyToClipboard(this.parentElement.nextElementSibling.textContent)"></button>
  <pre><code>gcc counter_clock.c</code></pre>
</div>
and execute it with the following syntax to read the count values.

`./a.out [threshold] [bin_start] [bin_end] [disc_width] `
  For instance,
<div>
  <button class="copy-button" onclick="copyToClipboard(this.parentElement.nextElementSibling.textContent)"></button>
  <pre><code>./a.out 13000 1 3001 2</code></pre>
</div>
reads the counts registered in bins 1 through 3001, with threshold set at 13000 (in 2's complement rep) producing discriminator TTL signal that is 32 ns wide.

**Notes:** <br>
- Counter memory resets on YAG trigger rising edge <br>
- Bin 0 is reserved; use bins 1-3000 for data acquisition <br>
- Bin numbers > 3000 return count value of 0


## Modifications
The project can be built as a Vivado project using the <i>photon_counter.tcl</i> and necessary modifications can be made. 

