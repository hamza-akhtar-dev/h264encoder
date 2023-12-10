# design under test
DUT = h264topsim

# dut parameters
ifeq ($(DUT), h264topsim)
	SRC_DIR = ./h264/encoder/
endif

all: compile sim

compile:
	vlog $(SRC_DIR)/*.sv

sim:
	vsim -c -voptargs=+acc $(DUT) -do "run -all"

clean:
	rm -rf work transcript *.wlf
