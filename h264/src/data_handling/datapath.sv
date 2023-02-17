module datpath #( WIDTH= 352, HEIGHT = 288)(input logic clk, reset,
			   input logic [1:0] x_count, 
			   input logic y_count,
			   output logic stop, x_16, y_16);

	
integer x=0, y=0;
always_ff@(posedge clk) begin
	if (reset) begin
		x=0; y=0;
	end
	else begin
		
		// When to stop
		if ( x == WIDTH && y == HEIGHT ) begin
			stop = 1'b1;
		end
		
		// Y-Counter
		if (y_count == 1'b0) begin
			y = y - 16;
		end
		else begin
			y = y + 1;
		end
		
		// X-Counter
		if (x_count == 2'b00) begin
			x = x - 16;
		end
		else if (x_count == 2'b10) begin
			x = x + 4;
		end
		else if (x_count == 2'b11) begin
			x = x + 16;
		end
		
		//
		if (x%16 == 0) begin
			x_16 = 1'b1;
		end
		else begin
			x_16 = 1'b0;
		end
		
		//
		if (y%16 == 0) begin
			y_16 = 1'b1;
		end
		else begin
			y_16 = 1'b0;
		end
	end	
end
endmodule