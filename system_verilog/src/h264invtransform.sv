module h264invtransform
    (
        input logic CLK,             // fast io clock
        input logic ENABLE,          // values input only when this is 1
        input logic [15:0] WIN,      // input (reverse zigzag order)
        output logic VALID,          // values output only when this is 1
        output logic [39:0] XOUT     // 4 x 10bit, first px is lsbs
    );

    // index to the d and f are (y first) as per std d and f
	logic [15:0] d01, d02, d03, d11, d12, d13,	d21, d22, d23, d31, d32, d33, e0, e1, e2, e3, f00, f01, f02, 
                 f03, f10, f11, f12, f13, f20, f21, f22, f23, f30, f31, f32, f33, g0, g1, g2, g3, hx0, hx1,
                 hx2, hx3, d00, d10, d20, d30, h0, h1, h2, h3;
	logic [9:0] h00, h01, h02, h03, h10, h11, h12, h13, h20, h21, h22, h23, h30, h31, h32, h33,  
				xout0, xout1, xout2, xout3;	
	//
	logic [3:0] iww, ixx;

    initial begin
        VALID = 1'd0;
        XOUT = 40'd0;
        d01 = 16'd0; 
        d02 = 16'd0; 
        d03 = 16'd0; 
        d11 = 16'd0; 
        d12 = 16'd0; 
        d13 = 16'd0;
        d21 = 16'd0;
        d22 = 16'd0; 
        d23 = 16'd0; 
        d31 = 16'd0; 
        d32 = 16'd0; 
        d33 = 16'd0; 
        e0 = 16'd0; 
        e1 = 16'd0;
        e2 = 16'd0; 
        e3 = 16'd0; 
        f00 = 16'd0; 
        f01 = 16'd0; 
        f02 = 16'd0; 
        f03 = 16'd0; 
        f10 = 16'd0; 
        f11 = 16'd0; 
        f12 = 16'd0; 
        f13 = 16'd0; 
        f20 = 16'd0; 
        f21 = 16'd0; 
        f22 = 16'd0; 
        f23 = 16'd0; 
        f30 = 16'd0; 
        f31 = 16'd0; 
        f32 = 16'd0; 
        f33 = 16'd0; 
        g0 = 16'd0; 
        g1 = 16'd0; 
        g2 = 16'd0; 
        g3 = 16'd0; 
        hx0 = 16'd0; 
        hx1 = 16'd0;
        hx2 = 16'd0; 
        hx3 = 16'd0;
        d00 = 16'd0; 
        d10 = 16'd0; 
        d20 = 16'd0; 
        d30 = 16'd0; 
        h0 = 16'd0; 
        h1 = 16'd0; 
        h2 = 16'd0; 
        h3 = 16'd0;
        h00 = 10'd0; 
        h01 = 10'd0;
        h02 = 10'd0;
        h03 = 10'd0; 
        h10 = 10'd0; 
        h11 = 10'd0; 
        h12 = 10'd0; 
        h13 = 10'd0; 
        h20 = 10'd0; 
        h21 = 10'd0; 
        h22 = 10'd0; 
        h23 = 10'd0; 
        h30 = 10'd0; 
        h31 = 10'd0; 
        h32 = 10'd0; 
        h33 = 10'd0;
		iww = 4'd0;
		ixx = 4'd0;
    end

    always@(posedge CLK) begin
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
			d30 <= WIN;	// ROW3&COL0
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
			d20 <= WIN;	// ROW2&COL0 
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
			d10 <= WIN;	// ROW1&COL0
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
			d00 <= WIN;	// ROW0&COL0
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
			h0 <= (g0 + g3) + 32;	// 32 is rounding factor
			h1 <= (g1 + g2) + 32;
			h2 <= (g1 - g2) + 32;
			h3 <= (g0 - g3) + 32;
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
			h0 <= (g0 + g3) + 32;	// 32 is rounding factor
			h1 <= (g1 + g2) + 32;
			h2 <= (g1 - g2) + 32;
			h3 <= (g0 - g3) + 32;
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
			h0 <= (g0 + g3) + 32;	// 32 is rounding factor
			h1 <= (g1 + g2) + 32;
			h2 <= (g1 - g2) + 32;
			h3 <= (g0 - g3) + 32;
			h03 <= h0[15:6];
			h13 <= h1[15:6];
			h23 <= h2[15:6];
			h33 <= h3[15:6];
			VALID <= 1;
			xout0 <= h00;
			xout1 <= h01;
			xout2 <= h02;
			xout3 <= h03;
        end
		else if (ixx == 7) begin
			xout0 <= h10;
			xout1 <= h11;
			xout2 <= h12;
			xout3 <= h13;
        end
		else if (ixx == 8) begin
			xout0 <= h20;
			xout1 <= h21;
			xout2 <= h22;
			xout3 <= h23;
        end
		else if (ixx == 9) begin
			xout0 <= h30;
			xout1 <= h31;
			xout2 <= h32;
			xout3 <= h33;
        end
		else if (ixx == 10) begin
			VALID <= 0;
		end
		hx0 <= h0; // DEBUG
		hx1 <= h1;
		hx2 <= h2;
		hx3 <= h3;
		XOUT[9:0] <= xout0;
		XOUT[19:10] <= xout1;
		XOUT[29:20] <= xout2;
		XOUT[39:30] <= xout3;
    end

endmodule