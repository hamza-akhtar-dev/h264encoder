# design under test
DUT = h264topsim

# dut parameters
ifeq ($(DUT), h264topsim)
	SRC_DIR = ./h264/encoder/
endif

all: compile sim
simulation: compile wave

compile:
	vlog $(SRC_DIR)/*.sv

sim:
	vsim -c -voptargs=+acc $(DUT) -do "run -all"

wave:
	vsim -L -voptargs=+acc $(DUT) -do "add wave sim:/$(DUT)/intra4x4/* ;run -all"

clean:
	rm -rf work transcript *.wlf
