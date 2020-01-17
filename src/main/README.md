# The source code for the MAIN module #

This directory contains the VHDL source code for the MAIN module.

This module contains the CPU, RAM, ROM, I/O chips, and Ethernet port, as well
as performs address decoding of the CPU's memory map.

# Test in simulation
This module can be tested separately in simulation. To do this, just type
"make". This will assemble and execute the small program in test/rom.s.

# Memory map (not yet implemented)
* 0x0000 - 0x9EFF : Low RAM
* 0x9F00 - 0x9FFF : I/O
* 0xA000 - 0xBFFF : Banked RAM (256 banks of 8 kB)
* 0xC000 - 0xFFFF : Banked ROM (8 banks of 16 kB)

## I/O memory map
* 0x9F20 - 0x9F3F : [VERA](../vera/README.md)
* 0x9F60 - 0x9F6F : VIA1 (Selects ROM and RAM bank)
* 0x9F70 - 0x9F7F : VIA2 (Connected to PS/2 keyboard)
* 0x9FC0 - 0x9FCF : Ethernet port
* 0x9FE0 - 0x9FEF : YM2151

## ROM banking
The ROM is banked as follows
* 0 : KERNAL
* 1 : KEYBD
* 2 : CBDOS
* 3 : GEOS
* 4 : BASIC
* 5 : MONITOR
* 6 : CHARSET
* 7 : ETH

To select the ROM bank, write to bits 2-0 of address 0x9F60.
To select the RAM bank, write to address 0x9F61.

