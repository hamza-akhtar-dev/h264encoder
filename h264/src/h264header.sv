module h264header 
(
    input logic CLK,				//clock
	//slice:
	input logic NEWSLICE,		    //reset: this is the first in a slice
	input logic LASTSLICE,  	    //this is last slice in frame
	input logic SINTRA,			    //slice I flag
	//macroblock:
	input logic MINTRA,			    //macroblock I flag
	input logic LSTROBE,			//luma data here (16 of these)
	input logic CSTROBE,			//chroma data (first latches CMODE)
	input logic [5:0] QP,	        //0..51 as specified in standard	
	//for intra:
	input logic PMODE,			    //luma prev_intra4x4_pred_mode_flag
	input logic [2:0] RMODE,	    //luma rem_intra4x4_pred_mode_flag
	input logic [1:0] CMODE,	    //intra_chroma_pred_mode
	//for inter:
	input logic [1:0] PTYPE,	        //0=P16x16,1=P16x8,2=P8x16,3=subtypes
	input logic [1:0] PSUBTYPE,	//only if PTYPE=b"11"
	input logic [11:0] MVDX,	        //signed MVD X (qtr pixel)
	input logic [11:0] MVDY,	        //signed MVD Y (qtr pixel)
	//out:
	output logic [19:0] VE = 20'd0,
	output logic [4:0] VL = 5'd0,
	output logic VALID = 1'b0	        // VE/VL valid
);

	logic slicehead1 = 1'b0;	// if we need to emit slice header, part1
	logic slicehead2 = 1'b0;	// if we need to emit slice header, part2
	logic mbhead = 1'b0;		// if we need to emit mb header
	logic idrtwice = 1'b0;		// if 2 IDRs with no P's in middle
	logic [15:0] lbuf = 16'd0;	//accumulator for PMODE/RMODE
	logic [4:0] lbufc = 5'd0;	//count for PMODE/RMODE
	logic [1:0] cmodei = 2'd0;
	logic [3:0] lcount = 4'd0;
	logic ccount = 1'b0;
	logic [3:0] fcount = 4'd0;
	logic lstrobed = 1'b0;
	logic [3:0] emit = 4'd0;
	logic [3:0] ix = 4'd1;
	logic tailf = 1'b0;			// set if to emit tail
	logic pushf = 1'b0;			// set to push to abuf
	logic [15:0] sev;
	logic sevf = 1'b0;			// set if to emit sev
	logic [15:0] uevp1;     	//uev+1
	logic uevf = 1'b0;			// set if to emit uevp1
	//
	logic [15:0] abuf [15:0];
	logic [4:0] abufc [15:0];
	//
	localparam ZERO = 5'd0;

    always_ff @( posedge CLK )
	begin
		if (NEWSLICE || (emit==ix-1 && emit!=0)) 
		begin
			slicehead1 <= NEWSLICE;
			slicehead2 <= NEWSLICE;
			mbhead <= 1'b1;
			mbhead <= 1'b1;
			lcount <= '0;
			ccount <= 1'b0;
			lbufc <= '0;
			ix <= 4'd1;
			emit <= 4'd0;
        end
		else if (emit!=0)
		begin
			emit <= emit+1;
        end
		else if (slicehead1) 
		begin
			//NAL header byte: IDR or normal:
			if (SINTRA) 
			begin
				lbuf <= 16'h5525;		//0x25 (8bits)
            end
            else 
			begin
				lbuf <= 16'h5521;		//0x21 (8bits)
			end
			lbufc <= ZERO+8;
			pushf <= 1'b1;
			slicehead1 <= 1'b0;
        end
		else if (slicehead2 && !pushf) 
		begin
			// Summary: IDR I-frame headers are:
			//   1010100001001 (13 bits) or
			//   101010000010001 (15 bits)
			// Summary: P-frame headers are:
			//   11111nnnn01 (11 bits)
			if (SINTRA && !idrtwice)
			begin
				//here if I / IDR and previous wasn't IDR
				lbuf <= 16'b0010101110000100;	//101110000100 (12 bits)
				lbufc <= ZERO+12;
				idrtwice <= 1'b1;
				fcount <= {3'd0, LASTSLICE};		//next frame is 1
            end
            else if (SINTRA) 
			begin
				//here if I / IDR and previous was IDR (different tag)
				lbuf <= 16'b0010111000001000;	//10111000001000 (14 bits)
				lbufc <= ZERO+14;
				idrtwice <= 1'b0;
				fcount <= {3'd0, LASTSLICE};		//next frame is 1
            end
            else 
			begin
				//here if P
				lbuf <= {11'b00101011111, fcount, 1'b0};	//11111nnnn0 (10 bits)
				lbufc <= ZERO+10;
				idrtwice <= 1'b0;
				assert (PTYPE==0);	//only this supported at present
				if (LASTSLICE==1'b1) begin
					fcount <= fcount+1;		//next frame
				end
			end
			sev <= $signed(QP-26);
			sevf <= 1'b1;
			slicehead2 <= 1'b0;
			pushf <= 1'b1;
		end
		if (CSTROBE && !ccount && !NEWSLICE) 
		begin	//chroma
			ccount <= 1'b1;
			cmodei <= CMODE;
		end
		if (!LSTROBE) 
		begin
			lstrobed <= LSTROBE;
		end
		if (LSTROBE && !lstrobed && !NEWSLICE) 
		begin	//luma
			if (mbhead==1'b1 && pushf==1'b0) 
			begin
				//head: mb_skip_run (if SINTRA) and mb_type
				if (SINTRA && MINTRA) 
				begin	//macroblock header
					//mbtype=I4x4 /1/
					lbuf[5:0] <= 6'b000111;
					lbufc <= ZERO+1;
                end
				else if (!SINTRA && MINTRA) 
				begin
					//mbskiprun=0, mbtype=I4x4 in Pslice /100110/
					lbuf[5:0] <= 6'b100110;
					lbufc <= ZERO+7;
                end
				else 
				begin
					//mbskiprun=0, mbtype=P16x16 /11/
					lbuf[5:0] <= 6'b000111;
					lbufc <= ZERO+2;
				end
				mbhead <= 1'b0;
            end
			else if (!pushf) 
			begin
				//normal processing
				lcount <= lcount+1;
				lstrobed <= LSTROBE;
				if (MINTRA) 
				begin
					if (PMODE) 
					begin
						lbuf <= {lbuf[14:0], PMODE};
						lbufc <= lbufc+1;
                    end
					else 
					begin
						lbuf <= {lbuf[11:0], PMODE, RMODE};
						lbufc <= lbufc+4;
					end
                end
				else 
				begin// P macroblocks
					if (lcount==1 || lcount==2) 
					begin	//mvx=0 and mvy=0
						assert (MVDX==0 && MVDY==0);
						lbuf <= {lbuf[14:0], 1'b1};
						lbufc <= lbufc+1;
					end
				end
				if (lcount==15) 
				begin
					tailf <= 1'b1;
					pushf <= 1'b1;
				end
			end
		end
		//
		if (sevf) 
		begin
			//convert 16bit sev to 16bit uev, begin add 1
			//these equations have been optimised rather a lot
			if (!sev[15] && sev!=0) 
			begin
				uevp1 <= {sev[14:0], 1'b0};
            end
			else 
			begin
				uevp1 <= {(15'd0 - sev[14:0]), 1'b1};
			end
			uevf <= sevf;
			sevf <= 1'b0;
		end
		if (uevf) 
		begin
			lbuf <= uevp1;
			if (uevp1[15:1]==0) 
			begin
				lbufc <= ZERO+1; 
			end
			else if (uevp1[15:2]==0) 
			begin
				lbufc <= ZERO+3; 
			end
			else if (uevp1[15:3]==0) 
			begin
				lbufc <= ZERO+5; 
			end
			else if (uevp1[15:4]==0) 
			begin
				lbufc <= ZERO+7; 
			end
			else if (uevp1[15:5]==0) 
			begin
				lbufc <= ZERO+9; 
			end
			else if (uevp1[15:6]==0) 
			begin
				lbufc <= ZERO+11; 
			end
			else if (uevp1[15:7]==0) 
			begin
				lbufc <= ZERO+13; 
			end
			else if (uevp1[15:8]==0) 
			begin
				lbufc <= ZERO+15; 
			end
			else if (uevp1[15:9]==0) 
			begin
				lbufc <= ZERO+17; 
			end
			else if (uevp1[15:10]==0) 
			begin
				lbufc <= ZERO+19; 
			end
			else if (uevp1[15:11]==0) 
			begin
				lbufc <= ZERO+21; 
			end
			else if (uevp1[15:12]==0) 
			begin
				lbufc <= ZERO+23; 
			end
			else if (uevp1[15:13]==0 )
			begin
				lbufc <= ZERO+25; 
			end
			else if (uevp1[15:14]==0) 
			begin
				lbufc <= ZERO+27; 
			end
			else if (uevp1[15]==1'b0) 
			begin
				lbufc <= ZERO+29; 
			end
			else begin
				lbufc <= ZERO+31;
			end
			uevf <= sevf;
			pushf <= 1'b1;
		end
		//
		if (pushf && !NEWSLICE) 
		begin
			//emit to buffer
			if (lbufc!=0) 
			begin
				abuf[ix] <= lbuf;
				abufc[ix] <= lbufc;
				lbufc <= ZERO;
				ix <= ix+1;
			end
			pushf <= 1'b0;
        end
		else if (lbufc>12) 
		begin
			pushf <= 1'b1;
		end
		if (tailf && !pushf && !NEWSLICE && emit!=ix) 
		begin
			//tail: chromatype if I
			//tail: codedblockpattern /1/ or /0001101/; and slice_qp_delta /1/
			if (MINTRA) 
			begin
				if (!cmodei) 
				begin
					lbuf <= 16'b0000000000001111;	//111
					lbufc <= ZERO+3;
                end
				else 
				begin
					lbuf <= {12'b000000000010, (cmodei+1), 2'b11};	//0tt11
					lbufc <= ZERO+5;
				end
            end
			else 
			begin	//P
				lbuf <= 16'b0000000000011011;	//00011011
				lbufc <= ZERO+8;
			end
			pushf <= 1'b1;
			tailf <= 1'b0;
			emit <= emit+1;
		end

		if (emit != 0) 
		begin
			VALID <= 1'b1;
			VE <= {4'd0, abuf[emit]};
			VL <= abufc[emit];
        end
        else 
		begin
			VALID <= 1'b0;
		end      
    end
endmodule