module stg #(HEIGHT=288, WIDTH=352)(input logic clk, reset,start);

	localparam S0 = 2'b00;
	localparam S1 = 2'b01;
	localparam S2 = 2'b10;
	localparam S3 = 2'b11;
	
	logic [1:0] cs, ns ;
	integer x=0, y=0, counter;
	
	always_ff@(posedge clk) begin
		if(reset) begin	
			cs <= S0;
		end 
		else begin
			cs <= ns;
		end
	end
	
	//Next State logic
	always_comb begin	
		case(cs)
		S0: begin	
			if (start) begin
				ns = S1; 
			end
		end
		S1: begin
			x = x + 4;
			if ( x%16 != 0 ) begin
				ns = S1;
			end	
			else if ( x%16 == 0 ) begin
				ns = S2;
			end
			else if ( x == WIDTH && y == HEIGHT ) begin
				ns = S0;
			end
		end
		S2: begin
			x = x - 16;
			y = y + 1;
			if ( y%16 == 0 ) begin
				ns = S3;
			end
			else begin
				ns = S1;
			end
		end
		S3: begin
			x = x + 16;
			y = y - 16;
			ns = S1;
		end
		endcase
	end
endmodule
	