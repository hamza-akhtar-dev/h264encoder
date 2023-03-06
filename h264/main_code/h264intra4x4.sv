module h264intra4x4 
(
   input logic CLK,                    // pixel clock
   input logic NEWSLICE,               // indication this is the first in a slice
   input logic NEWLINE,                // indication this is the first on a line
   input logic STROBEI,                // data here
   input logic [31:0] DATAI,
   output logic READYI,
   //  top interface:
   input logic [31:0] TOPI,            // top pixels (to predict against)
   input logic [3:0] TOPMI,            // top block's mode (for P/RMODEO)
   output logic [1:0] XXO = 2'b00,     // which macroblock X
   output logic XXINC = 1'b0,          // when to increment XX macroblock
   //  feedback interface:
   input logic [7:0] FEEDBI,           // feedback for pixcol
   input logic FBSTROBE,               // feedback valid
   //  out interface:
   output logic STROBEO = 1'b0,        // data here
   output logic [35:0] DATAO = 36'd0,
   output logic [31:0] BASEO = 32'd0,  // base for reconstruct
   input  logic READYO = 1'b1,
   output logic MSTROBEO = 1'b0,       // modeo here
   output logic [3:0] MODEO = 4'd0,    // 0..8 prediction type
   output logic PMODEO = 1'b0,         // prev_i4x4_pred_mode_flag
   output logic [2:0] RMODEO = 3'd0,   // rem_i4x4_pred_mode_flag
   output logic CHREADY = 1'b0         // ready line to chroma
);

logic [31:0] pix [63:0] = '{default : '0};
logic [7:0] pixleft [15:0] = '{default : '0};
logic [7:0] pixlefttop = '0;
logic lvalid = '0;
logic tvalid = '0;
logic dconly = '0;
logic [31:0] topih = '0;
logic [31:0] topii = '0;

logic [5:0] statei = '0;
logic [4:0] state = '0;

logic outf1 = '0;
logic outf = '0;
logic chreadyi = '0;
logic chreadyii = '0;
logic readyod = '0;

logic [3:0] submb = '0;
logic [1:0] xx = '0;
logic [1:0] yy = '0;
logic [3:0] yyfull = '0; 
logic [1:0] oldxx = '0;
logic [3:0] fbptr = '0;
logic fbpending = '0;

logic [3:0] modeoi = '0;
logic [3:0] prevmode = '0;
logic [3:0] lmode [3:0] = '{default: 4'd9};  // lmode = 9       // doubt in this line 

logic [31:0] dat0 = '0;

logic [8:0] vdif0 = '0;
logic [8:0] vdif1 = '0;
logic [8:0] vdif2 = '0;
logic [8:0] vdif3 = '0;

logic [7:0] vabsdif0 = '0;
logic [7:0] vabsdif1 = '0;
logic [7:0] vabsdif2 = '0;
logic [7:0] vabsdif3 = '0;
logic [11:0] vtotdif = '0;

logic [7:0] leftp = '0;
logic [7:0] leftpd = '0;
logic [8:0] hdif0 = '0;
logic [8:0] hdif1 = '0;
logic [8:0] hdif2 = '0;
logic [8:0] hdif3 = '0;
logic [7:0] habsdif0 = '0;
logic [7:0] habsdif1 = '0;
logic [7:0] habsdif2 = '0;
logic [7:0] habsdif3 = '0;
logic [11:0] htotdif = '0;

logic [7:0] left0 = '0;
logic [7:0] left1 = '0;
logic [7:0] left2 = '0;
logic [7:0] left3 = '0;
logic [8:0] ddif0 = '0;
logic [8:0] ddif1 = '0;
logic [8:0] ddif2 = '0;
logic [8:0] ddif3 = '0;
logic [7:0] dabsdif0 = '0;
logic [7:0] dabsdif1 = '0;
logic [7:0] dabsdif2 = '0;
logic [7:0] dabsdif3 = '0;
logic [11:0] dtotdif = '0;
	
logic [9:0] sumt = '0;
logic [9:0] suml = '0;
logic [10:0] sumtl = '0;

integer xi, yi;

always_comb 
begin

   xx = {submb[2], submb[0]};
   yy = {submb[3], submb[1]};

   XXO = ((state == 5'd2) | (state == 5'd16)) ? xx : oldxx;
   XXINC = (state == 20) ? 1'b1: 1'b0;
   READYI  = ((statei[5:4] != (yy - 2'b10)) && (statei[5:4] != (yy - 2'b01))) ?  1'b1: 1'b0;
   yyfull = {yy, state[1:0]};

   left0 = pixleft[{yy, 2'b00}];
   left1 = pixleft[{yy, 2'b01}];
   left2 = pixleft[{yy, 2'b10}];
   left3 = pixleft[{yy, 2'b11}];

   MODEO = modeoi;
   CHREADY = chreadyii & READYO;
   
end

always_ff @( posedge CLK ) 
begin
	if (STROBEI) 
	begin
		pix[statei] <= DATAI;
		statei <= statei + 1;
	end
	else if (NEWLINE) 
	begin
		statei <= 6'b000000;
		lvalid <= 1'b0;
		state <= '0;
		STROBEO <= '0;
		fbpending <= '0;
	end          

	if (NEWSLICE) 
	begin
		tvalid <= '0;
	end
	else if (NEWLINE)
	begin
	   tvalid <= 1'b1;
	end

   	if (state == 15) 
	begin
		submb <= submb+1;
	end

	if (state == 1 || state == 15)
	begin
		oldxx <= xx;
	end
	
   	if (state == 0 && statei == 0) 
	begin end	         
	else if (state == 3 && statei[5:4] == yy) 
	begin end	        
	else if ((state ==11) && (!READYO || FBSTROBE || fbpending)) 
	begin end          
	else if (state == 15 && xx[0] && submb != 15) 
		state <= 2;	
	else if ((state == 19) && (FBSTROBE || fbpending || chreadyi || chreadyii))
	begin end         	
	else if (state == 19 && submb != 0) 
		state <= 3;	
	else if (state == 20)
   	state <= 0;		
	else
		state <= state+1;
		
	if (state == 15 && !xx[0]) 
		chreadyi <= 1;
		
	if (!outf && chreadyi && !READYO) begin
		chreadyii <= 1;
		chreadyi <= 0;
   end
	else if (!READYO && readyod && chreadyii) begin
		chreadyii <= 0;
	end 
	readyod <= READYO;
		
	if (state == 2 || state == 16) begin
		if (TOPMI < lmode[yy]) 
				prevmode <= TOPMI;
		else
			prevmode <= lmode[yy];
			
	sumt <= {2'b00, TOPI[7:0]} + {2'b00, TOPI[15:8]} + {2'b00, TOPI[23:16]} + {2'b00, TOPI[31:24]};
	topih <= TOPI;
	end
		
   suml <= {2'b00, left0} + {2'b00, left1} + {2'b00, left2} + {2'b00, left3};

	if (state == 3) begin
		if (lvalid || xx != 0) begin
			if (tvalid || yy != 0) 				
				sumtl <= {1'b0, sumt} + {1'b0, suml} + 4;
			else
				sumtl <= {suml, 1'b0} + 4;
      end
		else begin
			if (tvalid || yy != 0) 				
				sumtl <= {sumt, 1'b0} + 4;
			else
				sumtl <= {8'h80, 3'b000};
		end 
		topii <= topih;
	end
		
		dat0 <= pix[{yy, state[1:0], xx}];
		leftp <= pixleft[yyfull];
		
		vdif0 <= {1'b0, dat0[7:0]} - {1'b0, topii[7:0]};
		vdif1 <= {1'b0, dat0[15:8]} - {1'b0, topii[15:8]};
		vdif2 <= {1'b0, dat0[23:16]} - {1'b0, topii[23:16]};
		vdif3 <= {1'b0, dat0[31:24]} - {1'b0, topii[31:24]};
		
		hdif0 <= {1'b0, dat0[7:0]} - {1'b0, leftp};
		hdif1 <= {1'b0, dat0[15:8]} - {1'b0, leftp};
		hdif2 <= {1'b0, dat0[23:16]} - {1'b0, leftp};
		hdif3 <= {1'b0, dat0[31:24]} - {1'b0, leftp};
		leftpd <= leftp;
		
		ddif0 <= {1'b0, dat0[7:0]} - {1'b0, sumtl[10:3]};
		ddif1 <= {1'b0, dat0[15:8]} - {1'b0, sumtl[10:3]};
		ddif2 <= {1'b0, dat0[23:16]} - {1'b0, sumtl[10:3]};
		ddif3 <= {1'b0, dat0[31:24]} - {1'b0, sumtl[10:3]};
		if (!vdif0[8]) 
			vabsdif0 <= vdif0[7:0];
		else
			vabsdif0 <= 8'h00 - vdif0[7:0];
		
		if (!vdif1[8])
			vabsdif1 <= vdif1[7:0];
		else
			vabsdif1 <= 8'h00 - vdif1[7:0];
		
		if (!vdif2[8])
			vabsdif2 <= vdif2[7:0];
		else
			vabsdif2 <= 8'h00 - vdif2[7:0];

		if (!vdif3[8])
			vabsdif3 <= vdif3[7:0];
		else
			vabsdif3 <= 8'h00 - vdif3[7:0];
		
		if (!hdif0[8])
			habsdif0 <= hdif0[7:0];
		else
			habsdif0 <= 8'h00 - hdif0[7:0];
		
		if (!hdif1[8])
			habsdif1 <= hdif1[7:0];
		else
			habsdif1 <= 8'h00 - hdif1[7:0];
		
		if (!hdif2[8])
			habsdif2 <= hdif2[7:0];
		else
			habsdif2 <= 8'h00 - hdif2[7:0];
		
		if (!hdif3[8])
			habsdif3 <= hdif3[7:0];
		else
			habsdif3 <= 8'h00 - hdif3[7:0];
		
		if (!ddif0[8])
			dabsdif0 <= ddif0[7:0];
		else
			dabsdif0 <= 8'h00 - ddif0[7:0];
		
		if (!ddif1[8])
			dabsdif1 <= ddif1[7:0];
		else
			dabsdif1 <= 8'h00 - ddif1[7:0];
		
		if (!ddif2[8])
			dabsdif2 <= ddif2[7:0];
		else
			dabsdif2 <= 8'h00 - ddif2[7:0];
		
		if (!ddif3[8])
			dabsdif3 <= ddif3[7:0];
		else
			dabsdif3 <= 8'h00 - ddif3[7:0];
		
		if (state == 6) begin
			vtotdif <= '0;
			htotdif <= '0;
			dtotdif <= '0;
			if ((tvalid || yy != 0) && (lvalid || xx != 0)) 
				dconly <= 0;
			else
				dconly <= 1;
		end
		
		if (state >= 7 && state <= 10) begin
			vtotdif <= {8'h0, vabsdif0} + {8'h0, vabsdif1} + {8'h0, vabsdif2} + {8'h0, vabsdif3} + vtotdif;
			htotdif <= {8'h0, habsdif0} + {8'h0, habsdif1} + {8'h0, habsdif2} + {8'h0, habsdif3} + htotdif;
			dtotdif <= {8'h0, dabsdif0} + {8'h0, dabsdif1} + {8'h0, dabsdif2} + {8'h0, dabsdif3} + dtotdif;
		end 
		
		if (state == 11) begin
			if (vtotdif <= htotdif && vtotdif <= dtotdif && !dconly) 
				modeoi <= 8'h0;		
			else if (htotdif <= dtotdif && !dconly) 
				modeoi <= 8'h1;		
			else
				modeoi <= 8'h2;		
		end

		if (state == 12) begin
			lmode[yy] <= modeoi;
			assert (modeoi == 2 || !dconly) else $error("modeoi wrong for dconly");
			if (dconly || prevmode == modeoi)
				PMODEO <= 1;
			else if (modeoi < prevmode) begin
				PMODEO <= 0;
				RMODEO <= modeoi[2:0];
         	end
			else begin
				PMODEO <= 0;
				RMODEO <= modeoi[2:0] - 1;
			end 
		end 

		if (state >= 12 && state <= 15) 
			outf1 <= 1;
		else
			outf1 <= 0;
		
		outf <= outf1;
	
		if (outf) begin
			STROBEO <= 1;
			MSTROBEO <= ~outf1;
			if (modeoi == 0) begin
				DATAO <= {vdif3, vdif2, vdif1, vdif0};
				BASEO <= topii;
       		end
			else if (modeoi == 1) begin
				DATAO <= {hdif3, hdif2, hdif1, hdif0};
				BASEO <= {leftpd, leftpd, leftpd, leftpd};
        	end
			else if ( modeoi==2) begin
				DATAO <= {ddif3, ddif2, ddif1, ddif0};
				BASEO <= {sumtl[10:3], sumtl[10:3], sumtl[10:3], sumtl[10:3]};
			end 
      	end
		else begin
			STROBEO <= 0;
			MSTROBEO <= 0;
		end 

		if (state == 15 && !FBSTROBE) begin
			fbptr <= {yy, 2'b00};
			fbpending <= 1;
		end 
		
		if (FBSTROBE) begin
			pixleft[fbptr] <= FEEDBI;
			fbptr <= fbptr + 1;
			fbpending <= 0;
			if ((submb == 14 || submb == 15) && (!NEWLINE))
         		lvalid <= 1;
		end   

end
    
endmodule  