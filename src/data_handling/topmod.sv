module topmod (input logic clk, reset, start);

logic stop, x_16, y_16;
logic [1:0] x_count, y_count;
datpath dp(clk, reset, x_count,y_count,
		stop, x_16, y_16);
		
controller ctrl(clk, reset, start, stop, x_16, y_16,
           x_count, y_count);

endmodule