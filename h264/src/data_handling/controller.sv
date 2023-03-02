module controller #
(
	parameter HEIGHT = 352,
	parameter WIDTH = 288
)
(
	input logic rst, clk, 
	input logic stop, start,
	output logic hold
);

	localparam S0 = 2'b00;
	localparam S1 = 2'b01;
	localparam S2 = 2'b10;
	localparam S3 = 2'b11;
	
	logic [1:0] cs, ns;
	
	always_ff@(posedge clk) 
	begin
		if(rst) 
		begin	
			cs <= S0;
		end 
		else 
		begin
			cs <= ns;
		end
	end
	
	//Next State logic
	always_comb 
	begin	
		case(cs)
			S0: 
			begin	
				if (start) 
				begin
					ns = S1;
				end
				else
				begin
					ns = S0;
				end
			end
			S1: 
			begin
				if(stop)
				begin
					ns = S0;
				end
				else
				begin
					ns = S1;
				end
			end
		endcase
	end

	always_comb 
	begin	
		case(cs)
			S0: 
			begin	
				hold = 1;
			end
			S1: 
			begin
				hold = 0;
			end
		endcase
	end
endmodule
	