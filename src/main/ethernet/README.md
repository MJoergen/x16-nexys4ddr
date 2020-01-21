# The Ethernet port #

This directory contains the VHDL source code for the Ethernet port.

This gives the CPU access to send and receive Ethernet frames.

## Memory map
```
000 : ETH_RX_LO
001 : ETH_RX_HI
010 : ETH_RX_DAT
011 : ETH_RX_OWN
100 : ETH_TX_LO
101 : ETH_TX_HI
110 : ETH_TX_DAT
111 : ETH_TX_OWN
```

The Ethernet modules contains two separate virtual address spaces, one for
receiving frames and one for transmitting frames. The two virtual address
spaces are non-overlapping, and each have a fixed size of 2 kB. Both address
spaces have auto-incrementing pointers.

The pointer to the virtual address space is written in the registers LO and HI.
Data can be read from the receive buffer by reading the DAT register.  There is
no support for writing to the receive space. The transmit space can be read
from and written to. Both read and write cause the address pointer to auto-
increment.

Ownership of each address space is controlled by the OWN register.  A value of
0 means the address space is owned by the CPU, while a value of 1 means the
address space is owned by the Ethernet module.  Ownership can never be taken,
only be given.

## Transmit a frame
To transmit an Ethernet frame, the CPU does the following:
* Write 0 to ETH\_TX\_LO
* Write 0 to ETH\_TX\_HI
* Repeatedly write frame data - one byte at a time - to ETH\_TX\_DAT
* Write 1 to ETH\_TX\_OWN
* Finally, poll the ETH\_TX\_OWN register, waiting until 0 is read back.

## Receiving frames
To enable receiving of frames the CPU does the following:
* Write a 1 to ETH\_RX\_OWN
* Poll the ETH\_RX\_OWN register, waiting until 0 is read back.
* Write 0 to ETH\_RX\_LO
* Write 0 to ETH\_RX\_HI
* Repeatedly read frame data - one byte at a time - from ETH\_RX\_DAT

