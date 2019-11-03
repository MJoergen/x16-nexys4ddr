# The 65C02 CPU #

This directory contains the VHDL source code for the 65C02 CPU.

The implementation is split into a datapath, where all the registers are
stored, and the control logic. The latter is implemented using microcode.

The implementation is tested using the 6502 functional test suite. Running
on the hardware takes around 8 seconds.

TBD: Currently, only the 6502 opcodes are supported.
TBD: Decimal mode is not supported. Setting this flag is completely ignored.

