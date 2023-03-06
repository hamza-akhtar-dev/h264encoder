// -------------------------------------------------------------------------
// -- H264 core transform - VHDL
// -- 
// -- Written by Andy Henson
// -- Copyright (c) 2008 Zexia Access Ltd
// -- All rights reserved.

// -- This is the core forward transform for H264, without quantisation
// -- this acts on a 4x4 matrix

// -- We compute a result matrix Y from Cf X CfT . E
// -- where X is the input matrix (XX00...XX33), Y the result matrix
// -- Cf is the transform matrix, and CfT its transpose.

// -- this component gives YN which is Cf X CfT without multiply by E
// -- which is done at the quantisation stage.

// -- the intermediate matrix F is X CfT, "horizontal" ones

// -- FF00 is x=0,y=0,  FF01 is x=1 etc; delay 2 from X in (TT+2..TT+5)

// -- Input: XXIN the input matrix X at time TT..TT+3
// -- 4 beats of clock input horizontal rows; 4 x 9bit residuals each row; little endian order.
// -- Outputs: YNOUT the output matrix (before scaling by E)
// -- 16 beats of clock output YN in reverse zigzag order. TT+8..TT+23

// -- Passes test vectors (testresidual.txt) (May 2008)

// -- XST: 266 slices; 184 MHz; Xpower 3mW @ 120MHz


module h264coretransform
(
    input logic CLK,	//fast io clock
    output logic READY = '0,		//set when ready for ENABLE
    input logic ENABLE,				//values input only when this is 1
    input logic [35:0] XXIN,	 //4 x 9bit, first px is lsbs
    output logic VALID = '0,				//values output only when this is 1
    output logic [13:0] YNOUT = '0	//output (zigzag order)
);


    
logic [1:0] yny, ynx;
logic [8:0]  xx0, xx1, xx2, xx3;


assign xx0 = XXIN[8:0];
assign xx1 = XXIN[17:9];
assign xx2 = XXIN[26:18];
assign xx3 = XXIN[35:27];

logic [9:0] xt0 = 10'd0;
logic [9:0] xt1 = 10'd0;
logic [9:0] xt2 = 10'd0;
logic [9:0] xt3 = 10'd0;

logic [11:0] ff00 = 12'd0;
logic [11:0] ff01 = 12'd0;
logic [11:0] ff02 = 12'd0;
logic [11:0] ff03 = 12'd0;
logic [11:0] ff10 = 12'd0;
logic [11:0] ff11 = 12'd0;
logic [11:0] ff12 = 12'd0;
logic [11:0] ff13 = 12'd0;
logic [11:0] ff20 = 12'd0;
logic [11:0] ff21 = 12'd0;
logic [11:0] ff22 = 12'd0;
logic [11:0] ff23 = 12'd0;
logic [11:0] ffx0 = 12'd0;
logic [11:0] ffx1 = 12'd0;
logic [11:0] ffx2 = 12'd0;
logic [11:0] ffx3 = 12'd0;
logic [11:0] ff0p = 12'd0;
logic [11:0] ff1p = 12'd0;
logic [11:0] ff2p = 12'd0;
logic [11:0] ff3p = 12'd0;
logic [11:0] ff0pu = 12'd0;
logic [11:0] ff1pu = 12'd0;
logic [11:0] ff2pu = 12'd0;
logic [11:0] ff3pu = 12'd0;
logic [12:0] yt0 = 13'd0;
logic [12:0] yt1 = 13'd0;
logic [12:0] yt2 = 13'd0;
logic [12:0] yt3 = 13'd0;
logic valid1 = 1'd0;
logic valid2 = 1'd0;

logic [2:0] ixx = 3'd0;
logic [3:0] iyn = 4'd0;

logic [3:0] ynyx = 4'd0;

logic [1:0] yny1 = 2'd0;
logic [1:0] yny2 = 2'd0;

localparam ROW0 = 2'b00;
localparam ROW1 = 2'b01;
localparam ROW2 = 2'b10;
localparam ROW3 = 2'b11;
localparam COL0 = 2'b00;
localparam COL1 = 2'b01;
localparam COL2 = 2'b10;
localparam COL3 = 2'b11;

assign yny = ynyx[3:2];
assign ynx = ynyx [1:0];
	
always_comb 
begin
    case(iyn)
        4'd15 : ynyx = {ROW0, COL0};
        4'd14 : ynyx = {ROW0, COL1};
        4'd13 : ynyx = {ROW1, COL0};
        4'd12 : ynyx = {ROW2, COL0};
        4'd11 : ynyx = {ROW1, COL1};
        4'd10 : ynyx = {ROW0, COL2};
        4'd9  : ynyx = {ROW0, COL3};
        4'd8  : ynyx = {ROW1, COL2};
        4'd7  : ynyx = {ROW2, COL1};
        4'd6  : ynyx = {ROW3, COL0};
        4'd5  : ynyx = {ROW3, COL1};
        4'd4  : ynyx = {ROW2, COL2};
        4'd3  : ynyx = {ROW1, COL3};
        4'd2  : ynyx = {ROW2, COL3};
        4'd1  : ynyx = {ROW3, COL2};
        default : ynyx = {ROW3, COL3};
    endcase

    case(ynx)
        2'd0: 
        begin 
            ff0pu = ff00;
            ff1pu = ff10;
            ff2pu = ff20;
            ff3pu = ffx0;
        end

        2'd1: 
        begin 
            ff0pu = ff01;
            ff1pu = ff11;
            ff2pu = ff21;
            ff3pu = ffx1;
        end

        2'd2: 
        begin 
            ff0pu = ff02;
            ff1pu = ff12;
            ff2pu = ff22;
            ff3pu = ffx2;
        end

        default: 
        begin 
            ff0pu = ff03;
            ff1pu = ff13;
            ff2pu = ff23;
            ff3pu = ffx3;
        end 
    endcase
end
	
	
always_ff @(posedge CLK)
begin

    if (ENABLE || (ixx != 0)) 
    begin
        ixx <= ixx + 1;
    end 

    if (ixx < 3 && (iyn >= 14 || iyn==0)) 
    begin
        READY <= 1;
    end
    else
    begin
        READY <= 0;
    end 

		// --compute matrix ff, from XX times CfT
		// --CfT is 1  2  1  1
		// --       1  1 -1 -2
		// --       1 -1 -1  2
		// --       1 -2  1 -1

    if (ENABLE) 
    begin
        // --initial helpers (TT+1) (10bit from 9bit)
        xt0 <= {xx0[8], xx0} + {xx3[8], xx3};			//--xx0 + xx3
        xt1 <= {xx1[8], xx1} + {xx2[8], xx2};			//--xx1 + xx2
        xt2 <= {xx1[8], xx1} - {xx2[8], xx2};			//--xx1 - xx2
        xt3 <= {xx0[8], xx0} - {xx3[8], xx3};			//--xx0 - xx3
    end 

    if ((ixx>=1) && (ixx<=4)) 
    begin
        // --now compute row of FF matrix at TT+2 (12bit from 10bit)
        ffx0 <= {xt0[9], xt0[9], xt0} + {xt1[9], xt1[9], xt1};	    //--xt0 + xt1
        ffx1 <= {xt2[9], xt2[9], xt2} + {xt3[9], xt3, 1'b0};	 	//--xt2 + 2*xt3
        ffx2 <= {xt0[9], xt0[9], xt0} - {xt1[9], xt1[9], xt1};	    //--xt0 - xt1
        ffx3 <= {xt3[9], xt3[9], xt3} - {xt2[9], xt2, 1'b0};		//--xt3 - 2*xt2
    end 

    //--place rows 0,1,2 into slots at TT+3,4,5
    if (ixx==2) 
    begin
        ff00 <= ffx0;
        ff01 <= ffx1;
        ff02 <= ffx2;
        ff03 <= ffx3;
    end
    else if (ixx==3)
    begin
        ff10 <= ffx0;
        ff11 <= ffx1;
        ff12 <= ffx2;
        ff13 <= ffx3;
    end 
    else if (ixx==4) 
    begin
        ff20 <= ffx0;
        ff21 <= ffx1;
        ff22 <= ffx2;
        ff23 <= ffx3;
    end 

		// --
		// --compute element of matrix YN, from Cf times ff
		// --Cf is 1  1  1  1
		// --      2  1 -1 -2
		// --      1 -1 -1  1
		// --      1 -2  2 -1
		// --
		// --second stage helpers (13bit from 12bit) TT+6..TT+21
		// --ff0p..3 are column entries selected above

    if ((ixx == 5) || (iyn != 0))
    begin
        ff0p <= ff0pu;
        ff1p <= ff1pu;
        ff2p <= ff2pu;
        ff3p <= ff3pu;
        yny1 <= yny;
        iyn <= iyn + 1;
        valid1 <= 1'd1;
    end
    else 
    begin
        valid1 <= 1'd0;
    end 
    
    if (valid1) 
    begin
        yt0 <= {ff0p[11], ff0p} + {ff3p[11], ff3p};	    //--ff0 + ff3
        yt1 <= {ff1p[11], ff1p} + {ff2p[11], ff2p};	    //--ff1 + ff2
        yt2 <= {ff1p[11], ff1p} - {ff2p[11], ff2p};	    //--ff1 - ff2
        yt3 <= {ff0p[11], ff0p} - {ff3p[11], ff3p};	    //--ff0 - ff3
        yny2 <= yny1;
    end 

    // --now compute output stage
    if (valid2) 
    begin
        //--compute final YNOUT values (14bit from 13bit)
        if (yny2==0) 
        begin
            YNOUT <= {yt0[12], yt0} + {yt1[12], yt1};	//-- yt0 + yt1
        end
        else if (yny2==1) 
        begin
            YNOUT <= {yt2[12], yt2} + {yt3, 1'b0};		//-- yt2 + 2*yt3
        end
        else if (yny2==2) 
        begin
            YNOUT <= {yt0[12], yt0} - {yt1[12], yt1};  //-- yt0 - yt1
        end	   
        else 
        begin
            YNOUT <= {yt3[12], yt3} - {yt2, 1'b0};		   //-- yt3 - 2*yt2
        end 
    end

    valid2 <= valid1;
    VALID <= valid2;

end 

endmodule

