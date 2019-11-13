# The 65C02 CPU #

This directory contains the VHDL source code for the 65C02 CPU.

The implementation is split into a datapath, where all the registers are
stored, and the control logic. The latter is implemented using microcode.

The implementation is tested using the 6502 and 65C02 functional test suite.
Running on the hardware these tests take around 8 seconds each.

