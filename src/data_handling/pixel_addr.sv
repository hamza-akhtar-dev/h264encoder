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
        .stop(stop),
		.start(start), 
        .hold(hold)
	);

    datapath dp
    (
        .rst(rst), 
        .clk(clk),
        .hold(hold),
	    .x(x_out), 
        .y(y_out),
        .stop(stop)
    );
    
endmodule