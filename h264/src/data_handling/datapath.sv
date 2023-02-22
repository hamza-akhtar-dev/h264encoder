module datpath #( WIDTH= 352, HEIGHT = 288)(input logic clk, reset,
			   input logic [1:0] x_count, y_count,
			   output logic stop=0, x_16=0, y_16=0);

	
integer x=0, y=0;
always_ff@(posedge clk) begin
	if (reset) begin
		x=0; y=0;
	end
	else begin
		
		// Y-Counter
		if (y_count == 2'b00) begin
			y = y - 16;
		end
		else if (y_count == 2'b11) begin
			y = y + 1;
		end
		else begin
			y = y;
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
		else begin
			x = x;
		end
		
	end	
end

always_comb begin 
		// When to stop
		if ( x == WIDTH && y == HEIGHT ) begin
			stop = 1'b1;
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
endmodule