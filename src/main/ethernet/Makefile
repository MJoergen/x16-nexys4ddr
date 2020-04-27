XILINX_DIR = /opt/Xilinx/Vivado/2019.2

SUB  = ../../../sub
SRC  = ethernet.vhd
SRC += rx_dma.vhd
SRC += fifo.vhd
SRC += rx_header.vhd
SRC += tx_dma.vhd
SRC += $(SUB)/lan8720a/src/lan8720a.vhd
SRC += $(SUB)/lan8720a/src/rmii_rx.vhd
SRC += $(SUB)/lan8720a/src/rmii_tx.vhd
SRC += $(SUB)/cdc/src/cdc.vhd

TB = ethernet_tb
TB_SRC = $(TB).vhd
WAVE = build/$(TB).ghw
SAVE = $(TB).gtkw


#####################################
# Simulation
#####################################

show: $(WAVE) $(SAVE)
	gtkwave $(WAVE) $(SAVE)

$(WAVE): $(SRC) $(TB_SRC) build
	ghdl -i --ieee=synopsys --std=08 --work=unisim $(XILINX_DIR)/data/vhdl/src/unisims/unisim_VCOMP.vhd
	ghdl -i --ieee=synopsys --std=08 --work=unisim $(XILINX_DIR)/data/vhdl/src/unisims/unisim_VPKG.vhd
	ghdl -i --ieee=synopsys --std=08 --work=unisim $(XILINX_DIR)/data/vhdl/src/unisims/primitive/*.vhd
	ghdl -i --ieee=synopsys --std=08 --work=work $(SRC) $(TB_SRC)
	ghdl -m --ieee=synopsys --std=08 -frelaxed-rules $(TB)
	ghdl -r $(TB) --assert-level=error --wave=$(WAVE) --stop-time=250us

build:
	mkdir -p build

#####################################
# Cleanup
#####################################

clean:
	rm -rf build
	rm -rf *.o
	rm -rf work-obj08.cf
	rm -rf unisim-obj08.cf
	rm -rf $(TB)

