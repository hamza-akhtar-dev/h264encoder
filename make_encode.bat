vlog ./h264/main_code/*.sv
vsim -c -voptargs=+acc h264topsim -do "run -all"