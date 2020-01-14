# This Makefile is used for simulation testing of the MAIN module.
# Simulation is done using the program ghdl. It may be available
# in your OS repository, otherwise it may be downloaded from here:
# https://github.com/ghdl/ghdl

XILINX_DIR = /opt/Xilinx/Vivado/2019.2

SOURCES  = main.vhd rom.vhd ram.vhd via.vhd ../cdc.vhd
SOURCES += ps2/ps2_buffer.vhd ps2/ps2_reader.vhd
SOURCES += cpu_65c02/cpu_65c02.vhd cpu_65c02/ctl.vhd cpu_65c02/datapath.vhd cpu_65c02/microcode.vhd
SOURCES += cpu_65c02/alu.vhd cpu_65c02/ar.vhd cpu_65c02/hi.vhd cpu_65c02/lo.vhd
SOURCES += cpu_65c02/pc.vhd cpu_65c02/sp.vhd cpu_65c02/sr.vhd cpu_65c02/xr.vhd 
SOURCES += cpu_65c02/yr.vhd cpu_65c02/zp.vhd cpu_65c02/mr.vhd
SOURCES += ../vera/cpu/mmu.vhd ../vera/cpu/config.vhd ../vera/cpu/cpu.vhd ../vera/vram.vhd
SOURCES += ../vera/cpu/spi.vhd ../vera/cpu/spi_master.vhd
SOURCES += ps2/ps2_writer.vhd ../vera/cpu/spi_slave.vhd
SOURCES += ethernet/lan8720a/lan8720a.vhd ethernet/lan8720a/rmii_rx.vhd ethernet/lan8720a/rmii_tx.vhd
SOURCES += ethernet/rx_dma.vhd ethernet/fifo.vhd ethernet/rx_header.vhd ethernet/tx_dma.vhd
SOURCES += ethernet/ethernet.vhd
SOURCES += test/tb.vhd test/phy_sim.vhd
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

