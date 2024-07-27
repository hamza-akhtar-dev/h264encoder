
// H264 - Core Transform

module h264coretransform
(
    input logic CLK,	// fast io clock
    input logic RESET,
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

// New Parameters

logic input_1;  // Input for FSM-1
logic en_pipeline1,en_pipeline2,en_pipeline3,en_pipeline4; // Pipeline enable signals
logic en_pipeline5,en_pipeline6,en_pipeline7,en_pipeline8; // Pipeline enable signals
logic [13:0] ynout_in;
logic valid1_in;
logic [9:0] xt0_in,xt1_in,xt2_in,xt3_in;
logic [12:0] yt0_in,yt1_in,yt2_in,yt3_in;
logic [11:0] ffx0_in,ffx1_in,ffx2_in,ffx3_in;

// Pipeline Enables
assign en_pipeline1 = ENABLE;
assign en_pipeline7 = valid1;
assign en_pipeline8 = valid2;

assign input_1 = (ixx != 0);            // Input for FSM-1

// FSM-1 - Moore Machine with 8 states; S0,S1,S2,S3,S4,S5,S6,S7
h264coretransform_controller controller(
                            .CLK(CLK),
                            .RESET(RESET),
                            .ENABLE(ENABLE),
                            .input_1(input_1),
                            .en_pipeline2(en_pipeline2),
                            .en_pipeline3(en_pipeline3),
                            .en_pipeline4(en_pipeline4),
                            .en_pipeline5(en_pipeline5)
                            );

// ########################################

// ###### RESET, READY & COUNTERS #########

// ########################################
always_ff @(posedge CLK)
begin
    // Reset Signal is active low
    if (~RESET)
    begin
        ixx <= 0;   // Reset counter
    end
    else 
    begin
        if (ENABLE || (ixx != 0)) // Counter for ixx
        begin
            ixx <= ixx + 1;
        end
        if (en_pipeline6)         // Counter for iyn
        begin
            iyn <= iyn + 1;
        end
    end

    // READY Signal Generator
    if (ixx < 3 && (iyn >= 14 || iyn==0))
    begin
        READY <= 1;
    end
    else
    begin
        READY <= 0;
    end
end

// ########################################

// ######  Pipeline Register #1  ##########

// ########################################

always_comb
begin
    // --initial helpers (TT+1) (10bit from 9bit)
    xt0_in = {xx0[8], xx0} + {xx3[8], xx3};			//--xx0 + xx3
    xt1_in = {xx1[8], xx1} + {xx2[8], xx2};			//--xx1 + xx2
    xt2_in = {xx1[8], xx1} - {xx2[8], xx2};			//--xx1 - xx2
    xt3_in = {xx0[8], xx0} - {xx3[8], xx3};			//--xx0 - xx3
end

// Pipeline Register # 1    
always_ff @(posedge CLK)
begin
    if (ENABLE)
    begin
        // --initial helpers (TT+1) (10bit from 9bit)
        xt0 <= xt0_in;			//--xx0 + xx3
        xt1 <= xt1_in;			//--xx1 + xx2
        xt2 <= xt2_in;			//--xx1 - xx2
        xt3 <= xt3_in;			//--xx0 - xx3
    end
end

// ########################################

// ###### Pipeline Registers 2-5 ##########

// ########################################

always_comb
begin
    // --now compute row of FF matrix at TT+2 (12bit from 10bit)
    ffx0_in = {xt0[9], xt0[9], xt0} + {xt1[9], xt1[9], xt1};	    //--xt0 + xt1
    ffx1_in = {xt2[9], xt2[9], xt2} + {xt3[9], xt3, 1'b0};	 	//--xt2 + 2*xt3
    ffx2_in = {xt0[9], xt0[9], xt0} - {xt1[9], xt1[9], xt1};	    //--xt0 - xt1
    ffx3_in = {xt3[9], xt3[9], xt3} - {xt2[9], xt2, 1'b0};		//--xt3 - 2*xt2
end
// Pipeline Registers 2-5
always_ff @(posedge CLK)
begin
    // Registers powered by FSM-1
    // Pipeline 2
    if (en_pipeline2)
    begin
        // --now compute row of FF matrix at TT+2 (12bit from 10bit)
        ffx0 <= ffx0_in;
        ffx1 <= ffx1_in;
        ffx2 <= ffx2_in;
        ffx3 <= ffx3_in;
    end

    //--place rows 0,1,2 into slots at TT+3,4,5
    // Pipeline 3
    if (en_pipeline3) 
    begin
        ff00 <= ffx0;
        ff01 <= ffx1;
        ff02 <= ffx2;
        ff03 <= ffx3;
    end

    // Pipeline 4
    if (en_pipeline4)
    begin
        ff10 <= ffx0;
        ff11 <= ffx1;
        ff12 <= ffx2;
        ff13 <= ffx3;
    end 

    // Pipeline 5
    if (en_pipeline5) 
    begin
        ff20 <= ffx0;
        ff21 <= ffx1;
        ff22 <= ffx2;
        ff23 <= ffx3;
    end
end


// ########################################

// ######  Pipeline Register #6  ##########

// ########################################

// Muxes before Pipeline #6
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

    //assign yny = ynyx[3:2];  -- Unconditionally assigned
    //assign ynx = ynyx [1:0]; -- Unconditionally assigned

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

// Pipeline #6 & Register below Pipeline #6
always_comb
begin
    // en_pipeline6 Signal Generator for pipeline # 06
    if ((ixx == 5) || (iyn != 0))
        en_pipeline6 = 1;
    else
        en_pipeline6 = 0;

    // Mux below pipeline # 06
    if (en_pipeline6)
        valid1_in = 1'b1;
    else
        valid1_in = 1'b0;
end

// Signals used in Pipeline #6 are generated above and in always_comb block
always_ff @(posedge CLK)
begin
    if (en_pipeline6)
    begin
        ff0p <= ff0pu;
        ff1p <= ff1pu;
        ff2p <= ff2pu;
        ff3p <= ff3pu;
        yny1 <= yny;
    end

    // valid1 Register below Pipeline # 6
    // CLK dependent
    valid1 <= valid1_in;   // en_pipeline7
end

// ########################################

// ######  Pipeline Register #7  ##########

// ########################################

always_comb
begin
    yt0_in = {ff0p[11], ff0p} + {ff3p[11], ff3p};	    //--ff0 + ff3
    yt1_in = {ff1p[11], ff1p} + {ff2p[11], ff2p};	    //--ff1 + ff2
    yt2_in = {ff1p[11], ff1p} - {ff2p[11], ff2p};	    //--ff1 - ff2
    yt3_in = {ff0p[11], ff0p} - {ff3p[11], ff3p};	    //--ff0 - ff3
end

// Pipeline 7
always_ff @(posedge CLK)
begin
    if (en_pipeline7) 
    begin
        yt0 <= yt0_in;
        yt1 <= yt1_in;
        yt2 <= yt2_in;
        yt3 <= yt3_in;
        yny2 <= yny1;
    end

    // Valid2
    valid2 <= valid1;   // en_pipeline8
end

// ########################################

// ######  Pipeline Register #8  ##########

// ########################################

// MUX before Pipeline # 08
always_comb
begin
    //--compute final YNOUT values (14bit from 13bit)
    // yny -> yny1 -> yny2 ('yny2' is 'yny' after delay of '2 clock cycles')
    if (yny2==0) 
    begin
        ynout_in = {yt0[12], yt0} + {yt1[12], yt1};	//-- yt0 + yt1
    end
    else if (yny2==1) 
    begin
        ynout_in = {yt2[12], yt2} + {yt3, 1'b0};		//-- yt2 + 2*yt3
    end
    else if (yny2==2) 
    begin
        ynout_in = {yt0[12], yt0} - {yt1[12], yt1};    //-- yt0 - yt1
    end	   
    else
    begin
        ynout_in = {yt3[12], yt3} - {yt2, 1'b0};	    //-- yt3 - 2*yt2
    end 
end
// Pipeline # 08 (ENDING)
always_ff @(posedge CLK)
begin
    // OUTPUT "ynout_in"is computed at the end of always_comb block

    if (en_pipeline8)
    begin
        YNOUT <= ynout_in;
    end

    // VALID
    VALID <= valid2;
end

endmodule