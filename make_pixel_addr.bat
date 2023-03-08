 vlog ./h264/data_handling/*.sv
 vsim -c -voptargs=+acc tb_pixel_addr -do "run -all"
 