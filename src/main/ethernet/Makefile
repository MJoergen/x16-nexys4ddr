XILINX_DIR = /opt/Xilinx/Vivado/2019.2

SRC  = ethernet.vhd rx_dma.vhd fifo.vhd rx_header.vhd tx_dma.vhd \
       lan8720a/lan8720a.vhd lan8720a/rmii_rx.vhd lan8720a/rmii_tx.vhd \
       ../../cdc.vhd
TB = ethernet_tb.vhd
WAVE = ethernet_tb.ghw
SAVE = ethernet_tb.gtkw


#####################################
# Simulation
#####################################

sim: $(SRC) 
	ghdl -i --ieee=synopsys --std=08 --work=unisim $(XILINX_DIR)/data/vhdl/src/unisims/unisim_VCOMP.vhd
	ghdl -i --ieee=synopsys --std=08 --work=unisim $(XILINX_DIR)/data/vhdl/src/unisims/unisim_VPKG.vhd
	ghdl -i --ieee=synopsys --std=08 --work=unisim $(XILINX_DIR)/data/vhdl/src/unisims/primitive/*.vhd
	ghdl -i --ieee=synopsys --std=08 --work=work $(SRC) $(TB)
	ghdl -m --ieee=synopsys --std=08 -frelaxed-rules ethernet_tb
	ghdl -r ethernet_tb --assert-level=error --wave=$(WAVE) --stop-time=250us
	gtkwave $(WAVE) $(SAVE)


#####################################
# Cleanup
#####################################

clean:
	rm -rf usage_statistics_webtalk.*
	rm -rf vivado*
	rm -rf *.o
	rm -rf comp.dcp
	rm -rf .Xil
	rm -rf .cache
	rm -rf work-obj08.cf
	rm -rf unisim-obj08.cf
	rm -rf ethernet_tb
	rm -rf ethernet_tb.ghw

