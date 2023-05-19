vlog ./h264/encoder/*.sv
REM vsim -c -voptargs=+acc h264topsim -do "run -all"