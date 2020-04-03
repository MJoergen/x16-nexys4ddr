# This Makefile is used for simulation testing of the VERA module.
# Simulation is done using the program ghdl. It may be available
# in your OS repository, otherwise it may be downloaded from here:
# https://github.com/ghdl/ghdl

SUB = ../../sub
SOURCES  = vera.vhd vram.vhd palette.vhd
SOURCES += $(SUB)/cdc/src/cdc.vhd $(SUB)/cdc/src/pulse_conv.vhd         # Mixed clock domain
SOURCES += cpu/config.vhd cpu/cpu.vhd                                   # All CPU clock domain
SOURCES += vga/pix.vhd vga/sync.vhd vga/vga.vhd vga/layer.vhd           # All VGA clock domain
SOURCES += vga/mode0.vhd vga/mode7.vhd                                  # All VGA clock domain
SOURCES += cpu/spi_master.vhd cpu/spi_slave.vhd cpu/spi.vhd

TB          = tb
TB_SOURCES  = sim/cpu_dummy.vhd
TB_SOURCES += sim/$(TB).vhd
WAVE        = sim/$(TB).ghw
SAVE        = sim/$(TB).gtkw


#####################################
# Simulation
#####################################

.PHONY: sim
sim: $(SOURCES)
	ghdl -i --std=08 --work=work $(SOURCES) $(TB_SOURCES)
	ghdl -m --std=08 --ieee=synopsys -frelaxed-rules $(TB)
	ghdl -r $(TB) --assert-level=error --wave=$(WAVE) --stop-time=42000ns
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

