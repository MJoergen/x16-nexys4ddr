# Specify install location of the Xilinx Vivado tool
XILINX_DIR = /opt/Xilinx/Vivado/2018.2

# This defines all the source files (VHDL) used in the project
SOURCES  = x16.vhd
SOURCES += clk.vhd
SOURCES += vera/vera.vhd vera/vram.vhd vera/palette.vhd vera/cdc.vhd vera/pulse_conv.vhd
SOURCES += vera/cpu/mmu.vhd vera/cpu/cpu.vhd vera/cpu/config.vhd
SOURCES += vera/cpu/spi.vhd vera/cpu/spi_master.vhd
SOURCES += vera/vga/pix.vhd vera/vga/sync.vhd vera/vga/vga.vhd vera/vga/layer.vhd
SOURCES += main/main.vhd main/ram.vhd main/rom.vhd main/via.vhd
SOURCES += main/ps2/ps2_buffer.vhd main/ps2/ps2_reader.vhd main/ps2/ps2_writer.vhd
SOURCES += main/cpu_65c02/cpu_65c02.vhd main/cpu_65c02/ctl.vhd main/cpu_65c02/datapath.vhd main/cpu_65c02/microcode.vhd
SOURCES += main/cpu_65c02/alu.vhd main/cpu_65c02/ar.vhd main/cpu_65c02/hi.vhd main/cpu_65c02/lo.vhd
SOURCES += main/cpu_65c02/pc.vhd main/cpu_65c02/sp.vhd main/cpu_65c02/sr.vhd main/cpu_65c02/xr.vhd
SOURCES += main/cpu_65c02/yr.vhd main/cpu_65c02/zp.vhd main/cpu_65c02/mr.vhd

# Configure the FPGA on the Nexys4DDR board with the generated bit-file
fpga: x16-rom.bit
	djtgcfg prog -d Nexys4DDR -i 0 --file $<

x16-rom.bit: x16.bit x16.mmi rom.mem
	bash -c "source $(XILINX_DIR)/settings64.sh ; updatemem -debug -meminfo x16.mmi -data rom.mem -proc dummy -bit x16.bit -out x16-rom.bit -force > updatemem.txt"

rom.mem: main/rom.txt
	echo "@0000" > $@
	cat $< >> $@

# Generate the bit-file used to configure the FPGA
x16.bit: x16.tcl $(SOURCES) x16.xdc
	bash -c "source $(XILINX_DIR)/settings64.sh ; vivado -mode tcl -source $<"

# Generate the build script used by Vivado
x16.tcl: rom.tcl
	echo "# This is a tcl command script for the Vivado tool chain" > $@
	echo "read_vhdl -vhdl2008 { $(SOURCES)  }" >> $@
	echo "read_xdc x16.xdc" >> $@
	echo "set_param synth.elaboration.rodinMoreOptions \"rt::set_parameter max_loop_limit 200000\"" >> $@
	echo "synth_design -top x16 -part xc7a100tcsg324-1 -flatten_hierarchy none" >> $@
	echo "source debug.tcl" >> $@
	echo "opt_design -directive NoBramPowerOpt" >> $@
	echo "write_debug_probes -force x16.ltx" >> $@
	echo "place_design" >> $@
	echo "route_design" >> $@
	echo "write_checkpoint -force x16.dcp" >> $@
	echo "source rom.tcl" >> $@
	echo "write_bitstream -force x16.bit" >> $@
	echo "exit" >> $@

main/rom.txt:
	make -C main rom.txt

# Remove all generated files
clean:
	make -C main clean
	rm -rf usage_statistics_webtalk.*
	rm -rf vivado*
	rm -rf updatemem*
	rm -rf x16-rom.bit
	rm -rf x16.bit
	rm -rf x16.dcp
	rm -rf x16.tcl
	rm -rf .Xil
	rm -rf .cache
	rm -rf rom.mem
	rm -rf x16.mmi
	rm -rf x16.ltx
