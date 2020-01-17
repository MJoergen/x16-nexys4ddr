XILINX_DIR = /opt/Xilinx/Vivado/2019.2

SRC  = ym2151.vhd
TB = ym2151_tb
TB_SRC = $(TB).vhd
WAVE = $(TB).ghw
SAVE = $(TB).gtkw


#####################################
# Simulation
#####################################

sim: $(SRC) 
	ghdl -i --ieee=synopsys --std=08 --work=work $(SRC) $(TB_SRC)
	ghdl -m --ieee=synopsys --std=08 -frelaxed-rules $(TB)
	ghdl -r $(TB) --assert-level=error --wave=$(WAVE) --stop-time=400us
	gtkwave $(WAVE) $(SAVE)


#####################################
# Cleanup
#####################################

clean:
	rm -rf *.o
	rm -rf work-obj08.cf
	rm -rf $(TB)
	rm -rf $(WAVE)

