module h264intra8x8cc 
(
    input logic CLK2,
    input logic NEWSLICE,
    input logic NEWLINE, 
    input logic STROBEI, 
    input logic FBSTROBE,
    input logic READYO,
    input logic [7:0] FEEDBI, 
    input logic [31:0] DATAI, 
    input logic [31:0] TOPI,
    
    output logic STROBEO = 1'b0,
    output logic DCSTROBEO = 1'b0,
    output logic READYI = 1'b0,
    output logic XXC = 1'b0,
    output logic XXINC = 1'b0,
    output logic [1:0] XXO = 2'd0,
    output logic [1:0] CMODEO = 2'd0,
    output logic [15:0] DCDATAO = 16'd0,
    output logic [31:0] BASEO = 32'd0,
    output logic [35:0] DATAO = 36'd0
);
	logic [31:0] pix [31:0] = '{default: '0};	//macroblock data; first half is Cb, then Cr
	logic [7:0] pixleft [15:0] = '{default: '0};		//previous col, first half is Cb, then Cr
	logic lvalid = 1'b0;					//set if pixels on left are valid
	logic tvalid = 1'b0;					//set if TOP valid (not first line)
	logic [31:0] topil = 32'd0;
	logic [31:0] topir = 32'd0;
	logic [31:0] topii = 32'd0;
	//input states
	logic [4:0] istate = 5'd0;	//which input word
	//processing states	
	logic crcb = 1'b0;			//which of cr/cb
	logic [1:0] quad = 2'd0;	//which of 4 blocks
	localparam  IDLE = 4'd0;
	logic [3:0] state = IDLE;	//state/row for processing
	//output state
	logic [1:0] oquad = 2'd0;	//which of 4 blocks output
	logic [1:0] fquad = 2'd0;	//which of 4 blocks for feedback
	logic ddc1  = 1'b0;						//output flag dc
	logic ddc2  = 1'b0;						//output flag dc
	logic fbpending = 1'b0;					//wait for feedback
	logic [3:0] fbptr = 4'd0;
	//type out
	//logic cmodeoi = 2'd0;	//always DC=0 this version
	logic [31:0] dat0 = 32'd0;
	//diffs for mode 2 dc
	logic [1:0] lindex = 2'd0;
	logic [7:0] left0 = 8'd0;
	logic [7:0] left1 = 8'd0;
	logic [7:0] left2 = 8'd0;
	logic [7:0] left3 = 8'd0;
	logic [8:0] ddif0 = 9'd0;
	logic [8:0] ddif1 = 9'd0;
	logic [8:0] ddif2 = 9'd0;
	logic [8:0] ddif3 = 9'd0;
	logic [12:0] dtot = 13'd0;
	//averages for mode 2 dc
	logic [9:0] sumt = 10'd0;
	logic [9:0] suml = 10'd0;
	logic [10:0] sumtl = 11'd0;

	always_comb begin 
		// 
		XXO = {crcb, fquad[0]};
		XXINC = (state == 4'd15 && crcb == 1'b1) ? 1'b1 : 1'b0;
		READYI = (state == 4'd0 || istate[4] != crcb) ? 1'b1 : 1'b0;
		DCDATAO = {{3{dtot[12]}}, dtot}; //16bit
		//
		topii = (quad[0] == 1'b0)? topil : topir;
		lindex = {crcb, quad[1]};
		left0 = pixleft[{1'b0, lindex, 2'b00}];
		left1 = pixleft[{1'b0, lindex, 2'b01}];
		left2 = pixleft[{1'b0, lindex, 2'b10}];
		left3 = pixleft[{1'b0, lindex, 2'b11}];
		//
		//CMODEO = cmodeoi;	//always 00
		//		
	end

    always_ff @( posedge CLK2 ) begin
        if (STROBEI) begin
			pix[istate] <= DATAI;
			istate <= istate + 1;
        end
		else if (NEWLINE) begin
			istate <= 5'd0;
			lvalid <= 1'b0;
			state <= IDLE;
			crcb <= 1'b0;
			quad <= 2'd0;
		end
		if (NEWSLICE) begin
			tvalid <= 1'b0;
        end
        else if (NEWLINE) begin 
			tvalid <= 1'b1;
		end
		//
		if (!NEWLINE) begin
			if (state == IDLE && istate[4] == crcb) begin 
            end
			else if (state == 4'd7 && oquad != 2'd3) begin 
				state <= IDLE+4;			//loop to load all DC coeffs
            end
			else if (state == 4'd8 && READYO == 1'b0) begin
            end
			else if (state == 4'd14 && (fbpending == 1'b1 || FBSTROBE == 1'b1)) begin
            end
			else if (state == 4'd14 && quad != 2'd0) begin
				state <= IDLE+8;			//loop for all blocks
            end
            else begin
				state <= state+1;
			end
			//
			if (state == 4'd15) begin 
				crcb <= !crcb;
				if (crcb == 1'b1) begin
					lvalid <= 1'b1;	//new macroblk
				end
			end
			//
			if (state == 4'd5 || state == 4'd9 ) begin
				quad <= quad+1;
			end
			if (state == 4'd7 || state == 4'd11) begin
				oquad <= quad;
			end
			if (state == 4'd0 || state == 4'd1) begin 
				fquad[0] <= state[0];	//for latching topir/topil
            end
			else if (state == 4'd9) begin
				fquad <= quad;
			end
		end
		//
		if (state == 4'd1) begin
			topil <= TOPI;
        end
		else if (state == 4'd2) begin
			topir <= TOPI;
		end
		sumt <= {2'd0, topii[7:0]} + {2'd0, topii[15:8]} + {2'd0, topii[23:16]} + {2'd0, topii[31:24]};
		suml <= {2'd0, left0} + {2'd0, left1} + {2'd0, left2} + {2'd0, left3};
		if (state == 4'd4 || state == 4'd8) begin
			// set avg by setting sumtl
			// note: quad 1 and 2 don't use sumt+suml but prefer sumt or suml if poss
			if (lvalid == 1'b1 && tvalid == 1'b1 && (quad == 2'd0 || quad == 2'd3)) begin 	//left+top valid
				sumtl <= {1'b0, sumt} + {1'b0, suml} + 4;
            end
			else if (lvalid == 1'b1 && (tvalid == 1'b0 || quad == 2'd2)) begin
				sumtl <= {suml, 1'b0} + 4;
            end
			else if ((lvalid == 1'b0 || quad == 2'd1) && tvalid == 1'b1 ) begin
				sumtl <= {sumt, 1'b0} + 4;
            end
			else begin
				sumtl <= {8'h80, 3'd0};
			end
		end
		//
		//states 4..7, 8..11
		dat0 <= pix[{crcb, oquad[1], state[1:0], oquad[0]}];
		if (state == 4'd7) begin
			ddc1 <= 1'b1;
        end
		else begin
			ddc1 <= 1'b0;
		end
		//
		//states 5..(8), 9..12
		ddif0 <= {1'b0, dat0[7:0]} - {1'b0, sumtl[10:3]};
		ddif1 <= {1'b0, dat0[15:8]} - {1'b0, sumtl[10:3]};
		ddif2 <= {1'b0, dat0[23:16]} - {1'b0, sumtl[10:3]};
		ddif3 <= {1'b0, dat0[31:24]} - {1'b0, sumtl[10:3]};
		ddc2 <= ddc1;
		//
		//states 6..(9)
		if (state == 4'd6) begin 
			dtot <= {{4{ddif0[8]}}, ddif0} + {{4{ddif1[8]}}, ddif1} + {{4{ddif2[8]}}, ddif2} + {{4{ddif3[8]}}, ddif3};
        end
		else begin
			dtot <= dtot + {{4{ddif0[8]}}, ddif0} + {{4{ddif1[8]}}, ddif1} + {{4{ddif2[8]}}, ddif2} + {{4{ddif3[8]}}, ddif3};
		end
		DCSTROBEO <= ddc2;
		//
		//states 10..13
		if (state>=4'd10 && state<=4'd13) begin
			DATAO <= {ddif3, ddif2, ddif1, ddif0};
			BASEO <= {sumtl[10:3], sumtl[10:3], sumtl[10:3], sumtl[10:3]};
			STROBEO <= 1'b1;
		end
		else begin
			STROBEO <= 1'b0;
		end
		//		
		if (state == 4'd9) begin	//set feedback ptr to get later feedback
			fbptr <= {crcb, quad[1], 2'd0};
			fbpending <= 1'b1;
		end
		//
		// this comes back from transform/quantise/dequant/detransform loop
		// some time later... (state == 4'd13 waits for it)
		//
		if (FBSTROBE == 1'b1 && state >= 4'd12) begin
			if (quad[0] == 1'b0 ) begin
				pixleft[{1'b0,fbptr}] <= FEEDBI;
			end
			fbptr <= fbptr + 1;
			fbpending <= 1'b0;
		end
		//
	end
endmodule