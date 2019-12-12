# Progress Log

This file contains a brief description of my process with implementing the X16
on the Nexys4DDR board.

## 2019-10-26
Initial checkin, where the VGA port displays a simple checkerboard pattern in
640x480 resolution.  I'm planning on running the entire design using two
clocks: The VERA will run at the VGA clock of 25 MHz, and the rest of the
design will run at the CPU clock of 8 MHz.

Next step: In order to get the VERA to display more than a checkerboard, I need
to dive into the VERA documentation. My intention is to get the default
character mode to work. The challenging part is actually how to test this
incrementally, i.e without having to wait until everything is implemented. I
will probably just hard code some characters and fonts to begin with, but then
quickly move on to implement the interface to the 65C02, and then hardcode a
process that simulates the CPU writes to the VERA.

I will wait with implementing the CPU, as I already have a working 6502 from
the dyoc project, where I just need to modify it for the 65C02.

## 2019-10-27
I've generated a list of all the writes performed by the KERNAL/BASIC during
startup, and this gives information on how to initialize the VERA. I will need
to emulate this when testing (before I implement the CPU). See the
[README](fpga/vera/README.md) in the vera subdirectory.

I've started implementing mode 0 (the default text mode). However, I've
immediately run into a problem. For each pixel being displayed, the VERA must
perform two reads from the Video RAM:
1. Reading from the MAP area to get the character value at the corresponding pixel.
2. Reading from the TILE area to get the tile data for this character.

Initially I had planned to place the MAP and TILE areas in two separate Block
RAMs, so that the reads could be performed simultaneously. However, with the
very flexible interface of the VERA this is not possible. So I need to rethink
this.  Furthermore, when implementing the sprite functionality I will need to
perform additional reads from the Video RAM.

## 2019-10-28
I realized that reading from Video RAM only needs to take place for every tile,
and not for every pixel. And since each tile is (at least) 8 pixels wide, there
is adequate time for reading.

The module needs to perform three reads from Video RAM for each eight
horizontal pixels: Two bytes from the MAP area, and one byte from the TILE
area.

So far, I'm ignoring all writes to the configuration registers, and only
focusing on getting the reads from Video RAM working properly. I've copied
(most of) the startup writes performed by the KERNAL/BASIC into a small module
that simulates the CPU. This should generate the same startup screen as the
X16, albeit with a black background.

To help debug the VERA implementation, I've added a test bench for simulating
the VERA. This immediately helped me find two bugs in mode0.vhd. One bug was
that the staged pixel counters were only updated once every tile, but should be
updated on every pixel. The other was insufficient delay when reading from
Video RAM.

## 2019-10-29
Testing mode 0 on hardware revealed a simple error of each tile being mirrored,
which was easy to fix.

I've faked the background colour by initializing the entire VRAM with blue
colour ('6' for background and foreground). This is just a temporary hack until
I get the CPU and KERNAL running.

I've added the translation between the internal and external memory map. The
writes to the VERA block have been changed to reflect the external addressing,
and I've added the writes to the VERA configuration registers. A few of these
registers are implemented, the rest are ignored.

I've renamed the file mode0.vhd to layer.vhd to better reflect its purpose,
and I've added a block diagram of my current limited implementation of the VERA.

The next step is to get the 65C02 CPU up and running.  In another project
[https://github.com/MJoergen/cpu65c02](https://github.com/MJoergen/cpu65c02)
I've ported a complete functional test suite for the 65C02. This I will use to
test my implementation of the 65C02 CPU. I already have a working 6502
implementation in my [Design Your Own
Computer](https://github.com/MJoergen/nexys4ddr/tree/master/dyoc) project, so
that should be a relatively easy task.

I still need to be very careful about the interface between the CPU and the
VERA, because they will be running two different clock frequencies.  In
particular, since reading from the VERA potentially updates the state in the
VERA (addresses auto-increment) this makes the task very delicate.

## 2019-10-31
Getting the CPU read access turned out to be a lot more work than anticipated.
Originally, I had planned to run the VERA and the CPU on separate clock
domains, and have a clock domain crossing (CDC) circuit in the top level
module.  However, this would cause large delays (latency) when the CPU wants to
read from the VERA.

Instead, I now use the fact that the Block RAMs in the FPGA are true dual port,
so one port can run on the CPU clock and the other on the VGA clock.  The VERA
module must therefore have both clocks, which changes the design considerably.

From a hardware perspective this also makes much more sense. A physical VERA
chip would have pins connecting to the CPU, including a corresponding CPU clock
signal, and would also have another VGA clock signal to drive the VGA output
pins.

I still don't have the CPU implemented, so I'm using a mock cpu\_dummy module,
and I've moved this into the top level, i.e. outside the VERA module.

The 65C02 CPU expects reads to be ready the very next clock cycle, this is
essentially a combinatorial read.  However, since the Block RAMs in the FPGA
are synchronous, there appears to be a problem. However, I solved that by
clocking all the Block RAMs on the *falling* edge of the CPU clock. This
reduces the slack in the timing, but since the CPU is only running at 8 MHz,
this is no problem.


The next step is now to get the CPU running.

## 2019-11-1

I've added a simple memory map with 16 kB RAM and 16 kB ROM, moving another
small step towards adding the CPU.  There is no banking and no I/O ports,
except the VERA.

I've added debug signals, so the LED's show either:
* The last (internal) address written to in the VERA.
* The current index. This will become the current instruction pointer, when
the CPU is ready.

Choosing between these two is done using switch number 0.

## 2019-11-3

I've now copied over the 6502 implementation from my other project
[dyoc](https://github.com/MJoergen/nexys4ddr/tree/master/dyoc). I've done a
little bit of cleanup, and I've tested the CPU using the 6502 functional test
suite.

So the status is that the project can now execute programs for the 6502
processor.  I've written a short test program in assembly that prints a few
squares on the screen.

Next step is to augment the CPU with the 65C02 instructions.

## 2019-11-5
I've modified the CPU implementation with the 65C02 instructions and in the
process I've uncovered what I believe is a bug in Vivado.

But first, I noticed a very bad design decision in my 6502 implementation. For
some instructions (e.g. INC d) the processor needs to do a read-modify-write
operation on a given memory address. I had implememted that by having the
processor do the read and the write in the same clock cycle. That does actually
work, because the read happens on the falling edge, while the write takes place
on the following rising edge.

However, in the current design I need the RAM to process both read and writes
on the falling clock edge, in order to match the behaviour of the VERA block.
But changing the RAM to do both read and write on the falling edge will of
course not work without changing the design, because one can no longer do the
read and the write in the same clock cycle. However, I discovered that the design
(unexpectedly) DOES work in hardware, whereas it (expectedly) fails in simulation.
After investigating this discrepancy it appears the Vivado synthesis
incorrectly clocks the write signal to the Block RAM on the rising edge,
despite having specified falling edge in the RTL. I've reported this issue in
the Xilinx forum
[here](https://forums.xilinx.com/t5/Synthesis/falling-edge-not-supported-in-inferred-RAM/m-p/1039276).

Despite this setback, and while waiting for a response from Xilinx, I've
removed this simultaneous read-and-write-in-same-cycle behaviour.  This will
lead to instructions like INC taking one more clock cycle than before, but on
the other hand will more closely mimic the real 6502/65C02 processor.

I've added support for decimal mode. I've added the two VIA I/O controllers, as
well as keyboard support and ROM banking.

I'm now running the official r34 ROM on the Nexys 4 DDR board !!

The only caveat is that it takes nearly 3 hours to generate a bit-file, where
the bulk of the time is spent reading the 128 kByte ROM image. I don't know
why this takes so long, and I've filed yet another issue on Xilinx' forum.

Next step is to get the SD card working (i.e. the VERA SPI support), implement
RAM banking, and implement the remaining VERA modes.

## 2019-11-6
I've added RAM banking, but only for 128 kB so far. I've added VSYNC interrupt
from the VERA, which the KERNAL uses as a 60 Hz timer.

## 2019-11-7
I've agreed with PeriFractic to make the repository private, because there is
a copyright infringement. In the interest of remaining good friends, it seemed
best to make the repository private.

I found a work-around for the Vivado bug that mixed rising and falling edge
clocks on the BRAMs. The solution is to use rising\_edge everywhere, but to
invert the clock inputs to the specific blocks, i.e. RAM, ROM, VIA, and VERA.

I found a solution for the very slow build times (more than two hours, when the
ROM is 128 kB). The solution involves quite a bit of tcl magic, but it appears
to work now. It remains to be seen, how stable this solution is.

On the other hand, the current version of the project doesn't work, so I've
introduced a bug somewhere.

## 2019-11-10
After several bugfixes, the ROM now starts up, and the cursor blinks. One of
the bugs was that the VIA2 port B input was held low, and the ROM interpreted
this as a mouse event in progress.

The keyboard still doesn't work, and the root cause is not found. When running
my own test in rom.s it does work, but the timing is different from the
standard, so maybe that is causing problems.

So more debugging is still in progress, now using the Internal Logic Analyzer,
and I'm writing a PS/2 buffer module as a work-around for the timing problems.

## 2019-11-12
Now keyboard works! I'm using a PS/2 buffer, but not sure if it is still
needed.  The reason is that I didn't fully understand how to implement
bi-directional signals, and I didn't fully appreciate that the PS/2 signals are
open-collector.  This means that the FPGA should either drive the pin low, or
should leave the pin tristated. However, the FPGA should never drive the pin
high. This is now fixed, so I need to test, whether the buffer is still needed.

The ROM defaults to US layout, but supposedly that can be changed by
pressing the F9 key. Otherwise, I can modify line 123 in kernal/editor.1.s
"nemu  lda #0          ;US layout"
to something different.

I did run into the problem mentioned by Joshua Scholar about sticky shift keys,
so I'm currently running on his fork on github:
https://github.com/differentprogramming/x16-rom/commit/657bae1b70fe9688a33e5204ea10849bac061580

Next step (other than trying the F9 key and trying without the PS/2 buffer) is
to work on the SD card.

Another thing to try is whether line 101 of main/cpu\_65c02/ctl.vhd
"ADDR\_PC + PC\_INC when cnt = 0 else"
is necessary. Or whether line 92
"microcode\_addr\_s <= ir & cnt;"
can perhaps be tweaked instead.

## 2019-11-14
Ok, so apparently, the PS/2 buffer is needed. Without it, the ROM gets no data
from the keyboard.

Keyboard layouts work fine, but there is no Danish layout enabled by default in
the ROM.

A first attempt at rewriting the code in ctl.vhd lead to a combinatorial loop.
So I've given up for now ...

## 2019-11-18
I double-checked that the keyboard waits over 5000 clock cycles before sending
data when it is allowed. So clearly, the software should not have to wait for
that long in every timer tick. 

## 2019-11-24
I've been battling with the SD-card SPI interface, and finally got it working.
The last problem was that the CS pin was inverted. It apparently is active low.
I found that out after reading a few hundred pages of documentation ...

The ROM has been updated to avoid the sticky keys. The latest ROM doesn't work
with the SD-card in the emulator, nor on by board. So I assume my board is
working, and that the problem is in the ROM.

## 2019-11-25
The pull request #73 for the ROM describes a solution to get the SD-card to
work.  It still needs testing on the board, and also it's unclear whether the
SAVE command works.

I'm thinking about implementing network support, at least for LOAD and SAVE.
My first thought was to encapsulate the SD card requests (read\_block etc) into
proprietary UDP packets, but I prefer a solution using existing protocols.  So
another idea is to implement a TFTP client in the ROM, see e.g. [RFC 1350 - The
TFTP protocol](https://tools.ietf.org/pdf/rfc1350.pdf) . The server could e,g.
be tftpd-hpa.

## 2019-11-26
Thinking more about the Ethernet port, I imagine having a narrow interface just
like the VERA, i.e. something like:

|Address|Description                                                |
|-------|-----------------------------------------------------------|
|9FE0   | Port A low byte                                           |
|9FE1   | Port A high byte (bits 3-0), port A increment (bits 7-4)  |
|9FE2   | Port A data                                               |
|9FE3   | Rx control/status (bit 0)                                 |
|9FE4   | Port B low byte                                           |
|9FE5   | Port B high byte (bits 3-0), port B increment (bits 7-4)  |
|9FE6   | Port B data                                               |
|9FE7   | Tx control/status (bit 0)                                 |

The ethernet module will have an internal memory map of 4 kB, enough to store
one Ethernet frame for receive and one for transmit.

The Rx/Tx control/status register is a single bit showing ownership of the
buffer. A value of 0 indicates ownership by CPU, and a value of 1 indicates
ownership by Ethernet module. Ownership can only be given (cooperatively),
never taken.

To enable Ethernet Rx, the CPU write the value 1 to the register 9FE3. The CPU
may poll this register, and when a frame has been received, the value in
register 9FE3 will be read as zero. The frame now resides within the Ethernet
module at address 0x0000, and is now owned by the CPU. The first two bytes are
the length of the frame (big endian) in number of bytes (excluding CRC), and
the remaining bytes are the frame, starting with the MAC header.  The CPU may
inspect the packet, and possibly copy the packet to CPU RAM. When the CPU is
finished with the buffer, the CPU may transfer ownership back to the Ethernet
module, ready for receiving the next frame.

To send an Ethernet frame, the CPU writes the ethernet frame into virtual
address 0x0400, where the first two bytes indicate the length of the frame (big
endian).  Then the CPU writes a 1 to the register 9FE7, thus transferring
ownership to the Ethernet module.  When the frame has been transmitted, the
Ethernet module will reset the value in the register 9FE7, thus granting
ownership back to the CPU.

When the CPU has released ownership all write accesses are disabled. The CPU
may still read whatever contents are in the virtual memory, but any writes are
ignored.

## 2019-12-05
First of all, I changed the ethernet memory map to 9FC\* instead of 9FE\*,
because the latter was already in use by the sound device.

I've been contemplating how to read and write files over ethernet.  I've
started with the simple version, where the network interface supports two
commands over UDP: "read block" and "write block", each block is 512 bytes, and
is addressed by a 32-bit LBA (logical block address). This hooks nicely into
the API provided in the file sdcard.asm.

The above method is essentially a networked block device. Curiously, there
already exists a standardized NBD (network block device), but it runs on top of
TCP. So one option is to implement TCP.  But the main drawback with the above
is that the SD card will no longer be available.

A more general approach is to add support for an entire new Commodore device on
the TALK/LISTEN layer. This requires adding support for the LOAD and SAVE
commands. I initially considered TFTP, but it does not provide support for
directory listing. So now I'm looking into NFS (RFC 1094) over RPC (RFC 1057).

## 2019-12-06
DONE:
* Fix debug.tcl so it works with multiple clock nets.

TODO:
* Complete sd\_net.py so it can emulate read\_block and write\_block
* Implement TFTP server in python
* Implement TFTP client parallel with CBDOS (e.g. device number 9).

## 2019-12-09
So I went ahead and implemented the TFTP client, and removed the virtual SD
card.  Currently, it supports reading a file from a TFTP server. The plan is to
make an augmented TFTP server, which will "translate" the file named "$" to a
directory listing. The ROM will be oblivious, so it means the user will have to
type first: LOAD "$",9 and then type LIST to get the directory listing.

I fixed a bug in the PS2 writer where it would sometimes come out of
sync with the ROM.

TODO:
* Make an augmented TFTP server that can generate a directory listing.
* Implement SAVE.
* Allow both CBDOS and ETH to work simultaneously.

## 2019-12-10
I got TFTP SAVE to work in the emulator, so now it just needs testing on hardware.
I've written a rudimentary TFTP server, and will then test it with the new ROM.
Then I'll add support for directory listing!
I still need to add simultaneous support for CBDOS and ETH.

Later, I'll go back and add support for more VERA modes.

## 2019-12-11
I simplified the implementation by removing a lot of unused functionality.
Now the ROM works with my home-made TFTP server.

TODO:
* Add simultaneous support for CBDOS and ETH.
* Add support for directory listing!
* Add support for more VERA modes.

## 2019-12-12
So I got the directory listing working. And I've written a few sample
programs in BASIC. I want to make some more simple programs in BASIC.


