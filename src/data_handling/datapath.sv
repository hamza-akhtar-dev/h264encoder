module datapath 
(
	input logic rst, clk, en_x, en_y, incr_x, dcr_x, dcr_y,
	output logic [31:0] x, y
);

	x_counter xcnt
	(
		.rst(rst), 
		.clk(clk), 
		.en_x(en_x), 
		.incr_x(incr_x), 
		.dcr_x(dcr_x), 
		.x(x)
	);

	y_counter ycnt
	(
		.rst(rst), 
		.clk(clk), 
		.en_y(en_y),
		.dcr_y(dcr_y), 
		.y(y)
	);	

endmodule