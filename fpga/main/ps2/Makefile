# This Makefile is used for simulation testing of the MAIN module.
# Simulation is done using the program ghdl. It may be available
# in your OS repository, otherwise it may be downloaded from here:
# https://github.com/ghdl/ghdl

SOURCES  = ps2_reader.vhd ps2_writer.vhd
SOURCES += tb.vhd
TB       = tb
WAVE     = tb.ghw
SAVE     = tb.gtkw


#####################################
# Simulation
#####################################

sim: $(SOURCES)
	ghdl -i --std=08 --work=work $(SOURCES)
	ghdl -m --std=08 --ieee=synopsys -frelaxed-rules $(TB)
	ghdl -r $(TB) --max-stack-alloc=16384 --assert-level=error --wave=$(WAVE) --stop-time=300us
	gtkwave $(WAVE) $(SAVE)


#####################################
# Cleanup
#####################################

clean:
	rm -rf *.o
	rm -rf work-obj08.cf
	rm -rf unisim-obj08.cf
	rm -rf $(TB)
	rm -rf $(WAVE)
	rm -rf a.out

