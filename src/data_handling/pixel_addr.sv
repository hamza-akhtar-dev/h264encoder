module pixel_addr
(
    input logic rst, clk, start,
    output logic [31:0] x_out, y_out
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

    datapath dp
    (
        .rst(rst), 
        .clk(clk), 
        .en_x(en_x), 
		.en_y(en_y), 
		.dcr_x(dcr_x), 
		.incr_x(incr_x), 
		.dcr_y(dcr_y),
	    .x(x), 
        .y(y)
    );

    assign x_out = x;
    assign y_out = y;
    
endmodule