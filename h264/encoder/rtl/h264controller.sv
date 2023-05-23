module h264controller #
(
	parameter IMGHEIGHT = 352,
	parameter IMGWIDTH  = 288
)
(
	input  logic rst,
	input  logic clk, 
	input  logic clk2, 

	input  logic start,

	input  logic xbuffer_DONE, 

	input  logic intra4x4_READYI,   
	input  logic intra8x8cc_READYI, 

	input  logic tobytes_STROBE, 
	input  logic tobytes_DONE,

	output logic newslice,       
	output logic newline,     

	output logic intra4x4_STROBEI,
	output logic intra8x8cc_STROBEI,

	output logic align_VALID,

	output logic [31:0] x,
	output logic [31:0] y,
	output logic [31:0] cx,
	output logic [31:0] cy,
	output logic        cuv
);

	localparam S0 = 6'b000000;
	localparam S1 = 6'b000001;
	localparam S2 = 6'b000010;
	localparam S3 = 6'b000011;
	localparam S4 = 6'b000100;
	localparam S5 = 6'b000101;
	localparam S6 = 6'b000110;
	localparam S7 = 6'b000111;
	localparam S8 = 6'b001000;
	localparam S9 = 6'b001001;
	localparam S10 = 6'b001010;
	localparam S11 = 6'b001011;
	localparam S12 = 6'b001100;
	localparam S13 = 6'b001101;
	localparam S14 = 6'b001110;
	localparam S15 = 6'b001111;
	localparam S16 = 6'b010000;
	localparam S17 = 6'b010001;
	localparam S18 = 6'b010010;
	localparam S19 = 6'b010011;
	localparam S20 = 6'b010100;
	localparam S21 = 6'b010101;
	localparam S22 = 6'b010110;
	localparam S23 = 6'b010111;
	localparam S24 = 6'b011000;
	localparam S25 = 6'b011001;
	localparam S26 = 6'b011010;
	localparam S27 = 6'b011011;
	localparam S28 = 6'b011100;
	localparam S29 = 6'b011101;
	localparam S30 = 6'b011110;


	logic [5:0] cs, ns;

	logic [31:0] w;
	
	always_ff @(posedge clk2) 
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
				if ( start )
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
				if ( (y < IMGHEIGHT) || (cy < IMGHEIGHT/2) )
				begin
					if ( intra4x4_READYI && (y < IMGHEIGHT) )
					begin
						ns = S2;
					end
				end
			end

			S2: ns = S3;
			S3: ns = S4;
			S4: ns = S5;
			S5: ns = S6;
			S6: ns = S7;
			S7: ns = S8;
			S8: ns = S9;
			S9: ns = S10;

			S10: 
			begin
				if ((y % 16) == 0 )
				begin		
                    if (x == IMGWIDTH)
                    begin
						if ( !xbuffer_DONE )
						begin
							ns = S20;
						end
						else
						begin
							if( intra8x8cc_READYI && (cy < IMGHEIGHT/2) )
							begin
								ns = S11;
							end
						end
					end
					else
					begin
						ns = S11;
					end
				end
				else
				begin
					ns = S11;
				end
			end

			S11: ns = S12;
			S12: ns = S13;
			S13: ns = S14;
			S14: ns = S15;
			S15: ns = S16;
			S16: ns = S17;
			S17: ns = S18;
			S18: ns = S19;
		
			S19:
			begin
				ns = S1;
			end

			S20:  // Wait Line
			begin
				if ( xbuffer_DONE )
				begin
					ns = S10;
				end
				else
				begin
					ns = S21;
				end
			end

			S21:  // Wait Frame
			begin
				if ( xbuffer_DONE )
				begin
					ns = S22;
				end
				else
				begin
					ns = S21;
				end
			end

			S22:
			begin
				if( w == 32 )
				begin
					ns = S23;
				end
				else
				begin
					ns = S22;
				end
			end

			S23: ns = S24;
			S24: ns = S25;

			S25:
			begin
				if( tobytes_DONE )
				begin
					ns = S26;
				end
				else
				begin
					ns = S25;
				end
			end

			S26: ns = S27;

			S27: 
			begin
				ns = S0;
			end

		endcase
	end

	always_comb 
	begin	
		case(cs)
			S0: 
			begin
				newline  = 1;
				newslice = 1;
				x = 0;
				y = 0;
				cx = 0;
				cy = 0;
				w  = 0;
				cuv = 0;
			end
			S1: 
			begin
				if( newline )
				begin
					cx = 0;
                    cy = cy - (cy % 8);
                    cuv = 0;
				end
			end
			S2: 
			begin
				intra4x4_STROBEI   = 1;
                newline            = 0;
                newslice           = 0;
			end
			S3:
			begin
				x = x + 4;
			end
			S4:
			begin
				x = x + 4;
			end
			S5:
			begin
				x = x + 4;
			end
			S6:
			begin
				x = x + 4;
				x = x - 16;	
                y = y + 1;
			end
			S7:
			begin
				x = x + 4;
			end
			S8:
			begin
				x = x + 4;
			end
			S9:
			begin
				x = x + 4;
			end
			S10:
			begin
				x = x + 4;
				x = x - 16;	
				y = y + 1;
				intra4x4_STROBEI = 0;
				if ( (y % 16) == 0 )
				begin
					x = x + 16;
                    y = y - 16;			
                    if (x == IMGWIDTH)
                    begin
                        x = 0;			
                        y = y + 16;
						if(xbuffer_DONE)
						begin
							newline = 1;
							$display("Newline pulsed Line: %2d Progress: %2d%%", y, y*100/IMGHEIGHT);
						end
					end
				end
			end
			S11:
			begin 
				intra8x8cc_STROBEI = 1;
			end
			S12: 
			begin 
				cx = cx + 4;
			end
			S13:
			begin
				cx = cx + 4;
				cx = cx - 8;
				cy = cy + 1;
			end
			S14: 
			begin 
				cx = cx + 4;
			end
			S15:
			begin
				cx = cx + 4;
				cx = cx - 8;
				cy = cy + 1;
			end
			S16: 
			begin 
				cx = cx + 4;
			end
			S17:
			begin
				cx = cx + 4;
				cx = cx - 8;
				cy = cy + 1;
			end
			S18: 
			begin 
				cx = cx + 4;
			end
			S19:
			begin
				cx = cx + 4;
				cx = cx - 8;
				cy = cy + 1;
				intra8x8cc_STROBEI = 0;
				if ( (cy % 8) == 0 ) 
                begin
                    if (cuv == 0) 
                    begin
                        cy = cy - 8;
                        cuv = 1;
					end
					else
					begin
						cuv = 0;
						cy = cy - 8;
						cx = cx + 8;
						if ( cx == IMGWIDTH/2 )
						begin
							cx = 0;	
							cy = cy + 8;
						end
					end
                end
			end
			S20:
			begin end
			S21:
			begin 
				$display("Done push of data into intra4x4 and intra8x8cc");
			end
			S22:
			begin
				w = w + 1;
			end
			S23:
			begin 
				align_VALID = 1;
			end
			S24:
			begin 
				align_VALID = 0;
			end
			S25:
			begin end
		endcase
	end

endmodule