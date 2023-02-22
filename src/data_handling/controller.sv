module controller #
(
	parameter HEIGHT = 352,
	parameter WIDTH = 288
)
(
	input logic rst, clk, start, 
	input logic [31:0] x, y,
	output logic en_x, incr_x, dcr_x, en_y, dcr_y
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
				if(x % 16 == 0)
				begin
					en_x = 0;
					dcr_x = 1;
					en_y = 1;
				end
				else if(x % 16 != 0)
				begin
					en_x = 1;
					dcr_x = 0;
					en_y = 0;
				end
				else if(y % 16 == 0)
				begin
					dcr_y = 1;

				end
				else 
				begin
					dcr_y = 1;
				end
			end
		endcase
	end
endmodule
	