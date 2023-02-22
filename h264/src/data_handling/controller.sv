module controller(input logic clk, reset, start, stop, x_16, y_16,
output logic [1:0] x_count=2'b01, y_count=2'b01);

	localparam S0 = 2'b00;
	localparam S1 = 2'b01;
	localparam S2 = 2'b10;
	localparam S3 = 2'b11;
	
	logic [1:0] cs, ns ;
	
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
				x_count = 2'b10;
			end
		end
		S1: begin
			x_count = 2'b10;
			if ( !x_16 ) begin
				ns = S1;
			end	
			else if ( x_16 ) begin
				ns = S2;
			end
			else if ( stop ) begin
				ns = S0;
			end
		end
		S2: begin
			x_count = 2'b00;
			y_count = 2'b11;
			if ( y_16 ) begin
				ns = S3;
			end
			else begin
				ns = S1;
			end
		end
		S3: begin
			x_count = 2'b11;
			y_count = 2'b00;
			ns = S1;
		end
		endcase
	end
endmodule
	