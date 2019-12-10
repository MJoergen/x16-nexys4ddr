# The Ethernet port #

This directory contains the VHDL source code for the Ethernet port.

This gives the CPU access to send and receive Ethernet frames.

## Memory map
9FC0 : ETH\_RX\_LO
9FC1 : ETH\_RX\_HI
9FC2 : ETH\_RX\_DAT
9FC3 : ETH\_RX\_OWN

9FC8 : ETH\_TX\_LO
9FC9 : ETH\_TX\_HI
9FCA : ETH\_TX\_DAT
9FCB : ETH\_TX\_OWN

The memory map is designed to resemble that of the VERA. So there are two
separate virtual address spaces, one for receiving frames and one for
transmitting frames. The two virtual address spaces are non-overlapping, and
each have a fixed size of 2 kB. Both address spaces have auto-incrementing
pointers.

The pointer to the virtual address space is written in the registers LO and HI.
Data can be read from the receive buffer by reading the DAT register.  There is
no support for writing to the receive space. The transmit space can be read
from and written to. Both read and write cause the address pointer to auto-
increment.

Ownership of each address space is controlled by the OWN register.  A value of
0 means the address space is owner by the CPU, while a value of 1 mean the
address space is owned by the Ethernet module.  Ownership can never be taken,
only be given.

## Transmit a frame
To transmit an Ethernet frame, the CPU write the data, and then writes the
value 1 to the OWN register. Now the Ethernet module has owndership, and the
CPU can no longer access the transmit buffer, except to read the OWN register.
When the frame has been sent, the Ethernet module automatically resets the OWN
register, thus handing back ownership to the CPU.

