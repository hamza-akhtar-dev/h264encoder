module h264tobytes 
(
    input logic CLK,
    input logic VALID,
    output logic READY = 1'b1,
    input logic [24:0] VE = 25'd0,
    input logic [4:0] VL = 5'd0,
    output logic [7:0] BYTE = 8'd0,
    output logic STROBE = 1'b0,
    output logic DONE = 1'b0 
);

    logic [24:0] aVE [63:0];
	logic [4:0] aVL [63:0];
	logic [5:0] ain = '0;
	logic [5:0] aout = '0;
	logic [5:0] adiff = '0;
	logic [24:0] VE1 = '0;
	logic [4:0] VL1 = '0;
	//
	logic [4:0] ptr = '0;	//ptr, initally VL
	logic [2:0] sel = '0;	//part of VL
	logic [24:0] vbuf = '0;	//initially VE
	logic [10:0] bbuf = '0;	//buffer for byte
	logic [3:0] count = '0;	//count of valid bits
	logic alignflg = '0;
	logic doneflg = '0;
	logic [7:0] pbyte = '0;	//output (pre stuffing)
	logic pstrobe = '0;
	logic [1:0] pzeros = '0;
	logic [3:0] vbufsel = '0;	//selection of vbuf
	logic pop = '0;

    always_comb 
	begin
        case (sel)
            3'd0 : vbufsel =  vbuf[3:0];
            3'd1 : vbufsel =  vbuf[7:4];
            3'd2 : vbufsel =  vbuf[11:8];
            3'd3 : vbufsel =  vbuf[15:12];
            3'd4 : vbufsel =  vbuf[19:16];
            3'd5 : vbufsel =  vbuf[23:20];
            3'd6 : vbufsel =  {3'd0, vbuf[24]};
            default: vbufsel =  4'd0; 
        endcase

		adiff = ain - aout;
		READY = (adiff < 24) ? 1'b1 : 1'b0;
		pop = (ain!=aout && ptr<=4 && alignflg==0) ? 1'b1 : 1'b0;
		VE1 = aVE[aout];
		VL1 = aVL[aout];
    end

    always_ff @(posedge CLK) 
	begin
        //fifo
		if (VALID) 
		begin
			aVE[ain] <= VE;
			aVL[ain] <= VL;
			ain <= ain + 1;
			assert (adiff != 63) else $error ("Fifo overflow severity ERROR");
		end
		if (pop) 
		begin
			aout <= aout + 1;
		end
		//convert to bytes
		if (ptr>0) 
		begin
			//process up to 4 bits
			if (ptr[1:0] ==  0) 
			begin
				bbuf <= {bbuf[6:0], vbufsel[3:0]};		//process 4 bits
				count <= {1'b0,count[2:0]} + 4;
            end
			else if (ptr[1:0] == 3) 
			begin
				bbuf <= {bbuf[7:0], vbufsel[2:0]};		//process 3 bits
				count <= {1'b0,count[2:0]} + 3;
            end
			else if (ptr[1:0] == 2) 
			begin
				bbuf <= {bbuf[8:0], vbufsel[1:0]};		//process 2 bits
				count <= {1'b0,count[2:0]} + 2;
            end
			else 
			begin//1
				bbuf <= {bbuf[9:0], vbufsel[0]};		//process 1 bit
				count <= {1'b0,count[2:0]} + 1;
			end
        end
		else 
		begin //nothing to process
			count[3] <= 1'b0;	//keep low 3 bits, but this (the "available byte") clears
		end
		//
		if (ptr<=4 && alignflg==1'b1) 
		begin
			if (ptr==1'b0 && pstrobe==1'b0 && count[3]==1'b0) begin
				count[2:0] <= 3'd0;	//waste a cycle for alignment
				alignflg <= 1'b0;
				DONE <= doneflg;
            end
			else begin
				ptr <= 5'd0;
			end
        end
		else if (pop) 
		begin	//here to pop
			ptr <= VL1;
			vbuf <= VE1;
			alignflg <= VE1[16] && !VL1[4];	//if VL<16 and VE(16) set
			doneflg <= VE1[17] && !VL1[4];	//if VL<16 and VE(17) set
			if (VL1[1:0] == 0) 
			begin
				sel <= VL1[4:2]-1;
            end
			else 
			begin
				sel <= VL1[4:2];
			end
        end
		else
		begin	//process stuff in register
			if (ptr[1:0] != 0) 
			begin
				ptr[1:0] <= 2'd0;
				sel <= ptr[4:2]-1;
            end
			else if (ptr!=0) 
			begin
				ptr[4:2] <= ptr[4:2]-1;
				sel <= ptr[4:2]-2;
			end
		end

		if (count[3] == 1'b1) 
		begin
			if (count[1:0] == 2'd0) 
			begin
				pbyte <= bbuf[7:0];
            end
			else if (count[1:0]==1) 
			begin
				pbyte <= bbuf[8:1];
            end
			else if (count[1:0]==2) 
			begin
				pbyte <= bbuf[9:2]; 
            end
			else 
			begin
				pbyte <= bbuf[10:3];
            end
		end
	
		if (pstrobe==1'b1 && pzeros<2 && pbyte==0) 
		begin
			pzeros <= pzeros + 1;
        end
		else if (pstrobe==1'b1) 
		begin
			pzeros <= 2'd0;	//either because stuffed or non-zero
		end

		if (pstrobe==1'b1 && pzeros==2 && pbyte<4) 
		begin	
			BYTE <= 8'h03;			//stuff!!
			//leave pstrobe unchanged
        end
		else 
		begin
			BYTE <= pbyte;
			pstrobe <= count[3];
		end

		if (alignflg==1'b0 && doneflg==1'b1) 
		begin
			DONE <= 1'b0;
			doneflg <= 1'b0;
		end

		STROBE <= pstrobe;
    end
endmodule