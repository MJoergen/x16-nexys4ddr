# The source code for the MAIN module #

This directory contains the VHDL source code for the MAIN module.

This module contains the CPU, RAM, ROM, I/O chips, as well as
performs address decoding of the CPU's memory map.

TBD: So far, there is no support for RAM or ROM banking. This will
be added later.

# Memory map
* 0x0000 - 0x9EFF : Low RAM
* 0x9F00 - 0x9FFF : I/O
* 0xA000 - 0xBFFF : Banked RAM (256 banks of 8 kB)
* 0xC000 - 0xFFFF : Banked ROM (8 banks of 16 kB)

## I/O memory map
* 0x9F00 - 0x9F1F : Reserved
* 0x9F20 - 0x9F3F : [VERA](fpga/vera/README.md)
* 0x9F40 - 0x9F5F : Reserved
* 0x9F60 - 0x9F6F : VIA1 (Selects ROM and RAM bank)
* 0x9F70 - 0x9F7F : VIA2 (Connected to PS/2 keyboard)
* 0x9F80 - 0x9F9F : RTC (not present on Digilent)
* 0x9FA0 - 0x9FFF : Reserved

## Banking
The ROM is banked as follows
* 0 : KERNAL
* 1 : KEYBD
* 2 : CBDOS
* 3 : GEOS
* 4 : BASIC
* 5-7 : Unused

To select the ROM bank, write to bits 2-0 of address 0x9F60.
To select the RAM bank, write to address 0x9F61.

