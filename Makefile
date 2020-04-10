# Specify install location of the Xilinx Vivado tool
XILINX_DIR = /opt/Xilinx/Vivado/2019.1

# This defines all the source files (VHDL) used in the project
SUB      = sub
SOURCES  = src/x16.vhd
SOURCES += src/clk_rst.vhd
SOURCES += $(SUB)/cdc/src/cdc_vector.vhd
SOURCES += $(SUB)/cdc/src/cdc.vhd
SOURCES += $(SUB)/cdc/src/pulse_conv.vhd
SOURCES += src/vera/vera.vhd
SOURCES += src/vera/vram.vhd
SOURCES += src/vera/palette.vhd
SOURCES += src/vera/cpu/cpu.vhd
SOURCES += src/vera/cpu/config.vhd
SOURCES += src/vera/cpu/spi.vhd
SOURCES += src/vera/cpu/spi_master.vhd
SOURCES += src/vera/vga/pix.vhd
SOURCES += src/vera/vga/sync.vhd
SOURCES += src/vera/vga/vga.vhd
SOURCES += src/vera/vga/layer.vhd
SOURCES += src/vera/vga/mode0.vhd
SOURCES += src/vera/vga/mode7.vhd
SOURCES += src/main/main.vhd
SOURCES += src/main/ram.vhd
SOURCES += src/main/rom.vhd
SOURCES += src/main/via.vhd
SOURCES += src/main/ps2/ps2_buffer.vhd
SOURCES += src/main/ps2/ps2_reader.vhd
SOURCES += src/main/ps2/ps2_writer.vhd
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
SOURCES += src/main/ethernet/lan8720a/lan8720a.vhd
SOURCES += src/main/ethernet/lan8720a/rmii_rx.vhd
SOURCES += src/main/ethernet/lan8720a/rmii_tx.vhd
SOURCES += src/main/ethernet/rx_dma.vhd
SOURCES += src/main/ethernet/fifo.vhd
SOURCES += src/main/ethernet/rx_header.vhd
SOURCES += src/main/ethernet/tx_dma.vhd
SOURCES += src/main/ethernet/ethernet.vhd
SOURCES += src/pwm.vhd
SOURCES += $(SUB)/ym2151/src/ym2151_package.vhd
SOURCES += $(SUB)/ym2151/src/rambe.vhd
SOURCES += $(SUB)/ym2151/src/get_config.vhd
SOURCES += $(SUB)/ym2151/src/rom_phase_inc.vhd
SOURCES += $(SUB)/ym2151/src/rom_delay.vhd
SOURCES += $(SUB)/ym2151/src/calc_phase_inc.vhd
SOURCES += $(SUB)/ym2151/src/calc_product.vhd
SOURCES += $(SUB)/ym2151/src/calc_waveform.vhd
SOURCES += $(SUB)/ym2151/src/calc_delay.vhd
SOURCES += $(SUB)/ym2151/src/calc_output.vhd
SOURCES += $(SUB)/ym2151/src/update_state.vhd
SOURCES += $(SUB)/ym2151/src/ym2151.vhd

# Configure the FPGA on the Nexys4DDR board with the generated bit-file
fpga: build/x16-rom.bit
	djtgcfg prog -d Nexys4DDR -i 0 --file $<

# Create build directory
build:
	mkdir -p build

build/x16-rom.bit: build/x16.bit build/x16.mmi build/rom.mem
	bash -c "source $(XILINX_DIR)/settings64.sh ; updatemem -debug -meminfo build/x16.mmi -data build/rom.mem -proc dummy -bit build/x16.bit -out build/x16-rom.bit -force > build/updatemem.txt"

$(SUB)/x16-rom/build/x16/rom.bin:
	make -C $(SUB)/x16-rom

build/rom.mem: $(SUB)/x16-rom/build/x16/rom.bin
	src/main/bin2hex.py $< build/rom.txt
	echo "@0000" > $@
	cat build/rom.txt >> $@


# Generate the bit-file used to configure the FPGA
build/x16.bit: build/x16.tcl $(SOURCES) src/x16.xdc
	bash -c "source $(XILINX_DIR)/settings64.sh ; vivado -mode tcl -source $<"

# Generate the build script used by Vivado
build/x16.tcl: src/rom.tcl src/debug.tcl src/x16.xdc Makefile
	mkdir -p build
	echo "# This is a tcl command script for the Vivado tool chain" > $@
	echo "read_vhdl -vhdl2008 { $(SOURCES)  }" >> $@
	echo "read_xdc src/x16.xdc" >> $@
	echo "synth_design -top x16 -part xc7a100tcsg324-1 -flatten_hierarchy none" >> $@
	echo "write_checkpoint -force build/post_synth.dcp" >> $@
	echo "source src/debug.tcl" >> $@
	echo "opt_design -directive NoBramPowerOpt" >> $@
	echo "place_design" >> $@
	echo "route_design" >> $@
	echo "write_checkpoint -force build/x16.dcp" >> $@
	echo "source src/rom.tcl" >> $@
	echo "write_bitstream -force build/x16.bit" >> $@
	echo "exit" >> $@

# Remove all generated files
clean:
	make -C $(SUB)/x16-rom clean
	rm -rf build
	rm -rf vivado*
	rm -rf updatemem*
	rm -rf .Xil
	rm -rf usage_statistics_webtalk.*
	rm -rf webtalk.*

