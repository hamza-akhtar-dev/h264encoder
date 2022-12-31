module h264buffer
(
	input logic CLK,					    //clock
	input logic NEWSLICE,			        //-reset: this is the first in a slice
	input logic NEWLINE,				    //this is the first in a line
	
	input logic VALIDI,			    //luma/chroma data here (15/16/4 of these)
	input logic [11:0] ZIN,	            //luma/chroma data
	output logic READYI = 1'b0,		    //set when ready for next luma/chroma
	output logic CCIN = 1'b0,		    //set when inputting chroma
	output logic DONE = 1'b0,		    //set when all done and quiescent
	
	output logic [11:0] VOUT = 12'd0,	//luma/chroma data
	output logic VALIDO = 1'b0,		                        //strobe for data out

	output logic NLOAD = 1'b0,		                //load for CAVLC NOUT
	output logic [2:0] NX = 3'b000,	                //X value for NIN/NOUT
	output logic [2:0] NY = 3'b000,	                //Y value for NIN/NOUT
	output logic [1:0] NV = 2'b00,	                //valid flags for NIN/NOUT (1=left, 2=top, 3=avg)
	output logic NXINC =1'b0,	               //increment for X macroblock counter	

	input logic READYO,				//from cavlc module (goes inactive after block starts)
	input logic TREADYO,				//from tobytes module: tells it to freeze
	input logic HVALID 				//when header module outputting
);

	logic [11:0] buff [511:0];

	logic [3:0] ix = 4'h0;	            //index inside block
	logic [3:0] isubmb = 4'h0;          //index to blocks of luma
	logic [2:0] ichsubmb = 3'b000;      //index to blocks of chroma
	logic ichf = 1'b0;					//chroma flag
	logic ichdc = 1'b0;					//dc chroma flag
	logic [1:0] imb = 2'b00;	        //odd/even mb for chroma
	logic [3:0] ox = 4'h0;	            //index inside block
	logic [3:0] osubmb= 4'h0;           //index to blocks of luma
	logic ochf = 1'b0;					//chroma flag
	logic ochdc = 1'b0;					//dc chroma flag
	logic [1:0] omb = 2'b00;	        //odd/even mb for chroma
	logic nloadi = 1'b0;				//flag for nload (delay by 1)
	logic nxinci = 1'b0;				//flag for nload (delay by 1)
	logic nv0 = 1'b0;					//for NV(0)
	logic nv1 = 1'b0;					//for NV(1)
	logic nlvalid= 1'b0;				//left N is valid
	logic ntvalid= 1'b0;				//top N is valid
	logic ccinf = 1'b0;					//chroma in

	logic [8:0] addr;
	
	always_comb 
	begin
		if(omb==imb || (ochf==1 && isubmb<12) || (isubmb+1<osubmb && isubmb<12)) 
		begin
			READYI = 1'b1;
		end
		else 
		begin 
			READYI = 1'b0;
		end

		if(omb==imb && isubmb==0 && osubmb==0 && READYO==1'b1) 
		begin
			DONE = 1'b1;
		end
		else 
		begin
			DONE = 1'b0;
		end 

		if(nlvalid== 1'b1 || (osubmb[2] == 1'b1 && ochf==1'b0) || osubmb[0]==1'b1) 
		begin
			nv0 =1'b1;
		end
		else 
		begin
			nv0 = 1'b0;
		end

		if(ntvalid== 1'b1 || (osubmb[3] == 1'b1 && ochf==1'b0) || osubmb[1]==1'b1) 
		begin
			nv1 =1'b1;
		end
		else 
		begin
			nv1 = 1'b0;
		end
	end

	always_ff @(posedge CLK) 
	begin 

		if(NEWSLICE)  
		begin
			ix <= 4'h0;		//reset
			isubmb <= 4'h0;
			ichsubmb <= 3'b000;
			ichf <= 1'b0;
			ichdc <= 1'b0;
			imb <= 2'b00;
			ox <= 4'h0;
			osubmb <= 4'h0;
			ochf <= 1'b0;
			ochdc <= 1'b0;
			omb <= 2'b00;
			nloadi <= 1'b0;
			nlvalid <= 1'b0;
			ntvalid <= 1'b0;
		end

		else if (NEWLINE)
		begin
			nlvalid <= 1'b0;
			ntvalid <= 1'b1;
		end 
		//
		if (VALIDI && !NEWSLICE) 
		begin
			if (!ichf) 
			begin 
				addr = {1'b0, isubmb, ix};	
			end	
			else if (!ichdc) 
			begin
				addr = {1'b1, imb[0], ichsubmb, ix};
			end
			else  
			begin
				addr = {1'b1, imb[0], ichsubmb[2], (~ix[1:0]), 4'hf};
			end

			assert (!$isunknown(ZIN)) else $warning("Problems with ZIN severity WARNING");

			if (!ichf || ix!=15) 
			begin
				buff[addr] <= ZIN;
			end 

			if (!ichf) 
			begin	//luma
				ix <= ix + 1;
				if (ix==15) 
				begin
					isubmb <= isubmb+1;
					ichf <= ~isubmb[0];	//switch to chroma after even blocks
					if (isubmb==0 || isubmb==8) 
					begin
						ichdc <= 1'b1;
					end 
					if (isubmb==15) 
					begin
						imb <= imb+1;
					end
					assert (isubmb!=osubmb || ochf || ox>ix || imb==omb) else $error("xbuffer overflow? severity ERROR");
				end
			end
			else if (ichdc) 
			begin	//chromadc
				if (ix==3) 
				begin
					ix <= 4'h0;
					ichdc <= 1'b0;
				end
				else 
				begin
					ix <= ix + 1;
				end 
			end
			else if (!ichdc) 
			begin
				ix <= ix + 1;
				if (ix==15) 
				begin
					ichsubmb <= ichsubmb + 1;
					ichf <= 1'b0;
				end 
			end 
		end

		if (!VALIDI && !NEWSLICE) 
		begin
			assert (ix == 0) else $warning("VALIDI has fallen when in middle of block severity WARNING");
		end 
		//
		if (!NEWSLICE && !HVALID && imb!=omb && ((TREADYO && READYO) || ox!=0)) 
		begin
			//output
			if (!ochf) 
			begin
				addr = {1'b0, osubmb, ox};
			end
			else if(ochdc) 
			begin
				addr = {1'b1, omb[0], osubmb[2], ox[1:0], 4'hf};
			end
			else 
			begin
				addr = {1'b1, omb[0], osubmb[2:0], ox};
			end 	

			VOUT <= buff[addr];

			assert (!$isunknown(buff[addr])) else $warning("Problems with VOUT severity WARNING");

			VALIDO <= 1'b1;

			if (!ochf) 
			begin
				NX <= {1'b0, osubmb[2], osubmb[0]};
				NY <= {1'b0, osubmb[3], osubmb[1]};
			end
			else 
			begin
				NX <= {1'b1, osubmb[2], osubmb[0]};	//osubmb(2) is Cr/Cb flag
				NY <= {1'b1, osubmb[2], osubmb[1]};
			end

			if (!ochf) 
			begin
				ox <= ox+1;
				if (ox==15) 
				begin
					osubmb <= osubmb+1;
					if (osubmb==15) 
					begin
						ochf <= 1'b1;
						ochdc <= 1'b1;	//DC chroma follows Luma
					end
					nloadi <= 1'b1;
				end
			end
			else if (ochdc) 
			begin
				if (ox!=3) 
				begin
					ox <= ox+1;
				end
				else 
				begin
					ox <= 4'h0;					
					osubmb[2] <= ~osubmb[2];
					if (osubmb[2]) 
					begin
						ochdc <= 1'b0;	//AC chroma follows both DC chroma
					end 
				end
			end 
			else 
			begin
				if (ox!=14) 
				begin
					ox <= ox+1;
				end
				else 
				begin
					ox <= 4'h0;
					osubmb[2:0] <= osubmb[2:0] +1;
					if (osubmb[2:0]==7)
					begin
						ochf <= 1'b0;
						omb <= omb+1;
						nxinci <= 1'b1;
					end
					nloadi <= 1'b1;
				end 
			end 
		end
		else 
		begin
			VALIDO <= 1'b0;
		end

		NLOAD <= nloadi;
		NXINC <= nxinci;
		NV <= {nv1, nv0};

		if (nloadi) 
		begin
			nloadi <= 1'b0;
		end 

		if (nxinci) 
		begin
			nxinci <= 1'b0;
			nlvalid <= 1'b1;
		end 

		ccinf <= ichf & VALIDI;
		CCIN <= ccinf;

	end 	

endmodule