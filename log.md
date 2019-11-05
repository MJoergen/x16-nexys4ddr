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

Next step is to get the SD card working, as well implementing the remaining
VERA modes.

