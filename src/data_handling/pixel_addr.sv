module pixel_addr
(
    input logic rst, clk, start,
    output logic [31:0] x_out, y_out
);

    logic stop;

    controller ctrl
	(
		.rst(rst), 
		.clk(clk),
		.start(start), 
		.x(x_out), 
		.y(y_out)
	);

    datapath dp
    (
        .rst(rst), 
        .clk(clk), 
	    .x(x_out), 
        .y(y_out)
        .stop(stop)
    );
    
endmodule