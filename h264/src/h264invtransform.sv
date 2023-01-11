module h264invtransform
(
	input logic CLK,             // fast io clock
	input logic ENABLE,          // values input only when this is 1
	input logic [15:0] WIN,      // input (reverse zigzag order)
	output logic VALID = '0,          // values output only when this is 1
	output logic [39:0] XOUT = '0     // 4 x 10bit, first px is lsbs
);

    // index to the d and f are (y first) as per std d and f
	logic [15:0] d01 = '0; 
	logic [15:0] d02 = '0; 
	logic [15:0] d03 = '0; 
	logic [15:0] d11 = '0; 
	logic [15:0] d12 = '0; 
	logic [15:0] d13 = '0; 
	logic [15:0] d21 = '0; 
	logic [15:0] d22 = '0; 
	logic [15:0] d23 = '0; 
	logic [15:0] d31 = '0; 
	logic [15:0] d32 = '0; 
	logic [15:0] d33 = '0; 
	logic [15:0] e0 = '0; 
	logic [15:0] e1 = '0; 
	logic [15:0] e2 = '0; 
	logic [15:0] e3 = '0; 
	logic [15:0] f00 = '0; 
	logic [15:0] f01 = '0; 
	logic [15:0] f02 = '0; 
	logic [15:0] f03 = '0; 
	logic [15:0] f10 = '0; 
	logic [15:0] f11 = '0; 
	logic [15:0] f12 = '0; 
	logic [15:0] f13 = '0; 
	logic [15:0] f20 = '0; 
	logic [15:0] f21 = '0; 
	logic [15:0] f22 = '0; 
	logic [15:0] f23 = '0; 
	logic [15:0] f30 = '0; 
	logic [15:0] f31 = '0; 
	logic [15:0] f32 = '0; 
	logic [15:0] f33 = '0; 
	logic [15:0] g0 = '0;
	logic [15:0] g1 = '0; 
	logic [15:0] g2 = '0; 
	logic [15:0] g3 = '0; 

	logic [9:0] h00 = '0;
	logic [9:0] h01 = '0; 
	logic [9:0] h02 = '0; 
	logic [9:0] h10 = '0; 
	logic [9:0] h11 = '0; 
	logic [9:0] h12 = '0; 
	logic [9:0] h13 = '0; 
	logic [9:0] h20 = '0; 
	logic [9:0] h21 = '0; 
	logic [9:0] h22 = '0; 
	logic [9:0] h23 = '0; 
	logic [9:0] h30 = '0; 
	logic [9:0] h31 = '0; 
	logic [9:0] h32 = '0; 
	logic [9:0] h33 = '0; 

	logic [15:0] hx0 = '0; 
	logic [15:0] hx1 = '0;
	logic [15:0] hx2 = '0; 
	logic [15:0] hx3 = '0;  
	
	logic [3:0] iww = '0;
	logic [3:0] ixx = '0;

	logic [15:0] d00, d10, d20, d30, h0, h1, h2, h3;
	logic [9:0] h03;
			
    always@(posedge CLK) 
	begin
        if (ENABLE == 1 || iww != 0) 
			iww <= iww + 1;
		if (iww == 15 || ixx != 0) 
			ixx <= ixx + 1;

		// input: in reverse zigzag order
		if (iww == 0) 
			d33 <= WIN;	// ROW3&COL3;
		else if (iww == 1) 
			d32 <= WIN;	// ROW3&COL2 
		else if (iww == 2) 
			d23 <= WIN;	// ROW2&COL3
		else if (iww == 3)
			d13 <= WIN;	// ROW1&COL3
		else if (iww == 4) 
			d22 <= WIN;	// ROW2&COL2
		else if (iww == 5) 
			d31 <= WIN;	// ROW3&COL1 
		else if (iww == 6) begin
			d30 = WIN;	// ROW3&COL0
			e0 <= d30 + d32;	// process ROW3
			e1 <= d30 - d32;
			e2 <= {d31[15], d31[15:1]} - d33;
			e3 <= d31 + {d33[15], d33[15:1]};
        end
		else if (iww == 7) begin
			f30 <= e0 + e3;
			f31 <= e1 + e2;
			f32 <= e1 - e2;
			f33 <= e0 - e3;
			d21 <= WIN;	// ROW2&COL1
        end 
		else if (iww == 8) 
			d12 <= WIN;	// ROW1&COL2
		else if (iww == 9) 
			d03 <= WIN;	// ROW0&COL3
		else if (iww == 10) 
			d02 <= WIN;	// ROW0&COL2
		else if (iww == 11) 
			d11 <= WIN;	// ROW1&COL1 
		else if (iww == 12) begin
			d20 = WIN;	// ROW2&COL0 
			e0 <= d20 + d22;	// process ROW2
			e1 <= d20 - d22;
			e2 <= {d21[15], d21[15:1]} - d23;
			e3 <= d21 + {d23[15], d23[15:1]};
        end
		else if (iww == 13) begin
			f20 <= e0 + e3;
			f21 <= e1 + e2;
			f22 <= e1 - e2;
			f23 <= e0 - e3;
			d10 = WIN;	// ROW1&COL0
			e0 <= d10 + d12;	// process ROW1
			e1 <= d10 - d12;
			e2 <= {d11[15], d11[15:1]} - d13;
			e3 <= d11 + {d13[15], d13[15:1]};
        end
		else if (iww == 14) begin
			f10 <= e0 + e3;
			f11 <= e1 + e2;
			f12 <= e1 - e2;
			f13 <= e0 - e3;
			d01 <= WIN;	// ROW0&COL1
        end
		else if (iww == 15) begin
			d00 = WIN;	// ROW0&COL0
			e0 <= d00 + d02;	// process ROW1
			e1 <= d00 - d02;
			e2 <= {d01[15], d01[15:1]} - d03;
			e3 <= d01 + {d03[15], d03[15:1]};
		end

		// output stages (immediately after input stage 15)
		if (ixx == 1) begin
			f00 <= e0 + e3;	// complete input stage
			f01 <= e1 + e2;
			f02 <= e1 - e2;
			f03 <= e0 - e3;
        end
		else if (ixx == 2) begin
			g0 <= f00 + f20;		// col 0
			g1 <= f00 - f20;
			g2 <= {f10[15], f10[15:1]} - f30;
			g3 <= f10 + {f30[15], f30[15:1]};
        end
		else if (ixx == 3) begin
			h0 = (g0 + g3) + 32;	// 32 is rounding factor
			h1 = (g1 + g2) + 32;
			h2 = (g1 - g2) + 32;
			h3 = (g0 - g3) + 32;
			h00 <= h0[15:6];
			h10 <= h1[15:6];
			h20 <= h2[15:6];
			h30 <= h3[15:6];
			// VALID <= '1';
			g0 <= f01 + f21;		// col 1
			g1 <= f01 - f21;
			g2 <= {f11[15], f11[15:1]} - f31;
			g3 <= f11 + {f31[15], f31[15:1]};
        end
			// XOUT <= (see above)
		else if (ixx == 4) begin
			h0 = (g0 + g3) + 32;	// 32 is rounding factor
			h1 = (g1 + g2) + 32;
			h2 = (g1 - g2) + 32;
			h3 = (g0 - g3) + 32;
			h01 <= h0[15:6];
			h11 <= h1[15:6];
			h21 <= h2[15:6];
			h31 <= h3[15:6];
			g0 <= f02 + f22;		// col 2
			g1 <= f02 - f22;
			g2 <= {f12[15], f12[15:1]} - f32;
			g3 <= f12 + {f32[15], f32[15:1]};
        end
		else if (ixx == 5) begin
			h0 = (g0 + g3) + 32;	// 32 is rounding factor
			h1 = (g1 + g2) + 32;
			h2 = (g1 - g2) + 32;
			h3 = (g0 - g3) + 32;
			h02 <= h0[15:6];
			h12 <= h1[15:6];
			h22 <= h2[15:6];
			h32 <= h3[15:6];
			g0 <= f03 + f23;		// col 3
			g1 <= f03 - f23;
			g2 <= {f13[15], f13[15:1]} - f33;
			g3 <= f13 + {f33[15], f33[15:1]};
        end
		else if (ixx == 6) begin
			h0 = (g0 + g3) + 32;	// 32 is rounding factor
			h1 = (g1 + g2) + 32;
			h2 = (g1 - g2) + 32;
			h3 = (g0 - g3) + 32;
			h03 = h0[15:6];
			h13 <= h1[15:6];
			h23 <= h2[15:6];
			h33 <= h3[15:6];
			VALID <= 1;
			XOUT[9:0] <= h00;
			XOUT[19:10] <= h01;
			XOUT[29:20] <= h02;
			XOUT[39:30] <= h03;
        end
		else if (ixx == 7) begin
			XOUT[9:0] <= h10;
			XOUT[19:10] <= h11;
			XOUT[29:20] <= h12;
			XOUT[39:30] <= h13;
        end
		else if (ixx == 8) begin
			XOUT[9:0] <= h20;
			XOUT[19:10] <= h21;
			XOUT[29:20] <= h22;
			XOUT[39:30] <= h23;
        end
		else if (ixx == 9) begin
			XOUT[9:0] <= h30;
			XOUT[19:10] <= h31;
			XOUT[29:20] <= h32;
			XOUT[39:30] <= h33;
        end
		else if (ixx == 10) begin
			VALID <= 0;
		end
		hx0 <= h0; // DEBUG
		hx1 <= h1;
		hx2 <= h2;
		hx3 <= h3;
    end

endmodule