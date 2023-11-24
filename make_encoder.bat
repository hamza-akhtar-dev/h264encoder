vlog ./h264/encoder/*.sv
vsim -c -voptargs=+acc h264topsim -do "run -all"