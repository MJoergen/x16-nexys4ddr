# Design considerations

I initially started this project just writing a lot of code, but I gradually
realized that was the wrong approach. I need to first think of data
representation and signal widths and resolution.

## Audio signal generation

So let's start with the Nexys 4 DDR board. The audio output is a single bit
from the FPGA, which is passed through a 4th-order low pass filter at 15 kHz.
So to synthesize an audio signal, Pulse Density Modulation can be used. In this
approach the output bit rapidly switches on and off, and the low pass filter
will then smooth out this digital signal, essentially removing all the high
frequency components.

The sampling rate of the PDM signal should be as high as possible, and for
convenience I have chosen to use the input clock of 100 MHz.

The PDM module will take as input a density, represented as a fraction between
0 and 1 that is encoded as an unsigned integer. The PDM module works in
combination with the low-pass filter to give an approximate Digital-To-Analog
effect. In other words, the density value is roughly translated into a
proportional analog voltage on the audio output.

Note that there is a tradeoff between resolution in the time domain (i.e.
frequency response) and resolution in the voltage domain (i.e. signal-to-noise
ratio). With a PDM sampling rate of 100 MHz and an audio cutoff frequency of 15
kHz, the signal-to-noise ratio on the output of the PDM is 100000/15 =~ 6600.
I've therefore decided to use a density resolution of 12 bits which gives a
signal-to-noise ratio of 4192.  With 6 dB for each bit, this corresponds to 72
dB. This is the constant C\_PDM\_WIDTH.


## Sine Wave Generation

The heart of the YM2151 is a sine wave generator implemented as a big lookup
table (ROM). So what should be the address and data widths of this ROM?  Well
the output of the ROM feeds directly into the PDM module, so the data width
should be 12 bits as well. This is the constant C\_SINE\_WIDTH.  Note that the
sine function varies from -1 to 1, but the density varies from 0 to 1.  So the
sine function must be shifted up by 1, and scaled by a half.

## Frequency Generation

   constant C_PHASE_WIDTH : integer := C_SINE_WIDTH+3;


