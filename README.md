# Commander X16 #

This project aims at implementing the Commander X16 on the Digilent Nexys4DDR
board.

# Credit
First of all, this project makes use of all the ideas and work done on the Commander X16,
in particular the KERNAL and BASIC ROM's. So a great THANK YOU goes to David Murray
and to all of his team. This project wouldn't be possible without them.

# Scope of this project
When this project is finished, a complete clone of the Commander X16 (with limitations, see below)
will be running in hardware. My intension is to have a complete clone, neither more nor less.

For example, the Nexys4ddr board has an on-board
Ethernet connection, so it is possible to experiment with adding network functionality
to the Commander X16. However, this is outside the scope of this project. The reason is that new
features - I believe - should be designed by and driven by the Commander X16 team.

The Nexys4DDR board is quite expensive, and it could be interesting looking into porting
this project to a smaller board, e.g. the BASYS3. However, this is not something I'm
planning on doing.

# Technical details and limitations

The Commander X16 has the following features, all of which will be
implemented in the FPGA on the Digilent board.
* CPU (65C02 @ 8 MHz)
* GPU (VERA)
* 128 kB ROM (Banked)
* 2 MB RAM (Banked)
* VIA chips (Interfaces to keyboard)
* SD card (TBD)
* Sound chip (YM2151)

The VERA chip contains additional 128 kB of video RAM.

The FPGA on the Digilent board is a Xilinx Artix-7 (XC7A100T), which contains
540 kB of Block RAM. So, this project will not support the full 2 MB of RAM
on the X16. It might be possible to use the DDR2 RAM avaiable on the board, but
this is TBD.

# Additions

I've decided to add a connection to the Ethernet port, as a way of
loading/saving programs. This requires modifications to the X16 Rom.

# Sub-repositories

I've split the implementation into a number of sub-repositories:
* cdc     : This is a small library containing modules for Clock Domain Crossing.
* 65c02   : This is an implementation of the 65C02 processor.
* ym2151  : This is an implementation of the YM2151 sound chip.
* x16-rom : This is a fork of the Commander X16 ROM, where I have added Ethernet support.

# Implementation details

This implementation relies on a single onboard crystal of 100 MHz. From that a number of clocks
are generated:
* MAIN   : This drives the CPU, RAM, ROM, etc, at 8.33 MHz
* VERA   : This drives the VERA, at 25.2 MHz
* ETH    : This drives the Ethernet port, at 50 MHz
* YM2151 : This drives the YM2151 sound, at 3.57 MHz
* PWM    : This drives the Pulse Width Modulator connected to the YM2151, at 100 MHz.

# Pre-requisites
So to use this project on real hardware you need the following:
* A Nexys4DDR board from Digilent, with USB cable for FPGA configuration.
* The Vivado tool chain installed.
* A VGA cable from the board to a VGA monitor.
* A keyboard (with USB connector).

# Try it out!
Just type "make", and a bit-file will be generated and programmed to the Nexys4DDR board.

## Running simulations
* To test the VERA in simulation, go into the src/vera directory and type "make".
* To test the CPU in simulation, go into the src/main directory and type "make".

## Log
I'm keeping a [log](log.md) of my progress, so I can keep track of all my
ideas.

## Links
* [Nexys4DDR board from Digilent](https://reference.digilentinc.com/reference/programmable-logic/nexys-4-ddr/start)
* [GitHub repository for the Commander X16 project](https://github.com/commanderx16)
