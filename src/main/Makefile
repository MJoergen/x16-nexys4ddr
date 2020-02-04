# This Makefile is used for simulation testing of the MAIN module.
# Simulation is done using the program ghdl. It may be available
# in your OS repository, otherwise it may be downloaded from here:
# https://github.com/ghdl/ghdl

XILINX_DIR = /opt/Xilinx/Vivado/2019.2

SUB      = ../../sub
SOURCES  = main.vhd
SOURCES += rom.vhd
SOURCES += ram.vhd
SOURCES += via.vhd
SOURCES += ../cdc.vhd
SOURCES += ps2/ps2_buffer.vhd
SOURCES += ps2/ps2_reader.vhd
SOURCES += $(SUB)/65c02/src/cpu_65c02.vhd
SOURCES += $(SUB)/65c02/src/control/control.vhd
SOURCES += $(SUB)/65c02/src/control/microcode.vhd
SOURCES += $(SUB)/65c02/src/datapath/datapath.vhd
SOURCES += $(SUB)/65c02/src/datapath/alu.vhd
SOURCES += $(SUB)/65c02/src/datapath/ar.vhd
SOURCES += $(SUB)/65c02/src/datapath/hi.vhd
SOURCES += $(SUB)/65c02/src/datapath/lo.vhd
SOURCES += $(SUB)/65c02/src/datapath/pc.vhd
SOURCES += $(SUB)/65c02/src/datapath/sp.vhd
SOURCES += $(SUB)/65c02/src/datapath/sr.vhd
SOURCES += $(SUB)/65c02/src/datapath/xr.vhd
SOURCES += $(SUB)/65c02/src/datapath/yr.vhd
SOURCES += $(SUB)/65c02/src/datapath/zp.vhd
SOURCES += $(SUB)/65c02/src/datapath/mr.vhd
SOURCES += ../vera/cpu/mmu.vhd
SOURCES += ../vera/cpu/config.vhd
SOURCES += ../vera/cpu/cpu.vhd
SOURCES += ../vera/vram.vhd
SOURCES += ../vera/cpu/spi.vhd
SOURCES += ../vera/cpu/spi_master.vhd
SOURCES += ps2/ps2_writer.vhd
SOURCES += ../vera/cpu/spi_slave.vhd
SOURCES += ethernet/lan8720a/lan8720a.vhd
SOURCES += ethernet/lan8720a/rmii_rx.vhd
SOURCES += ethernet/lan8720a/rmii_tx.vhd
SOURCES += ethernet/rx_dma.vhd
SOURCES += ethernet/fifo.vhd
SOURCES += ethernet/rx_header.vhd
SOURCES += ethernet/tx_dma.vhd
SOURCES += ethernet/ethernet.vhd
SOURCES += $(SUB)/ym2151/ym2151_package.vhd
SOURCES += $(SUB)/ym2151/ym2151_config.vhd
SOURCES += $(SUB)/ym2151/ym2151_sine_rom.vhd
SOURCES += $(SUB)/ym2151/ym2151.vhd
SOURCES += test/tb.vhd
SOURCES += test/phy_sim.vhd
TB       = tb
WAVE     = test/tb.ghw
SAVE     = test/tb.gtkw


#####################################
# Simulation
#####################################

sim: $(SOURCES) rom.txt
	ghdl -i --ieee=synopsys --std=08 --work=unisim $(XILINX_DIR)/data/vhdl/src/unisims/unisim_VCOMP.vhd
	ghdl -i --ieee=synopsys --std=08 --work=unisim $(XILINX_DIR)/data/vhdl/src/unisims/unisim_VPKG.vhd
	ghdl -i --ieee=synopsys --std=08 --work=unisim $(XILINX_DIR)/data/vhdl/src/unisims/primitive/*.vhd
	ghdl -i --ieee=synopsys --std=08 --work=work $(SOURCES)
	ghdl -m --ieee=synopsys --std=08 --ieee=synopsys -frelaxed-rules $(TB)
	ghdl -r $(TB) --max-stack-alloc=16384 --assert-level=error --wave=$(WAVE) --stop-time=100us
	gtkwave $(WAVE) $(SAVE)

# Uncomment the line below to run the 6502 functional test suite.
#rom.txt: test/65C02_extended_opcodes_test.s
#rom.txt: test/6502_functional_test.s
rom.txt: test/rom.s
	ca65 $^ -o test/rom.o
	ld65 -vm -m test/rom.map -C test/ld.cfg test/rom.o
	./bin2hex.py rom.bin rom.txt



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
	rm -rf rom.bin
	rm -rf rom.txt
	rm -rf test/rom.o
	rm -rf test/rom.map

