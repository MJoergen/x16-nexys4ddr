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

The VERA chip contains additional 128 kB of video RAM.

The FPGA on the Digilent board is a Xilinx Artix-7 (XC7A100T), which contains
540 kB of Block RAM. So, this project will not support the full 2 MB of RAM
on the X16. It might be possible to use the DDR2 RAM avaiable on the board, but
this is TBD.

# Pre-requisites
So to use this project on real hardware you need the following:
* A Nexys4DDR board from Digilent, with USB cable for FPGA configuration.
* The Vivado tool chain installed.
* A VGA cable from the board to a VGA monitor.
* A keyboard (with USB connector).

# Try it out!
Just go into the fpga directory and type "make".

## Running simulations
* To test the VERA in simulation, go into the fpga/vera directory and type "make".
* To test the CPU in simulation, go into the fpga/main directory and type "make".

## Log
I'm keeping a [log](log.md) of my progress, so I can keep track of all my
ideas.

## Links
* [Nexys4DDR board from Digilent](https://reference.digilentinc.com/reference/programmable-logic/nexys-4-ddr/start)
* [GitHub repository for the Commander X16 project](https://github.com/commanderx16)
