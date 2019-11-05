# Specify install location of the Xilinx Vivado tool
XILINX_DIR = /opt/Xilinx/Vivado/2018.2

# This defines all the source files (VHDL) used in the project
SOURCES  = x16.vhd
SOURCES += clk.vhd
SOURCES += vera/vera.vhd vera/vram.vhd vera/palette.vhd vera/cdc.vhd
SOURCES += vera/cpu/mmu.vhd vera/cpu/cpu.vhd vera/cpu/config.vhd
SOURCES += vera/vga/pix.vhd vera/vga/sync.vhd vera/vga/vga.vhd vera/vga/layer.vhd
SOURCES += main/main.vhd main/ram.vhd main/rom.vhd main/via.vhd
SOURCES += main/cpu_65c02/cpu_65c02.vhd main/cpu_65c02/ctl.vhd main/cpu_65c02/datapath.vhd main/cpu_65c02/microcode.vhd
SOURCES += main/cpu_65c02/alu.vhd main/cpu_65c02/ar.vhd main/cpu_65c02/hi.vhd main/cpu_65c02/lo.vhd
SOURCES += main/cpu_65c02/pc.vhd main/cpu_65c02/sp.vhd main/cpu_65c02/sr.vhd main/cpu_65c02/xr.vhd
SOURCES += main/cpu_65c02/yr.vhd main/cpu_65c02/zp.vhd main/cpu_65c02/mr.vhd

# Configure the FPGA on the Nexys4DDR board with the generated bit-file
fpga: x16.bit
	djtgcfg prog -d Nexys4DDR -i 0 --file $<

# Generate the bit-file used to configure the FPGA
x16.bit: x16.tcl $(SOURCES) x16.xdc Makefile main/rom.txt
	bash -c "source $(XILINX_DIR)/settings64.sh ; vivado -mode tcl -source $<"

# Generate the build script used by Vivado
x16.tcl: Makefile
	echo "# This is a tcl command script for the Vivado tool chain" > $@
	echo "read_vhdl -vhdl2008 { $(SOURCES)  }" >> $@
	echo "read_xdc x16.xdc" >> $@
	echo "set_param synth.elaboration.rodinMoreOptions \"rt::set_parameter max_loop_limit 200000\"" >> $@
	echo "synth_design -top x16 -part xc7a100tcsg324-1 -flatten_hierarchy none" >> $@
	echo "place_design" >> $@
	echo "route_design" >> $@
	echo "write_checkpoint -force x16.dcp" >> $@
	echo "write_bitstream -force x16.bit" >> $@
	echo "exit" >> $@

main/rom.txt:
	make -C main rom.txt

# Remove all generated files
clean:
	make -C main clean
	rm -rf usage_statistics_webtalk.*
	rm -rf vivado*
	rm -rf x16.bit
	rm -rf x16.dcp
	rm -rf x16.tcl
	rm -rf .Xil
	rm -rf .cache
