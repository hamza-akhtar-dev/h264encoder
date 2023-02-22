module datapath 
(
	input logic rst, clk, start,
	output logic [31:0] x, y
);

	logic en_x, incr_x, dcr_x, en_y, dcr_y;

	controller ctrl
	(
		.rst(rst), 
		.clk(clk), 
		.start(start), 
		.x(x), 
		.y(y),
		.en_x(en_x), 
		.en_y(en_y), 
		.dcr_x(dcr_x), 
		.incr_x(incr_x), 
		.dcr_y(dcr_y)
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