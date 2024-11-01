# design under test
DUT = h264intra4x4_tb

# dut parameters
ifeq ($(DUT), h264intra4x4_tb)
	SRC_DIR = ./
endif

all: compile sim
simulation: compile wave

compile:
	vlog $(SRC_DIR)/*.sv

sim:
	vsim -c -voptargs=+acc $(DUT) -do "run -all"

wave:
	vsim -L -voptargs=+acc $(DUT) -do "add wave sim:/$(DUT)/UUT/* ;run -all"

clean:
	rm -rf work transcript *.wlf
