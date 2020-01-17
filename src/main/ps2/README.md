# The PS/2 port #

This directory contains the VHDL source code for the PS/2 port.

This gives the CPU access to control the CLK and DATA pins on the PS/2 port.

## PS/2 buffer
Since the Nexys4DDR board has a USB-PS/2 converter, the timing is subtly
different from a regular keyboard.
