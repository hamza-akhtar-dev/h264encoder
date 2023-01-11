module h264cavlc 
(
    input logic CLK, CLK2, ENABLE,
	input logic  SIN = 1'b0,
    input logic [11:0] VIN,
    input logic [4:0] NIN,
    output logic READY,
	output logic VS = 1'b0,
	output logic VALID = 1'b0,
    output logic [24:0] VE = 25'd0,
    output logic [4:0] VL = 5'd0,
	output logic [4:0] NOUT = 5'd0,
    output logic [2:0] XSTATE
);

	// information collected from input when ENABLE=1
	// all thse are in the "CLK2" timing domain
	logic eenable = '0;			//1 if ENABLE=1 seen
	logic eparity = '0;			//which register bank to use
	logic [4:0] emaxcoeffs = 5'd0;
	logic [4:0] etotalcoeffs = 5'd0;
	logic [4:0] etotalzeros = 5'd0;
	logic [1:0] etrailingones = 2'd0;	//max 3 allowed
	logic ecnz = 1'b0;		//flag set if coeff nz so far
	logic ecgt1 = 1'b0;	//flag set if coeff >1 so far
	logic [2:0] et1signs = 3'd0;		//signs of above (1=-ve)
	logic [3:0] erun = 4'd0;		//run before next coeff
	logic [3:0] eindex = 4'd0;	//index into coeff table
	logic [1:0] etable ;
	logic es = 1'b0;				//s (stream) flag
	// holding buffer; "CLK2" timing domain
	logic hvalidi = 1'b0;			//1 if holding buffer valid
	logic hvalid = 1'b0;			//1 if holding buffer valid (delayed 1 clk)
	logic hparity = 1'b0;			//which register bank to use
	logic [4:0] hmaxcoeffs = 5'd0;
	logic [4:0] htotalcoeffs = 5'd0;
	logic [4:0] htotalzeros = 5'd0;
	logic [1:0] htrailingones = 2'd0;	//max 3 allowed
	logic [1:0] htable;
	logic hs = 1'b0;				//s (stream) flag
	logic [2:0] t1signs = 3'd0;		//signs of above (1=-ve)
	//
	//information copied from above during STATE_IDLE or RUNBF
	//this is in the "CLK" domain
	logic [4:0] maxcoeffs = 5'd0;
	logic [4:0] totalcoeffs = 5'd0;
	logic [4:0] totalzeros = 5'd0;
	logic [1:0] trailingones = 2'd0;	//max 3 allowed
	logic parity = 1'b0;			//which register bank to use
	//
	// states private to this processing engine
	localparam STATE_IDLE   = 3'b000;
	localparam STATE_READ   = 3'b001;
	localparam STATE_CTOKEN = 3'b010;
	localparam STATE_T1SIGN = 3'b011;
	localparam STATE_COEFFS = 3'b100;
	localparam STATE_TZEROS = 3'b101;
	localparam STATE_RUNBF  = 3'b110;
	logic [2:0] state = STATE_IDLE;
	//
	// runbefore subprocessor state
	logic rbstate = 1'b0;		//1=running 0=done
	//
	//stuff used during processing
	logic [3:0] cindex = 4'd0;	//index into coeff table
	logic [10:0] abscoeff ;
	logic [10:0] abscoeffa ;			//adjusted version of abscoeff
	logic signcoeff = 1'b0;
	logic [2:0] suffixlen = 3'd0;			//0..6
	logic [3:0] rbindex = 4'd0;	//index into coeff table
	logic [3:0] runb = 4'd0;		//run before next coeff
	logic [4:0] rbzerosleft = 5'd0;
	logic [24:0] rbve = 25'd0;
	logic [4:0] rbvl = 5'd0;
	//tables
	logic [5:0] coeff_token ;
	logic [4:0] ctoken_len ;
	localparam CTABLE0 = 3'b000;
	localparam CTABLE1 = 3'b001;
	localparam CTABLE2 = 3'b010;
	localparam CTABLE3 = 3'b011;
	localparam CTABLE4 = 3'b100;
	logic [2:0] ctable = CTABLE0;
	logic [2:0] ztoken;
	logic [3:0] ztoken_len;
	logic ztable = '0;
	logic [2:0] rbtoken ;
	//data arrays
	logic [11:0] coeffarray [31:0] = '{default : 12'd0} ;
	logic [3:0] runbarray [31:0] = '{default : 4'd0} ;

	always_comb 
	begin 

		XSTATE = state;

		if ( trailingones==0 && totalcoeffs==0 && ctable==0 ) coeff_token = 6'b000001;
		else if ( trailingones==0 && totalcoeffs==1 && ctable==0 ) coeff_token = 6'b000101;
		else if ( trailingones==1 && totalcoeffs==1 && ctable==0 ) coeff_token = 6'b000001;
		else if ( trailingones==0 && totalcoeffs==2 && ctable==0 ) coeff_token = 6'b000111;
		else if ( trailingones==1 && totalcoeffs==2 && ctable==0 ) coeff_token = 6'b000100;
		else if ( trailingones==2 && totalcoeffs==2 && ctable==0 ) coeff_token = 6'b000001;
		else if ( trailingones==0 && totalcoeffs==3 && ctable==0 ) coeff_token = 6'b000111;
		else if ( trailingones==1 && totalcoeffs==3 && ctable==0 ) coeff_token = 6'b000110;
		else if ( trailingones==2 && totalcoeffs==3 && ctable==0 ) coeff_token = 6'b000101;
		else if ( trailingones==3 && totalcoeffs==3 && ctable==0 ) coeff_token = 6'b000011;
		else if ( trailingones==0 && totalcoeffs==4 && ctable==0 ) coeff_token = 6'b000111;
		else if ( trailingones==1 && totalcoeffs==4 && ctable==0 ) coeff_token = 6'b000110;
		else if ( trailingones==2 && totalcoeffs==4 && ctable==0 ) coeff_token = 6'b000101;
		else if ( trailingones==3 && totalcoeffs==4 && ctable==0 ) coeff_token = 6'b000011;
		else if ( trailingones==0 && totalcoeffs==5 && ctable==0 ) coeff_token = 6'b000111;
		else if ( trailingones==1 && totalcoeffs==5 && ctable==0 ) coeff_token = 6'b000110;
		else if ( trailingones==2 && totalcoeffs==5 && ctable==0 ) coeff_token = 6'b000101;
		else if ( trailingones==3 && totalcoeffs==5 && ctable==0 ) coeff_token = 6'b000100;
		else if ( trailingones==0 && totalcoeffs==6 && ctable==0 ) coeff_token = 6'b001111;
		else if ( trailingones==1 && totalcoeffs==6 && ctable==0 ) coeff_token = 6'b000110;
		else if ( trailingones==2 && totalcoeffs==6 && ctable==0 ) coeff_token = 6'b000101;
		else if ( trailingones==3 && totalcoeffs==6 && ctable==0 ) coeff_token = 6'b000100;
		else if ( trailingones==0 && totalcoeffs==7 && ctable==0 ) coeff_token = 6'b001011;
		else if ( trailingones==1 && totalcoeffs==7 && ctable==0 ) coeff_token = 6'b001110;
		else if ( trailingones==2 && totalcoeffs==7 && ctable==0 ) coeff_token = 6'b000101;
		else if ( trailingones==3 && totalcoeffs==7 && ctable==0 ) coeff_token = 6'b000100;
		else if ( trailingones==0 && totalcoeffs==8 && ctable==0 ) coeff_token = 6'b001000;
		else if ( trailingones==1 && totalcoeffs==8 && ctable==0 ) coeff_token = 6'b001010;
		else if ( trailingones==2 && totalcoeffs==8 && ctable==0 ) coeff_token = 6'b001101;
		else if ( trailingones==3 && totalcoeffs==8 && ctable==0 ) coeff_token = 6'b000100;
		else if ( trailingones==0 && totalcoeffs==9 && ctable==0 ) coeff_token = 6'b001111;
		else if ( trailingones==1 && totalcoeffs==9 && ctable==0 ) coeff_token = 6'b001110;
		else if ( trailingones==2 && totalcoeffs==9 && ctable==0 ) coeff_token = 6'b001001;
		else if ( trailingones==3 && totalcoeffs==9 && ctable==0 ) coeff_token = 6'b000100;
		else if ( trailingones==0 && totalcoeffs==10 && ctable==0 ) coeff_token = 6'b001011;
		else if ( trailingones==1 && totalcoeffs==10 && ctable==0 ) coeff_token = 6'b001010;
		else if ( trailingones==2 && totalcoeffs==10 && ctable==0 ) coeff_token = 6'b001101;
		else if ( trailingones==3 && totalcoeffs==10 && ctable==0 ) coeff_token = 6'b001100;
		else if ( trailingones==0 && totalcoeffs==11 && ctable==0 ) coeff_token = 6'b001111;
		else if ( trailingones==1 && totalcoeffs==11 && ctable==0 ) coeff_token = 6'b001110;
		else if ( trailingones==2 && totalcoeffs==11 && ctable==0 ) coeff_token = 6'b001001;
		else if ( trailingones==3 && totalcoeffs==11 && ctable==0 ) coeff_token = 6'b001100;
		else if ( trailingones==0 && totalcoeffs==12 && ctable==0 ) coeff_token = 6'b001011;
		else if ( trailingones==1 && totalcoeffs==12 && ctable==0 ) coeff_token = 6'b001010;
		else if ( trailingones==2 && totalcoeffs==12 && ctable==0 ) coeff_token = 6'b001101;
		else if ( trailingones==3 && totalcoeffs==12 && ctable==0 ) coeff_token = 6'b001000;
		else if ( trailingones==0 && totalcoeffs==13 && ctable==0 ) coeff_token = 6'b001111;
		else if ( trailingones==1 && totalcoeffs==13 && ctable==0 ) coeff_token = 6'b000001;
		else if ( trailingones==2 && totalcoeffs==13 && ctable==0 ) coeff_token = 6'b001001;
		else if ( trailingones==3 && totalcoeffs==13 && ctable==0 ) coeff_token = 6'b001100;
		else if ( trailingones==0 && totalcoeffs==14 && ctable==0 ) coeff_token = 6'b001011;
		else if ( trailingones==1 && totalcoeffs==14 && ctable==0 ) coeff_token = 6'b001110;
		else if ( trailingones==2 && totalcoeffs==14 && ctable==0 ) coeff_token = 6'b001101;
		else if ( trailingones==3 && totalcoeffs==14 && ctable==0 ) coeff_token = 6'b001000;
		else if ( trailingones==0 && totalcoeffs==15 && ctable==0 ) coeff_token = 6'b000111;
		else if ( trailingones==1 && totalcoeffs==15 && ctable==0 ) coeff_token = 6'b001010;
		else if ( trailingones==2 && totalcoeffs==15 && ctable==0 ) coeff_token = 6'b001001;
		else if ( trailingones==3 && totalcoeffs==15 && ctable==0 ) coeff_token = 6'b001100;
		else if ( trailingones==0 && totalcoeffs==16 && ctable==0 ) coeff_token = 6'b000100;
		else if ( trailingones==1 && totalcoeffs==16 && ctable==0 ) coeff_token = 6'b000110;
		else if ( trailingones==2 && totalcoeffs==16 && ctable==0 ) coeff_token = 6'b000101;
		else if ( trailingones==3 && totalcoeffs==16 && ctable==0 ) coeff_token = 6'b001000;
		else if ( trailingones==0 && totalcoeffs==0 && ctable==1 ) coeff_token = 6'b000011;
		else if ( trailingones==0 && totalcoeffs==1 && ctable==1 ) coeff_token = 6'b001011;
		else if ( trailingones==1 && totalcoeffs==1 && ctable==1 ) coeff_token = 6'b000010;
		else if ( trailingones==0 && totalcoeffs==2 && ctable==1 ) coeff_token = 6'b000111;
		else if ( trailingones==1 && totalcoeffs==2 && ctable==1 ) coeff_token = 6'b000111;
		else if ( trailingones==2 && totalcoeffs==2 && ctable==1 ) coeff_token = 6'b000011;
		else if ( trailingones==0 && totalcoeffs==3 && ctable==1 ) coeff_token = 6'b000111;
		else if ( trailingones==1 && totalcoeffs==3 && ctable==1 ) coeff_token = 6'b001010;
		else if ( trailingones==2 && totalcoeffs==3 && ctable==1 ) coeff_token = 6'b001001;
		else if ( trailingones==3 && totalcoeffs==3 && ctable==1 ) coeff_token = 6'b000101;
		else if ( trailingones==0 && totalcoeffs==4 && ctable==1 ) coeff_token = 6'b000111;
		else if ( trailingones==1 && totalcoeffs==4 && ctable==1 ) coeff_token = 6'b000110;
		else if ( trailingones==2 && totalcoeffs==4 && ctable==1 ) coeff_token = 6'b000101;
		else if ( trailingones==3 && totalcoeffs==4 && ctable==1 ) coeff_token = 6'b000100;
		else if ( trailingones==0 && totalcoeffs==5 && ctable==1 ) coeff_token = 6'b000100;
		else if ( trailingones==1 && totalcoeffs==5 && ctable==1 ) coeff_token = 6'b000110;
		else if ( trailingones==2 && totalcoeffs==5 && ctable==1 ) coeff_token = 6'b000101;
		else if ( trailingones==3 && totalcoeffs==5 && ctable==1 ) coeff_token = 6'b000110;
		else if ( trailingones==0 && totalcoeffs==6 && ctable==1 ) coeff_token = 6'b000111;
		else if ( trailingones==1 && totalcoeffs==6 && ctable==1 ) coeff_token = 6'b000110;
		else if ( trailingones==2 && totalcoeffs==6 && ctable==1 ) coeff_token = 6'b000101;
		else if ( trailingones==3 && totalcoeffs==6 && ctable==1 ) coeff_token = 6'b001000;
		else if ( trailingones==0 && totalcoeffs==7 && ctable==1 ) coeff_token = 6'b001111;
		else if ( trailingones==1 && totalcoeffs==7 && ctable==1 ) coeff_token = 6'b000110;
		else if ( trailingones==2 && totalcoeffs==7 && ctable==1 ) coeff_token = 6'b000101;
		else if ( trailingones==3 && totalcoeffs==7 && ctable==1 ) coeff_token = 6'b000100;
		else if ( trailingones==0 && totalcoeffs==8 && ctable==1 ) coeff_token = 6'b001011;
		else if ( trailingones==1 && totalcoeffs==8 && ctable==1 ) coeff_token = 6'b001110;
		else if ( trailingones==2 && totalcoeffs==8 && ctable==1 ) coeff_token = 6'b001101;
		else if ( trailingones==3 && totalcoeffs==8 && ctable==1 ) coeff_token = 6'b000100;
		else if ( trailingones==0 && totalcoeffs==9 && ctable==1 ) coeff_token = 6'b001111;
		else if ( trailingones==1 && totalcoeffs==9 && ctable==1 ) coeff_token = 6'b001010;
		else if ( trailingones==2 && totalcoeffs==9 && ctable==1 ) coeff_token = 6'b001001;
		else if ( trailingones==3 && totalcoeffs==9 && ctable==1 ) coeff_token = 6'b000100;
		else if ( trailingones==0 && totalcoeffs==10 && ctable==1 ) coeff_token = 6'b001011;
		else if ( trailingones==1 && totalcoeffs==10 && ctable==1 ) coeff_token = 6'b001110;
		else if ( trailingones==2 && totalcoeffs==10 && ctable==1 ) coeff_token = 6'b001101;
		else if ( trailingones==3 && totalcoeffs==10 && ctable==1 ) coeff_token = 6'b001100;
		else if ( trailingones==0 && totalcoeffs==11 && ctable==1 ) coeff_token = 6'b001000;
		else if ( trailingones==1 && totalcoeffs==11 && ctable==1 ) coeff_token = 6'b001010;
		else if ( trailingones==2 && totalcoeffs==11 && ctable==1 ) coeff_token = 6'b001001;
		else if ( trailingones==3 && totalcoeffs==11 && ctable==1 ) coeff_token = 6'b001000;
		else if ( trailingones==0 && totalcoeffs==12 && ctable==1 ) coeff_token = 6'b001111;
		else if ( trailingones==1 && totalcoeffs==12 && ctable==1 ) coeff_token = 6'b001110;
		else if ( trailingones==2 && totalcoeffs==12 && ctable==1 ) coeff_token = 6'b001101;
		else if ( trailingones==3 && totalcoeffs==12 && ctable==1 ) coeff_token = 6'b001100;
		else if ( trailingones==0 && totalcoeffs==13 && ctable==1 ) coeff_token = 6'b001011;
		else if ( trailingones==1 && totalcoeffs==13 && ctable==1 ) coeff_token = 6'b001010;
		else if ( trailingones==2 && totalcoeffs==13 && ctable==1 ) coeff_token = 6'b001001;
		else if ( trailingones==3 && totalcoeffs==13 && ctable==1 ) coeff_token = 6'b001100;
		else if ( trailingones==0 && totalcoeffs==14 && ctable==1 ) coeff_token = 6'b000111;
		else if ( trailingones==1 && totalcoeffs==14 && ctable==1 ) coeff_token = 6'b001011;
		else if ( trailingones==2 && totalcoeffs==14 && ctable==1 ) coeff_token = 6'b000110;
		else if ( trailingones==3 && totalcoeffs==14 && ctable==1 ) coeff_token = 6'b001000;
		else if ( trailingones==0 && totalcoeffs==15 && ctable==1 ) coeff_token = 6'b001001;
		else if ( trailingones==1 && totalcoeffs==15 && ctable==1 ) coeff_token = 6'b001000;
		else if ( trailingones==2 && totalcoeffs==15 && ctable==1 ) coeff_token = 6'b001010;
		else if ( trailingones==3 && totalcoeffs==15 && ctable==1 ) coeff_token = 6'b000001;
		else if ( trailingones==0 && totalcoeffs==16 && ctable==1 ) coeff_token = 6'b000111;
		else if ( trailingones==1 && totalcoeffs==16 && ctable==1 ) coeff_token = 6'b000110;
		else if ( trailingones==2 && totalcoeffs==16 && ctable==1 ) coeff_token = 6'b000101;
		else if ( trailingones==3 && totalcoeffs==16 && ctable==1 ) coeff_token = 6'b000100;
		else if ( trailingones==0 && totalcoeffs==0 && ctable==2 ) coeff_token = 6'b001111;
		else if ( trailingones==0 && totalcoeffs==1 && ctable==2 ) coeff_token = 6'b001111;
		else if ( trailingones==1 && totalcoeffs==1 && ctable==2 ) coeff_token = 6'b001110;
		else if ( trailingones==0 && totalcoeffs==2 && ctable==2 ) coeff_token = 6'b001011;
		else if ( trailingones==1 && totalcoeffs==2 && ctable==2 ) coeff_token = 6'b001111;
		else if ( trailingones==2 && totalcoeffs==2 && ctable==2 ) coeff_token = 6'b001101;
		else if ( trailingones==0 && totalcoeffs==3 && ctable==2 ) coeff_token = 6'b001000;
		else if ( trailingones==1 && totalcoeffs==3 && ctable==2 ) coeff_token = 6'b001100;
		else if ( trailingones==2 && totalcoeffs==3 && ctable==2 ) coeff_token = 6'b001110;
		else if ( trailingones==3 && totalcoeffs==3 && ctable==2 ) coeff_token = 6'b001100;
		else if ( trailingones==0 && totalcoeffs==4 && ctable==2 ) coeff_token = 6'b001111;
		else if ( trailingones==1 && totalcoeffs==4 && ctable==2 ) coeff_token = 6'b001010;
		else if ( trailingones==2 && totalcoeffs==4 && ctable==2 ) coeff_token = 6'b001011;
		else if ( trailingones==3 && totalcoeffs==4 && ctable==2 ) coeff_token = 6'b001011;
		else if ( trailingones==0 && totalcoeffs==5 && ctable==2 ) coeff_token = 6'b001011;
		else if ( trailingones==1 && totalcoeffs==5 && ctable==2 ) coeff_token = 6'b001000;
		else if ( trailingones==2 && totalcoeffs==5 && ctable==2 ) coeff_token = 6'b001001;
		else if ( trailingones==3 && totalcoeffs==5 && ctable==2 ) coeff_token = 6'b001010;
		else if ( trailingones==0 && totalcoeffs==6 && ctable==2 ) coeff_token = 6'b001001;
		else if ( trailingones==1 && totalcoeffs==6 && ctable==2 ) coeff_token = 6'b001110;
		else if ( trailingones==2 && totalcoeffs==6 && ctable==2 ) coeff_token = 6'b001101;
		else if ( trailingones==3 && totalcoeffs==6 && ctable==2 ) coeff_token = 6'b001001;
		else if ( trailingones==0 && totalcoeffs==7 && ctable==2 ) coeff_token = 6'b001000;
		else if ( trailingones==1 && totalcoeffs==7 && ctable==2 ) coeff_token = 6'b001010;
		else if ( trailingones==2 && totalcoeffs==7 && ctable==2 ) coeff_token = 6'b001001;
		else if ( trailingones==3 && totalcoeffs==7 && ctable==2 ) coeff_token = 6'b001000;
		else if ( trailingones==0 && totalcoeffs==8 && ctable==2 ) coeff_token = 6'b001111;
		else if ( trailingones==1 && totalcoeffs==8 && ctable==2 ) coeff_token = 6'b001110;
		else if ( trailingones==2 && totalcoeffs==8 && ctable==2 ) coeff_token = 6'b001101;
		else if ( trailingones==3 && totalcoeffs==8 && ctable==2 ) coeff_token = 6'b001101;
		else if ( trailingones==0 && totalcoeffs==9 && ctable==2 ) coeff_token = 6'b001011;
		else if ( trailingones==1 && totalcoeffs==9 && ctable==2 ) coeff_token = 6'b001110;
		else if ( trailingones==2 && totalcoeffs==9 && ctable==2 ) coeff_token = 6'b001010;
		else if ( trailingones==3 && totalcoeffs==9 && ctable==2 ) coeff_token = 6'b001100;
		else if ( trailingones==0 && totalcoeffs==10 && ctable==2 ) coeff_token = 6'b001111;
		else if ( trailingones==1 && totalcoeffs==10 && ctable==2 ) coeff_token = 6'b001010;
		else if ( trailingones==2 && totalcoeffs==10 && ctable==2 ) coeff_token = 6'b001101;
		else if ( trailingones==3 && totalcoeffs==10 && ctable==2 ) coeff_token = 6'b001100;
		else if ( trailingones==0 && totalcoeffs==11 && ctable==2 ) coeff_token = 6'b001011;
		else if ( trailingones==1 && totalcoeffs==11 && ctable==2 ) coeff_token = 6'b001110;
		else if ( trailingones==2 && totalcoeffs==11 && ctable==2 ) coeff_token = 6'b001001;
		else if ( trailingones==3 && totalcoeffs==11 && ctable==2 ) coeff_token = 6'b001100;
		else if ( trailingones==0 && totalcoeffs==12 && ctable==2 ) coeff_token = 6'b001000;
		else if ( trailingones==1 && totalcoeffs==12 && ctable==2 ) coeff_token = 6'b001010;
		else if ( trailingones==2 && totalcoeffs==12 && ctable==2 ) coeff_token = 6'b001101;
		else if ( trailingones==3 && totalcoeffs==12 && ctable==2 ) coeff_token = 6'b001000;
		else if ( trailingones==0 && totalcoeffs==13 && ctable==2 ) coeff_token = 6'b001101;
		else if ( trailingones==1 && totalcoeffs==13 && ctable==2 ) coeff_token = 6'b000111;
		else if ( trailingones==2 && totalcoeffs==13 && ctable==2 ) coeff_token = 6'b001001;
		else if ( trailingones==3 && totalcoeffs==13 && ctable==2 ) coeff_token = 6'b001100;
		else if ( trailingones==0 && totalcoeffs==14 && ctable==2 ) coeff_token = 6'b001001;
		else if ( trailingones==1 && totalcoeffs==14 && ctable==2 ) coeff_token = 6'b001100;
		else if ( trailingones==2 && totalcoeffs==14 && ctable==2 ) coeff_token = 6'b001011;
		else if ( trailingones==3 && totalcoeffs==14 && ctable==2 ) coeff_token = 6'b001010;
		else if ( trailingones==0 && totalcoeffs==15 && ctable==2 ) coeff_token = 6'b000101;
		else if ( trailingones==1 && totalcoeffs==15 && ctable==2 ) coeff_token = 6'b001000;
		else if ( trailingones==2 && totalcoeffs==15 && ctable==2 ) coeff_token = 6'b000111;
		else if ( trailingones==3 && totalcoeffs==15 && ctable==2 ) coeff_token = 6'b000110;
		else if ( trailingones==0 && totalcoeffs==16 && ctable==2 ) coeff_token = 6'b000001;
		else if ( trailingones==1 && totalcoeffs==16 && ctable==2 ) coeff_token = 6'b000100;
		else if ( trailingones==2 && totalcoeffs==16 && ctable==2 ) coeff_token = 6'b000011;
		else if ( trailingones==3 && totalcoeffs==16 && ctable==2 ) coeff_token = 6'b000010;
		else if ( trailingones==0 && totalcoeffs==0 && ctable==3 ) coeff_token = 6'b000011;
		else if ( trailingones==0 && totalcoeffs==1 && ctable==3 ) coeff_token = 6'b000000;
		else if ( trailingones==1 && totalcoeffs==1 && ctable==3 ) coeff_token = 6'b000001;
		else if ( trailingones==0 && totalcoeffs==2 && ctable==3 ) coeff_token = 6'b000100;
		else if ( trailingones==1 && totalcoeffs==2 && ctable==3 ) coeff_token = 6'b000101;
		else if ( trailingones==2 && totalcoeffs==2 && ctable==3 ) coeff_token = 6'b000110;
		else if ( trailingones==0 && totalcoeffs==3 && ctable==3 ) coeff_token = 6'b001000;
		else if ( trailingones==1 && totalcoeffs==3 && ctable==3 ) coeff_token = 6'b001001;
		else if ( trailingones==2 && totalcoeffs==3 && ctable==3 ) coeff_token = 6'b001010;
		else if ( trailingones==3 && totalcoeffs==3 && ctable==3 ) coeff_token = 6'b001011;
		else if ( trailingones==0 && totalcoeffs==4 && ctable==3 ) coeff_token = 6'b001100;
		else if ( trailingones==1 && totalcoeffs==4 && ctable==3 ) coeff_token = 6'b001101;
		else if ( trailingones==2 && totalcoeffs==4 && ctable==3 ) coeff_token = 6'b001110;
		else if ( trailingones==3 && totalcoeffs==4 && ctable==3 ) coeff_token = 6'b001111;
		else if ( trailingones==0 && totalcoeffs==5 && ctable==3 ) coeff_token = 6'b010000;
		else if ( trailingones==1 && totalcoeffs==5 && ctable==3 ) coeff_token = 6'b010001;
		else if ( trailingones==2 && totalcoeffs==5 && ctable==3 ) coeff_token = 6'b010010;
		else if ( trailingones==3 && totalcoeffs==5 && ctable==3 ) coeff_token = 6'b010011;
		else if ( trailingones==0 && totalcoeffs==6 && ctable==3 ) coeff_token = 6'b010100;
		else if ( trailingones==1 && totalcoeffs==6 && ctable==3 ) coeff_token = 6'b010101;
		else if ( trailingones==2 && totalcoeffs==6 && ctable==3 ) coeff_token = 6'b010110;
		else if ( trailingones==3 && totalcoeffs==6 && ctable==3 ) coeff_token = 6'b010111;
		else if ( trailingones==0 && totalcoeffs==7 && ctable==3 ) coeff_token = 6'b011000;
		else if ( trailingones==1 && totalcoeffs==7 && ctable==3 ) coeff_token = 6'b011001;
		else if ( trailingones==2 && totalcoeffs==7 && ctable==3 ) coeff_token = 6'b011010;
		else if ( trailingones==3 && totalcoeffs==7 && ctable==3 ) coeff_token = 6'b011011;
		else if ( trailingones==0 && totalcoeffs==8 && ctable==3 ) coeff_token = 6'b011100;
		else if ( trailingones==1 && totalcoeffs==8 && ctable==3 ) coeff_token = 6'b011101;
		else if ( trailingones==2 && totalcoeffs==8 && ctable==3 ) coeff_token = 6'b011110;
		else if ( trailingones==3 && totalcoeffs==8 && ctable==3 ) coeff_token = 6'b011111;
		else if ( trailingones==0 && totalcoeffs==9 && ctable==3 ) coeff_token = 6'b100000;
		else if ( trailingones==1 && totalcoeffs==9 && ctable==3 ) coeff_token = 6'b100001;
		else if ( trailingones==2 && totalcoeffs==9 && ctable==3 ) coeff_token = 6'b100010;
		else if ( trailingones==3 && totalcoeffs==9 && ctable==3 ) coeff_token = 6'b100011;
		else if ( trailingones==0 && totalcoeffs==10 && ctable==3 ) coeff_token = 6'b100100;
		else if ( trailingones==1 && totalcoeffs==10 && ctable==3 ) coeff_token = 6'b100101;
		else if ( trailingones==2 && totalcoeffs==10 && ctable==3 ) coeff_token = 6'b100110;
		else if ( trailingones==3 && totalcoeffs==10 && ctable==3 ) coeff_token = 6'b100111;
		else if ( trailingones==0 && totalcoeffs==11 && ctable==3 ) coeff_token = 6'b101000;
		else if ( trailingones==1 && totalcoeffs==11 && ctable==3 ) coeff_token = 6'b101001;
		else if ( trailingones==2 && totalcoeffs==11 && ctable==3 ) coeff_token = 6'b101010;
		else if ( trailingones==3 && totalcoeffs==11 && ctable==3 ) coeff_token = 6'b101011;
		else if ( trailingones==0 && totalcoeffs==12 && ctable==3 ) coeff_token = 6'b101100;
		else if ( trailingones==1 && totalcoeffs==12 && ctable==3 ) coeff_token = 6'b101101;
		else if ( trailingones==2 && totalcoeffs==12 && ctable==3 ) coeff_token = 6'b101110;
		else if ( trailingones==3 && totalcoeffs==12 && ctable==3 ) coeff_token = 6'b101111;
		else if ( trailingones==0 && totalcoeffs==13 && ctable==3 ) coeff_token = 6'b110000;
		else if ( trailingones==1 && totalcoeffs==13 && ctable==3 ) coeff_token = 6'b110001;
		else if ( trailingones==2 && totalcoeffs==13 && ctable==3 ) coeff_token = 6'b110010;
		else if ( trailingones==3 && totalcoeffs==13 && ctable==3 ) coeff_token = 6'b110011;
		else if ( trailingones==0 && totalcoeffs==14 && ctable==3 ) coeff_token = 6'b110100;
		else if ( trailingones==1 && totalcoeffs==14 && ctable==3 ) coeff_token = 6'b110101;
		else if ( trailingones==2 && totalcoeffs==14 && ctable==3 ) coeff_token = 6'b110110;
		else if ( trailingones==3 && totalcoeffs==14 && ctable==3 ) coeff_token = 6'b110111;
		else if ( trailingones==0 && totalcoeffs==15 && ctable==3 ) coeff_token = 6'b111000;
		else if ( trailingones==1 && totalcoeffs==15 && ctable==3 ) coeff_token = 6'b111001;
		else if ( trailingones==2 && totalcoeffs==15 && ctable==3 ) coeff_token = 6'b111010;
		else if ( trailingones==3 && totalcoeffs==15 && ctable==3 ) coeff_token = 6'b111011;
		else if ( trailingones==0 && totalcoeffs==16 && ctable==3 ) coeff_token = 6'b111100;
		else if ( trailingones==1 && totalcoeffs==16 && ctable==3 ) coeff_token = 6'b111101;
		else if ( trailingones==2 && totalcoeffs==16 && ctable==3 ) coeff_token = 6'b111110;
		else if ( trailingones==3 && totalcoeffs==16 && ctable==3 ) coeff_token = 6'b111111;
		else if ( trailingones==0 && totalcoeffs==0 && ctable==4 ) coeff_token = 6'b000001;
		else if ( trailingones==0 && totalcoeffs==1 && ctable==4 ) coeff_token = 6'b000111;
		else if ( trailingones==1 && totalcoeffs==1 && ctable==4 ) coeff_token = 6'b000001;
		else if ( trailingones==0 && totalcoeffs==2 && ctable==4 ) coeff_token = 6'b000100;
		else if ( trailingones==1 && totalcoeffs==2 && ctable==4 ) coeff_token = 6'b000110;
		else if ( trailingones==2 && totalcoeffs==2 && ctable==4 ) coeff_token = 6'b000001;
		else if ( trailingones==0 && totalcoeffs==3 && ctable==4 ) coeff_token = 6'b000011;
		else if ( trailingones==1 && totalcoeffs==3 && ctable==4 ) coeff_token = 6'b000011;
		else if ( trailingones==2 && totalcoeffs==3 && ctable==4 ) coeff_token = 6'b000010;
		else if ( trailingones==3 && totalcoeffs==3 && ctable==4 ) coeff_token = 6'b000101;
		else if ( trailingones==0 && totalcoeffs==4 && ctable==4 ) coeff_token = 6'b000010;
		else if ( trailingones==1 && totalcoeffs==4 && ctable==4 ) coeff_token = 6'b000011;
		else if ( trailingones==2 && totalcoeffs==4 && ctable==4 ) coeff_token = 6'b000010;
		else coeff_token = 6'b000000;


		if ( trailingones==0 && totalcoeffs==0 && ctable==0 ) ctoken_len = 5'b00001;
		else if ( trailingones==0 && totalcoeffs==1 && ctable==0 ) ctoken_len = 5'b00110;
		else if ( trailingones==1 && totalcoeffs==1 && ctable==0 ) ctoken_len = 5'b00010;
		else if ( trailingones==0 && totalcoeffs==2 && ctable==0 ) ctoken_len = 5'b01000;
		else if ( trailingones==1 && totalcoeffs==2 && ctable==0 ) ctoken_len = 5'b00110;
		else if ( trailingones==2 && totalcoeffs==2 && ctable==0 ) ctoken_len = 5'b00011;
		else if ( trailingones==0 && totalcoeffs==3 && ctable==0 ) ctoken_len = 5'b01001;
		else if ( trailingones==1 && totalcoeffs==3 && ctable==0 ) ctoken_len = 5'b01000;
		else if ( trailingones==2 && totalcoeffs==3 && ctable==0 ) ctoken_len = 5'b00111;
		else if ( trailingones==3 && totalcoeffs==3 && ctable==0 ) ctoken_len = 5'b00101;
		else if ( trailingones==0 && totalcoeffs==4 && ctable==0 ) ctoken_len = 5'b01010;
		else if ( trailingones==1 && totalcoeffs==4 && ctable==0 ) ctoken_len = 5'b01001;
		else if ( trailingones==2 && totalcoeffs==4 && ctable==0 ) ctoken_len = 5'b01000;
		else if ( trailingones==3 && totalcoeffs==4 && ctable==0 ) ctoken_len = 5'b00110;
		else if ( trailingones==0 && totalcoeffs==5 && ctable==0 ) ctoken_len = 5'b01011;
		else if ( trailingones==1 && totalcoeffs==5 && ctable==0 ) ctoken_len = 5'b01010;
		else if ( trailingones==2 && totalcoeffs==5 && ctable==0 ) ctoken_len = 5'b01001;
		else if ( trailingones==3 && totalcoeffs==5 && ctable==0 ) ctoken_len = 5'b00111;
		else if ( trailingones==0 && totalcoeffs==6 && ctable==0 ) ctoken_len = 5'b01101;
		else if ( trailingones==1 && totalcoeffs==6 && ctable==0 ) ctoken_len = 5'b01011;
		else if ( trailingones==2 && totalcoeffs==6 && ctable==0 ) ctoken_len = 5'b01010;
		else if ( trailingones==3 && totalcoeffs==6 && ctable==0 ) ctoken_len = 5'b01000;
		else if ( trailingones==0 && totalcoeffs==7 && ctable==0 ) ctoken_len = 5'b01101;
		else if ( trailingones==1 && totalcoeffs==7 && ctable==0 ) ctoken_len = 5'b01101;
		else if ( trailingones==2 && totalcoeffs==7 && ctable==0 ) ctoken_len = 5'b01011;
		else if ( trailingones==3 && totalcoeffs==7 && ctable==0 ) ctoken_len = 5'b01001;
		else if ( trailingones==0 && totalcoeffs==8 && ctable==0 ) ctoken_len = 5'b01101;
		else if ( trailingones==1 && totalcoeffs==8 && ctable==0 ) ctoken_len = 5'b01101;
		else if ( trailingones==2 && totalcoeffs==8 && ctable==0 ) ctoken_len = 5'b01101;
		else if ( trailingones==3 && totalcoeffs==8 && ctable==0 ) ctoken_len = 5'b01010;
		else if ( trailingones==0 && totalcoeffs==9 && ctable==0 ) ctoken_len = 5'b01110;
		else if ( trailingones==1 && totalcoeffs==9 && ctable==0 ) ctoken_len = 5'b01110;
		else if ( trailingones==2 && totalcoeffs==9 && ctable==0 ) ctoken_len = 5'b01101;
		else if ( trailingones==3 && totalcoeffs==9 && ctable==0 ) ctoken_len = 5'b01011;
		else if ( trailingones==0 && totalcoeffs==10 && ctable==0 ) ctoken_len = 5'b01110;
		else if ( trailingones==1 && totalcoeffs==10 && ctable==0 ) ctoken_len = 5'b01110;
		else if ( trailingones==2 && totalcoeffs==10 && ctable==0 ) ctoken_len = 5'b01110;
		else if ( trailingones==3 && totalcoeffs==10 && ctable==0 ) ctoken_len = 5'b01101;
		else if ( trailingones==0 && totalcoeffs==11 && ctable==0 ) ctoken_len = 5'b01111;
		else if ( trailingones==1 && totalcoeffs==11 && ctable==0 ) ctoken_len = 5'b01111;
		else if ( trailingones==2 && totalcoeffs==11 && ctable==0 ) ctoken_len = 5'b01110;
		else if ( trailingones==3 && totalcoeffs==11 && ctable==0 ) ctoken_len = 5'b01110;
		else if ( trailingones==0 && totalcoeffs==12 && ctable==0 ) ctoken_len = 5'b01111;
		else if ( trailingones==1 && totalcoeffs==12 && ctable==0 ) ctoken_len = 5'b01111;
		else if ( trailingones==2 && totalcoeffs==12 && ctable==0 ) ctoken_len = 5'b01111;
		else if ( trailingones==3 && totalcoeffs==12 && ctable==0 ) ctoken_len = 5'b01110;
		else if ( trailingones==0 && totalcoeffs==13 && ctable==0 ) ctoken_len = 5'b10000;
		else if ( trailingones==1 && totalcoeffs==13 && ctable==0 ) ctoken_len = 5'b01111;
		else if ( trailingones==2 && totalcoeffs==13 && ctable==0 ) ctoken_len = 5'b01111;
		else if ( trailingones==3 && totalcoeffs==13 && ctable==0 ) ctoken_len = 5'b01111;
		else if ( trailingones==0 && totalcoeffs==14 && ctable==0 ) ctoken_len = 5'b10000;
		else if ( trailingones==1 && totalcoeffs==14 && ctable==0 ) ctoken_len = 5'b10000;
		else if ( trailingones==2 && totalcoeffs==14 && ctable==0 ) ctoken_len = 5'b10000;
		else if ( trailingones==3 && totalcoeffs==14 && ctable==0 ) ctoken_len = 5'b01111;
		else if ( trailingones==0 && totalcoeffs==15 && ctable==0 ) ctoken_len = 5'b10000;
		else if ( trailingones==1 && totalcoeffs==15 && ctable==0 ) ctoken_len = 5'b10000;
		else if ( trailingones==2 && totalcoeffs==15 && ctable==0 ) ctoken_len = 5'b10000;
		else if ( trailingones==3 && totalcoeffs==15 && ctable==0 ) ctoken_len = 5'b10000;
		else if ( trailingones==0 && totalcoeffs==16 && ctable==0 ) ctoken_len = 5'b10000;
		else if ( trailingones==1 && totalcoeffs==16 && ctable==0 ) ctoken_len = 5'b10000;
		else if ( trailingones==2 && totalcoeffs==16 && ctable==0 ) ctoken_len = 5'b10000;
		else if ( trailingones==3 && totalcoeffs==16 && ctable==0 ) ctoken_len = 5'b10000;
		else if ( trailingones==0 && totalcoeffs==0 && ctable==1 ) ctoken_len = 5'b00010;
		else if ( trailingones==0 && totalcoeffs==1 && ctable==1 ) ctoken_len = 5'b00110;
		else if ( trailingones==1 && totalcoeffs==1 && ctable==1 ) ctoken_len = 5'b00010;
		else if ( trailingones==0 && totalcoeffs==2 && ctable==1 ) ctoken_len = 5'b00110;
		else if ( trailingones==1 && totalcoeffs==2 && ctable==1 ) ctoken_len = 5'b00101;
		else if ( trailingones==2 && totalcoeffs==2 && ctable==1 ) ctoken_len = 5'b00011;
		else if ( trailingones==0 && totalcoeffs==3 && ctable==1 ) ctoken_len = 5'b00111;
		else if ( trailingones==1 && totalcoeffs==3 && ctable==1 ) ctoken_len = 5'b00110;
		else if ( trailingones==2 && totalcoeffs==3 && ctable==1 ) ctoken_len = 5'b00110;
		else if ( trailingones==3 && totalcoeffs==3 && ctable==1 ) ctoken_len = 5'b00100;
		else if ( trailingones==0 && totalcoeffs==4 && ctable==1 ) ctoken_len = 5'b01000;
		else if ( trailingones==1 && totalcoeffs==4 && ctable==1 ) ctoken_len = 5'b00110;
		else if ( trailingones==2 && totalcoeffs==4 && ctable==1 ) ctoken_len = 5'b00110;
		else if ( trailingones==3 && totalcoeffs==4 && ctable==1 ) ctoken_len = 5'b00100;
		else if ( trailingones==0 && totalcoeffs==5 && ctable==1 ) ctoken_len = 5'b01000;
		else if ( trailingones==1 && totalcoeffs==5 && ctable==1 ) ctoken_len = 5'b00111;
		else if ( trailingones==2 && totalcoeffs==5 && ctable==1 ) ctoken_len = 5'b00111;
		else if ( trailingones==3 && totalcoeffs==5 && ctable==1 ) ctoken_len = 5'b00101;
		else if ( trailingones==0 && totalcoeffs==6 && ctable==1 ) ctoken_len = 5'b01001;
		else if ( trailingones==1 && totalcoeffs==6 && ctable==1 ) ctoken_len = 5'b01000;
		else if ( trailingones==2 && totalcoeffs==6 && ctable==1 ) ctoken_len = 5'b01000;
		else if ( trailingones==3 && totalcoeffs==6 && ctable==1 ) ctoken_len = 5'b00110;
		else if ( trailingones==0 && totalcoeffs==7 && ctable==1 ) ctoken_len = 5'b01011;
		else if ( trailingones==1 && totalcoeffs==7 && ctable==1 ) ctoken_len = 5'b01001;
		else if ( trailingones==2 && totalcoeffs==7 && ctable==1 ) ctoken_len = 5'b01001;
		else if ( trailingones==3 && totalcoeffs==7 && ctable==1 ) ctoken_len = 5'b00110;
		else if ( trailingones==0 && totalcoeffs==8 && ctable==1 ) ctoken_len = 5'b01011;
		else if ( trailingones==1 && totalcoeffs==8 && ctable==1 ) ctoken_len = 5'b01011;
		else if ( trailingones==2 && totalcoeffs==8 && ctable==1 ) ctoken_len = 5'b01011;
		else if ( trailingones==3 && totalcoeffs==8 && ctable==1 ) ctoken_len = 5'b00111;
		else if ( trailingones==0 && totalcoeffs==9 && ctable==1 ) ctoken_len = 5'b01100;
		else if ( trailingones==1 && totalcoeffs==9 && ctable==1 ) ctoken_len = 5'b01011;
		else if ( trailingones==2 && totalcoeffs==9 && ctable==1 ) ctoken_len = 5'b01011;
		else if ( trailingones==3 && totalcoeffs==9 && ctable==1 ) ctoken_len = 5'b01001;
		else if ( trailingones==0 && totalcoeffs==10 && ctable==1 ) ctoken_len = 5'b01100;
		else if ( trailingones==1 && totalcoeffs==10 && ctable==1 ) ctoken_len = 5'b01100;
		else if ( trailingones==2 && totalcoeffs==10 && ctable==1 ) ctoken_len = 5'b01100;
		else if ( trailingones==3 && totalcoeffs==10 && ctable==1 ) ctoken_len = 5'b01011;
		else if ( trailingones==0 && totalcoeffs==11 && ctable==1 ) ctoken_len = 5'b01100;
		else if ( trailingones==1 && totalcoeffs==11 && ctable==1 ) ctoken_len = 5'b01100;
		else if ( trailingones==2 && totalcoeffs==11 && ctable==1 ) ctoken_len = 5'b01100;
		else if ( trailingones==3 && totalcoeffs==11 && ctable==1 ) ctoken_len = 5'b01011;
		else if ( trailingones==0 && totalcoeffs==12 && ctable==1 ) ctoken_len = 5'b01101;
		else if ( trailingones==1 && totalcoeffs==12 && ctable==1 ) ctoken_len = 5'b01101;
		else if ( trailingones==2 && totalcoeffs==12 && ctable==1 ) ctoken_len = 5'b01101;
		else if ( trailingones==3 && totalcoeffs==12 && ctable==1 ) ctoken_len = 5'b01100;
		else if ( trailingones==0 && totalcoeffs==13 && ctable==1 ) ctoken_len = 5'b01101;
		else if ( trailingones==1 && totalcoeffs==13 && ctable==1 ) ctoken_len = 5'b01101;
		else if ( trailingones==2 && totalcoeffs==13 && ctable==1 ) ctoken_len = 5'b01101;
		else if ( trailingones==3 && totalcoeffs==13 && ctable==1 ) ctoken_len = 5'b01101;
		else if ( trailingones==0 && totalcoeffs==14 && ctable==1 ) ctoken_len = 5'b01101;
		else if ( trailingones==1 && totalcoeffs==14 && ctable==1 ) ctoken_len = 5'b01110;
		else if ( trailingones==2 && totalcoeffs==14 && ctable==1 ) ctoken_len = 5'b01101;
		else if ( trailingones==3 && totalcoeffs==14 && ctable==1 ) ctoken_len = 5'b01101;
		else if ( trailingones==0 && totalcoeffs==15 && ctable==1 ) ctoken_len = 5'b01110;
		else if ( trailingones==1 && totalcoeffs==15 && ctable==1 ) ctoken_len = 5'b01110;
		else if ( trailingones==2 && totalcoeffs==15 && ctable==1 ) ctoken_len = 5'b01110;
		else if ( trailingones==3 && totalcoeffs==15 && ctable==1 ) ctoken_len = 5'b01101;
		else if ( trailingones==0 && totalcoeffs==16 && ctable==1 ) ctoken_len = 5'b01110;
		else if ( trailingones==1 && totalcoeffs==16 && ctable==1 ) ctoken_len = 5'b01110;
		else if ( trailingones==2 && totalcoeffs==16 && ctable==1 ) ctoken_len = 5'b01110;
		else if ( trailingones==3 && totalcoeffs==16 && ctable==1 ) ctoken_len = 5'b01110;
		else if ( trailingones==0 && totalcoeffs==0 && ctable==2 ) ctoken_len = 5'b00100;
		else if ( trailingones==0 && totalcoeffs==1 && ctable==2 ) ctoken_len = 5'b00110;
		else if ( trailingones==1 && totalcoeffs==1 && ctable==2 ) ctoken_len = 5'b00100;
		else if ( trailingones==0 && totalcoeffs==2 && ctable==2 ) ctoken_len = 5'b00110;
		else if ( trailingones==1 && totalcoeffs==2 && ctable==2 ) ctoken_len = 5'b00101;
		else if ( trailingones==2 && totalcoeffs==2 && ctable==2 ) ctoken_len = 5'b00100;
		else if ( trailingones==0 && totalcoeffs==3 && ctable==2 ) ctoken_len = 5'b00110;
		else if ( trailingones==1 && totalcoeffs==3 && ctable==2 ) ctoken_len = 5'b00101;
		else if ( trailingones==2 && totalcoeffs==3 && ctable==2 ) ctoken_len = 5'b00101;
		else if ( trailingones==3 && totalcoeffs==3 && ctable==2 ) ctoken_len = 5'b00100;
		else if ( trailingones==0 && totalcoeffs==4 && ctable==2 ) ctoken_len = 5'b00111;
		else if ( trailingones==1 && totalcoeffs==4 && ctable==2 ) ctoken_len = 5'b00101;
		else if ( trailingones==2 && totalcoeffs==4 && ctable==2 ) ctoken_len = 5'b00101;
		else if ( trailingones==3 && totalcoeffs==4 && ctable==2 ) ctoken_len = 5'b00100;
		else if ( trailingones==0 && totalcoeffs==5 && ctable==2 ) ctoken_len = 5'b00111;
		else if ( trailingones==1 && totalcoeffs==5 && ctable==2 ) ctoken_len = 5'b00101;
		else if ( trailingones==2 && totalcoeffs==5 && ctable==2 ) ctoken_len = 5'b00101;
		else if ( trailingones==3 && totalcoeffs==5 && ctable==2 ) ctoken_len = 5'b00100;
		else if ( trailingones==0 && totalcoeffs==6 && ctable==2 ) ctoken_len = 5'b00111;
		else if ( trailingones==1 && totalcoeffs==6 && ctable==2 ) ctoken_len = 5'b00110;
		else if ( trailingones==2 && totalcoeffs==6 && ctable==2 ) ctoken_len = 5'b00110;
		else if ( trailingones==3 && totalcoeffs==6 && ctable==2 ) ctoken_len = 5'b00100;
		else if ( trailingones==0 && totalcoeffs==7 && ctable==2 ) ctoken_len = 5'b00111;
		else if ( trailingones==1 && totalcoeffs==7 && ctable==2 ) ctoken_len = 5'b00110;
		else if ( trailingones==2 && totalcoeffs==7 && ctable==2 ) ctoken_len = 5'b00110;
		else if ( trailingones==3 && totalcoeffs==7 && ctable==2 ) ctoken_len = 5'b00100;
		else if ( trailingones==0 && totalcoeffs==8 && ctable==2 ) ctoken_len = 5'b01000;
		else if ( trailingones==1 && totalcoeffs==8 && ctable==2 ) ctoken_len = 5'b00111;
		else if ( trailingones==2 && totalcoeffs==8 && ctable==2 ) ctoken_len = 5'b00111;
		else if ( trailingones==3 && totalcoeffs==8 && ctable==2 ) ctoken_len = 5'b00101;
		else if ( trailingones==0 && totalcoeffs==9 && ctable==2 ) ctoken_len = 5'b01000;
		else if ( trailingones==1 && totalcoeffs==9 && ctable==2 ) ctoken_len = 5'b01000;
		else if ( trailingones==2 && totalcoeffs==9 && ctable==2 ) ctoken_len = 5'b00111;
		else if ( trailingones==3 && totalcoeffs==9 && ctable==2 ) ctoken_len = 5'b00110;
		else if ( trailingones==0 && totalcoeffs==10 && ctable==2 ) ctoken_len = 5'b01001;
		else if ( trailingones==1 && totalcoeffs==10 && ctable==2 ) ctoken_len = 5'b01000;
		else if ( trailingones==2 && totalcoeffs==10 && ctable==2 ) ctoken_len = 5'b01000;
		else if ( trailingones==3 && totalcoeffs==10 && ctable==2 ) ctoken_len = 5'b00111;
		else if ( trailingones==0 && totalcoeffs==11 && ctable==2 ) ctoken_len = 5'b01001;
		else if ( trailingones==1 && totalcoeffs==11 && ctable==2 ) ctoken_len = 5'b01001;
		else if ( trailingones==2 && totalcoeffs==11 && ctable==2 ) ctoken_len = 5'b01000;
		else if ( trailingones==3 && totalcoeffs==11 && ctable==2 ) ctoken_len = 5'b01000;
		else if ( trailingones==0 && totalcoeffs==12 && ctable==2 ) ctoken_len = 5'b01001;
		else if ( trailingones==1 && totalcoeffs==12 && ctable==2 ) ctoken_len = 5'b01001;
		else if ( trailingones==2 && totalcoeffs==12 && ctable==2 ) ctoken_len = 5'b01001;
		else if ( trailingones==3 && totalcoeffs==12 && ctable==2 ) ctoken_len = 5'b01000;
		else if ( trailingones==0 && totalcoeffs==13 && ctable==2 ) ctoken_len = 5'b01010;
		else if ( trailingones==1 && totalcoeffs==13 && ctable==2 ) ctoken_len = 5'b01001;
		else if ( trailingones==2 && totalcoeffs==13 && ctable==2 ) ctoken_len = 5'b01001;
		else if ( trailingones==3 && totalcoeffs==13 && ctable==2 ) ctoken_len = 5'b01001;
		else if ( trailingones==0 && totalcoeffs==14 && ctable==2 ) ctoken_len = 5'b01010;
		else if ( trailingones==1 && totalcoeffs==14 && ctable==2 ) ctoken_len = 5'b01010;
		else if ( trailingones==2 && totalcoeffs==14 && ctable==2 ) ctoken_len = 5'b01010;
		else if ( trailingones==3 && totalcoeffs==14 && ctable==2 ) ctoken_len = 5'b01010;
		else if ( trailingones==0 && totalcoeffs==15 && ctable==2 ) ctoken_len = 5'b01010;
		else if ( trailingones==1 && totalcoeffs==15 && ctable==2 ) ctoken_len = 5'b01010;
		else if ( trailingones==2 && totalcoeffs==15 && ctable==2 ) ctoken_len = 5'b01010;
		else if ( trailingones==3 && totalcoeffs==15 && ctable==2 ) ctoken_len = 5'b01010;
		else if ( trailingones==0 && totalcoeffs==16 && ctable==2 ) ctoken_len = 5'b01010;
		else if ( trailingones==1 && totalcoeffs==16 && ctable==2 ) ctoken_len = 5'b01010;
		else if ( trailingones==2 && totalcoeffs==16 && ctable==2 ) ctoken_len = 5'b01010;
		else if ( trailingones==3 && totalcoeffs==16 && ctable==2 ) ctoken_len = 5'b01010;
		else if ( ctable==3 ) ctoken_len = 5'b00110;
		else if ( trailingones==0 && totalcoeffs==0 && ctable==4 ) ctoken_len = 5'b00010;
		else if ( trailingones==0 && totalcoeffs==1 && ctable==4 ) ctoken_len = 5'b00110;
		else if ( trailingones==1 && totalcoeffs==1 && ctable==4 ) ctoken_len = 5'b00001;
		else if ( trailingones==0 && totalcoeffs==2 && ctable==4 ) ctoken_len = 5'b00110;
		else if ( trailingones==1 && totalcoeffs==2 && ctable==4 ) ctoken_len = 5'b00110;
		else if ( trailingones==2 && totalcoeffs==2 && ctable==4 ) ctoken_len = 5'b00011;
		else if ( trailingones==0 && totalcoeffs==3 && ctable==4 ) ctoken_len = 5'b00110;
		else if ( trailingones==1 && totalcoeffs==3 && ctable==4 ) ctoken_len = 5'b00111;
		else if ( trailingones==2 && totalcoeffs==3 && ctable==4 ) ctoken_len = 5'b00111;
		else if ( trailingones==3 && totalcoeffs==3 && ctable==4 ) ctoken_len = 5'b00110;
		else if ( trailingones==0 && totalcoeffs==4 && ctable==4 ) ctoken_len = 5'b00110;
		else if ( trailingones==1 && totalcoeffs==4 && ctable==4 ) ctoken_len = 5'b01000;
		else if ( trailingones==2 && totalcoeffs==4 && ctable==4 ) ctoken_len = 5'b01000;
		else ctoken_len = 5'b00111;

		if ( totalzeros==0 && totalcoeffs==1 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==1 && totalcoeffs==1 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==2 && totalcoeffs==1 && ztable==0 )  ztoken = 3'b010;
		else if ( totalzeros==3 && totalcoeffs==1 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==4 && totalcoeffs==1 && ztable==0 )  ztoken = 3'b010;
		else if ( totalzeros==5 && totalcoeffs==1 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==6 && totalcoeffs==1 && ztable==0 )  ztoken = 3'b010;
		else if ( totalzeros==7 && totalcoeffs==1 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==8 && totalcoeffs==1 && ztable==0 )  ztoken = 3'b010;
		else if ( totalzeros==9 && totalcoeffs==1 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==10 && totalcoeffs==1 && ztable==0 ) ztoken = 3'b010;
		else if ( totalzeros==11 && totalcoeffs==1 && ztable==0 ) ztoken = 3'b011;
		else if ( totalzeros==12 && totalcoeffs==1 && ztable==0 ) ztoken = 3'b010;
		else if ( totalzeros==13 && totalcoeffs==1 && ztable==0 ) ztoken = 3'b011;
		else if ( totalzeros==14 && totalcoeffs==1 && ztable==0 ) ztoken = 3'b010;
		else if ( totalzeros==15 && totalcoeffs==1 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==0 && totalcoeffs==2 && ztable==0 )  ztoken = 3'b111;
		else if ( totalzeros==1 && totalcoeffs==2 && ztable==0 )  ztoken = 3'b110;
		else if ( totalzeros==2 && totalcoeffs==2 && ztable==0 )  ztoken = 3'b101;
		else if ( totalzeros==3 && totalcoeffs==2 && ztable==0 )  ztoken = 3'b100;
		else if ( totalzeros==4 && totalcoeffs==2 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==5 && totalcoeffs==2 && ztable==0 )  ztoken = 3'b101;
		else if ( totalzeros==6 && totalcoeffs==2 && ztable==0 )  ztoken = 3'b100;
		else if ( totalzeros==7 && totalcoeffs==2 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==8 && totalcoeffs==2 && ztable==0 )  ztoken = 3'b010;
		else if ( totalzeros==9 && totalcoeffs==2 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==10 && totalcoeffs==2 && ztable==0 ) ztoken = 3'b010;
		else if ( totalzeros==11 && totalcoeffs==2 && ztable==0 ) ztoken = 3'b011;
		else if ( totalzeros==12 && totalcoeffs==2 && ztable==0 ) ztoken = 3'b010;
		else if ( totalzeros==13 && totalcoeffs==2 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==14 && totalcoeffs==2 && ztable==0 ) ztoken = 3'b000;
		else if ( totalzeros==0 && totalcoeffs==3 && ztable==0 )  ztoken = 3'b101;
		else if ( totalzeros==1 && totalcoeffs==3 && ztable==0 )  ztoken = 3'b111;
		else if ( totalzeros==2 && totalcoeffs==3 && ztable==0 )  ztoken = 3'b110;
		else if ( totalzeros==3 && totalcoeffs==3 && ztable==0 )  ztoken = 3'b101;
		else if ( totalzeros==4 && totalcoeffs==3 && ztable==0 )  ztoken = 3'b100;
		else if ( totalzeros==5 && totalcoeffs==3 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==6 && totalcoeffs==3 && ztable==0 )  ztoken = 3'b100;
		else if ( totalzeros==7 && totalcoeffs==3 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==8 && totalcoeffs==3 && ztable==0 )  ztoken = 3'b010;
		else if ( totalzeros==9 && totalcoeffs==3 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==10 && totalcoeffs==3 && ztable==0 ) ztoken = 3'b010;
		else if ( totalzeros==11 && totalcoeffs==3 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==12 && totalcoeffs==3 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==13 && totalcoeffs==3 && ztable==0 ) ztoken = 3'b000;
		else if ( totalzeros==0 && totalcoeffs==4 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==1 && totalcoeffs==4 && ztable==0 )  ztoken = 3'b111;
		else if ( totalzeros==2 && totalcoeffs==4 && ztable==0 )  ztoken = 3'b101;
		else if ( totalzeros==3 && totalcoeffs==4 && ztable==0 )  ztoken = 3'b100;
		else if ( totalzeros==4 && totalcoeffs==4 && ztable==0 )  ztoken = 3'b110;
		else if ( totalzeros==5 && totalcoeffs==4 && ztable==0 )  ztoken = 3'b101;
		else if ( totalzeros==6 && totalcoeffs==4 && ztable==0 )  ztoken = 3'b100;
		else if ( totalzeros==7 && totalcoeffs==4 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==8 && totalcoeffs==4 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==9 && totalcoeffs==4 && ztable==0 )  ztoken = 3'b010;
		else if ( totalzeros==10 && totalcoeffs==4 && ztable==0 ) ztoken = 3'b010;
		else if ( totalzeros==11 && totalcoeffs==4 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==12 && totalcoeffs==4 && ztable==0 ) ztoken = 3'b000;
		else if ( totalzeros==0 && totalcoeffs==5 && ztable==0 )  ztoken = 3'b101;
		else if ( totalzeros==1 && totalcoeffs==5 && ztable==0 )  ztoken = 3'b100;
		else if ( totalzeros==2 && totalcoeffs==5 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==3 && totalcoeffs==5 && ztable==0 )  ztoken = 3'b111;
		else if ( totalzeros==4 && totalcoeffs==5 && ztable==0 )  ztoken = 3'b110;
		else if ( totalzeros==5 && totalcoeffs==5 && ztable==0 )  ztoken = 3'b101;
		else if ( totalzeros==6 && totalcoeffs==5 && ztable==0 )  ztoken = 3'b100;
		else if ( totalzeros==7 && totalcoeffs==5 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==8 && totalcoeffs==5 && ztable==0 )  ztoken = 3'b010;
		else if ( totalzeros==9 && totalcoeffs==5 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==10 && totalcoeffs==5 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==11 && totalcoeffs==5 && ztable==0 ) ztoken = 3'b000;
		else if ( totalzeros==0 && totalcoeffs==6 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==1 && totalcoeffs==6 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==2 && totalcoeffs==6 && ztable==0 )  ztoken = 3'b111;
		else if ( totalzeros==3 && totalcoeffs==6 && ztable==0 )  ztoken = 3'b110;
		else if ( totalzeros==4 && totalcoeffs==6 && ztable==0 )  ztoken = 3'b101;
		else if ( totalzeros==5 && totalcoeffs==6 && ztable==0 )  ztoken = 3'b100;
		else if ( totalzeros==6 && totalcoeffs==6 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==7 && totalcoeffs==6 && ztable==0 )  ztoken = 3'b010;
		else if ( totalzeros==8 && totalcoeffs==6 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==9 && totalcoeffs==6 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==10 && totalcoeffs==6 && ztable==0 ) ztoken = 3'b000;
		else if ( totalzeros==0 && totalcoeffs==7 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==1 && totalcoeffs==7 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==2 && totalcoeffs==7 && ztable==0 )  ztoken = 3'b101;
		else if ( totalzeros==3 && totalcoeffs==7 && ztable==0 )  ztoken = 3'b100;
		else if ( totalzeros==4 && totalcoeffs==7 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==5 && totalcoeffs==7 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==6 && totalcoeffs==7 && ztable==0 )  ztoken = 3'b010;
		else if ( totalzeros==7 && totalcoeffs==7 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==8 && totalcoeffs==7 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==9 && totalcoeffs==7 && ztable==0 )  ztoken = 3'b000;
		else if ( totalzeros==0 && totalcoeffs==8 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==1 && totalcoeffs==8 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==2 && totalcoeffs==8 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==3 && totalcoeffs==8 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==4 && totalcoeffs==8 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==5 && totalcoeffs==8 && ztable==0 )  ztoken = 3'b010;
		else if ( totalzeros==6 && totalcoeffs==8 && ztable==0 )  ztoken = 3'b010;
		else if ( totalzeros==7 && totalcoeffs==8 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==8 && totalcoeffs==8 && ztable==0 )  ztoken = 3'b000;
		else if ( totalzeros==0 && totalcoeffs==9 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==1 && totalcoeffs==9 && ztable==0 )  ztoken = 3'b000;
		else if ( totalzeros==2 && totalcoeffs==9 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==3 && totalcoeffs==9 && ztable==0 )  ztoken = 3'b011;
		else if ( totalzeros==4 && totalcoeffs==9 && ztable==0 )  ztoken = 3'b010;
		else if ( totalzeros==5 && totalcoeffs==9 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==6 && totalcoeffs==9 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==7 && totalcoeffs==9 && ztable==0 )  ztoken = 3'b001;
		else if ( totalzeros==0 && totalcoeffs==10 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==1 && totalcoeffs==10 && ztable==0 ) ztoken = 3'b000;
		else if ( totalzeros==2 && totalcoeffs==10 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==3 && totalcoeffs==10 && ztable==0 ) ztoken = 3'b011;
		else if ( totalzeros==4 && totalcoeffs==10 && ztable==0 ) ztoken = 3'b010;
		else if ( totalzeros==5 && totalcoeffs==10 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==6 && totalcoeffs==10 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==0 && totalcoeffs==11 && ztable==0 ) ztoken = 3'b000;
		else if ( totalzeros==1 && totalcoeffs==11 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==2 && totalcoeffs==11 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==3 && totalcoeffs==11 && ztable==0 ) ztoken = 3'b010;
		else if ( totalzeros==4 && totalcoeffs==11 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==5 && totalcoeffs==11 && ztable==0 ) ztoken = 3'b011;
		else if ( totalzeros==0 && totalcoeffs==12 && ztable==0 ) ztoken = 3'b000;
		else if ( totalzeros==1 && totalcoeffs==12 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==2 && totalcoeffs==12 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==3 && totalcoeffs==12 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==4 && totalcoeffs==12 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==0 && totalcoeffs==13 && ztable==0 ) ztoken = 3'b000;
		else if ( totalzeros==1 && totalcoeffs==13 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==2 && totalcoeffs==13 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==3 && totalcoeffs==13 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==0 && totalcoeffs==14 && ztable==0 ) ztoken = 3'b000;
		else if ( totalzeros==1 && totalcoeffs==14 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==2 && totalcoeffs==14 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==0 && totalcoeffs==15 && ztable==0 ) ztoken = 3'b000;
		else if ( totalzeros==1 && totalcoeffs==15 && ztable==0 ) ztoken = 3'b001;
		else if ( totalzeros==0 && totalcoeffs==1 && ztable==1 )  ztoken = 3'b001;
		else if ( totalzeros==1 && totalcoeffs==1 && ztable==1 )  ztoken = 3'b001;
		else if ( totalzeros==2 && totalcoeffs==1 && ztable==1 )  ztoken = 3'b001;
		else if ( totalzeros==3 && totalcoeffs==1 && ztable==1 )  ztoken = 3'b000;
		else if ( totalzeros==0 && totalcoeffs==2 && ztable==1 )  ztoken = 3'b001;
		else if ( totalzeros==1 && totalcoeffs==2 && ztable==1 )  ztoken = 3'b001;
		else if ( totalzeros==2 && totalcoeffs==2 && ztable==1 )  ztoken = 3'b000;
		else if ( totalzeros==0 && totalcoeffs==3 && ztable==1 )  ztoken = 3'b001;
		else ztoken = 3'b000;

		if ( totalzeros==0 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b0001;
		else if ( totalzeros==1 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==2 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==3 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==4 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==5 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==6 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==7 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==8 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==9 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b0111;
		else if ( totalzeros==10 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b0111;
		else if ( totalzeros==11 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b1000;
		else if ( totalzeros==12 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b1000;
		else if ( totalzeros==13 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b1001;
		else if ( totalzeros==14 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b1001;
		else if ( totalzeros==15 && totalcoeffs==1 && ztable==0 ) ztoken_len = 4'b1001;
		else if ( totalzeros==0 && totalcoeffs==2 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==1 && totalcoeffs==2 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==2 && totalcoeffs==2 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==3 && totalcoeffs==2 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==4 && totalcoeffs==2 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==5 && totalcoeffs==2 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==6 && totalcoeffs==2 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==7 && totalcoeffs==2 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==8 && totalcoeffs==2 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==9 && totalcoeffs==2 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==10 && totalcoeffs==2 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==11 && totalcoeffs==2 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==12 && totalcoeffs==2 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==13 && totalcoeffs==2 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==14 && totalcoeffs==2 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==0 && totalcoeffs==3 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==1 && totalcoeffs==3 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==2 && totalcoeffs==3 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==3 && totalcoeffs==3 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==4 && totalcoeffs==3 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==5 && totalcoeffs==3 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==6 && totalcoeffs==3 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==7 && totalcoeffs==3 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==8 && totalcoeffs==3 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==9 && totalcoeffs==3 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==10 && totalcoeffs==3 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==11 && totalcoeffs==3 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==12 && totalcoeffs==3 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==13 && totalcoeffs==3 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==0 && totalcoeffs==4 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==1 && totalcoeffs==4 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==2 && totalcoeffs==4 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==3 && totalcoeffs==4 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==4 && totalcoeffs==4 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==5 && totalcoeffs==4 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==6 && totalcoeffs==4 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==7 && totalcoeffs==4 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==8 && totalcoeffs==4 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==9 && totalcoeffs==4 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==10 && totalcoeffs==4 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==11 && totalcoeffs==4 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==12 && totalcoeffs==4 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==0 && totalcoeffs==5 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==1 && totalcoeffs==5 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==2 && totalcoeffs==5 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==3 && totalcoeffs==5 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==4 && totalcoeffs==5 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==5 && totalcoeffs==5 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==6 && totalcoeffs==5 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==7 && totalcoeffs==5 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==8 && totalcoeffs==5 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==9 && totalcoeffs==5 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==10 && totalcoeffs==5 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==11 && totalcoeffs==5 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==0 && totalcoeffs==6 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==1 && totalcoeffs==6 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==2 && totalcoeffs==6 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==3 && totalcoeffs==6 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==4 && totalcoeffs==6 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==5 && totalcoeffs==6 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==6 && totalcoeffs==6 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==7 && totalcoeffs==6 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==8 && totalcoeffs==6 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==9 && totalcoeffs==6 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==10 && totalcoeffs==6 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==0 && totalcoeffs==7 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==1 && totalcoeffs==7 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==2 && totalcoeffs==7 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==3 && totalcoeffs==7 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==4 && totalcoeffs==7 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==5 && totalcoeffs==7 && ztable==0 ) ztoken_len = 4'b0010;
		else if ( totalzeros==6 && totalcoeffs==7 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==7 && totalcoeffs==7 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==8 && totalcoeffs==7 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==9 && totalcoeffs==7 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==0 && totalcoeffs==8 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==1 && totalcoeffs==8 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==2 && totalcoeffs==8 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==3 && totalcoeffs==8 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==4 && totalcoeffs==8 && ztable==0 ) ztoken_len = 4'b0010;
		else if ( totalzeros==5 && totalcoeffs==8 && ztable==0 ) ztoken_len = 4'b0010;
		else if ( totalzeros==6 && totalcoeffs==8 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==7 && totalcoeffs==8 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==8 && totalcoeffs==8 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==0 && totalcoeffs==9 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==1 && totalcoeffs==9 && ztable==0 ) ztoken_len = 4'b0110;
		else if ( totalzeros==2 && totalcoeffs==9 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==3 && totalcoeffs==9 && ztable==0 ) ztoken_len = 4'b0010;
		else if ( totalzeros==4 && totalcoeffs==9 && ztable==0 ) ztoken_len = 4'b0010;
		else if ( totalzeros==5 && totalcoeffs==9 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==6 && totalcoeffs==9 && ztable==0 ) ztoken_len = 4'b0010;
		else if ( totalzeros==7 && totalcoeffs==9 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==0 && totalcoeffs==10 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==1 && totalcoeffs==10 && ztable==0 ) ztoken_len = 4'b0101;
		else if ( totalzeros==2 && totalcoeffs==10 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==3 && totalcoeffs==10 && ztable==0 ) ztoken_len = 4'b0010;
		else if ( totalzeros==4 && totalcoeffs==10 && ztable==0 ) ztoken_len = 4'b0010;
		else if ( totalzeros==5 && totalcoeffs==10 && ztable==0 ) ztoken_len = 4'b0010;
		else if ( totalzeros==6 && totalcoeffs==10 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==0 && totalcoeffs==11 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==1 && totalcoeffs==11 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==2 && totalcoeffs==11 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==3 && totalcoeffs==11 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==4 && totalcoeffs==11 && ztable==0 ) ztoken_len = 4'b0001;
		else if ( totalzeros==5 && totalcoeffs==11 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==0 && totalcoeffs==12 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==1 && totalcoeffs==12 && ztable==0 ) ztoken_len = 4'b0100;
		else if ( totalzeros==2 && totalcoeffs==12 && ztable==0 ) ztoken_len = 4'b0010;
		else if ( totalzeros==3 && totalcoeffs==12 && ztable==0 ) ztoken_len = 4'b0001;
		else if ( totalzeros==4 && totalcoeffs==12 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==0 && totalcoeffs==13 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==1 && totalcoeffs==13 && ztable==0 ) ztoken_len = 4'b0011;
		else if ( totalzeros==2 && totalcoeffs==13 && ztable==0 ) ztoken_len = 4'b0001;
		else if ( totalzeros==3 && totalcoeffs==13 && ztable==0 ) ztoken_len = 4'b0010;
		else if ( totalzeros==0 && totalcoeffs==14 && ztable==0 ) ztoken_len = 4'b0010;
		else if ( totalzeros==1 && totalcoeffs==14 && ztable==0 ) ztoken_len = 4'b0010;
		else if ( totalzeros==2 && totalcoeffs==14 && ztable==0 ) ztoken_len = 4'b0001;
		else if ( totalzeros==0 && totalcoeffs==15 && ztable==0 ) ztoken_len = 4'b0001;
		else if ( totalzeros==1 && totalcoeffs==15 && ztable==0 ) ztoken_len = 4'b0001;
		else if ( totalzeros==0 && totalcoeffs==1 && ztable==1 ) ztoken_len = 4'b0001;
		else if ( totalzeros==1 && totalcoeffs==1 && ztable==1 ) ztoken_len = 4'b0010;
		else if ( totalzeros==2 && totalcoeffs==1 && ztable==1 ) ztoken_len = 4'b0011;
		else if ( totalzeros==3 && totalcoeffs==1 && ztable==1 ) ztoken_len = 4'b0011;
		else if ( totalzeros==0 && totalcoeffs==2 && ztable==1 ) ztoken_len = 4'b0001;
		else if ( totalzeros==1 && totalcoeffs==2 && ztable==1 ) ztoken_len = 4'b0010;
		else if ( totalzeros==2 && totalcoeffs==2 && ztable==1 ) ztoken_len = 4'b0010;
		else if ( totalzeros==0 && totalcoeffs==3 && ztable==1 ) ztoken_len = 4'b0001;
		else ztoken_len = 4'b0001;

		if ( runb==0 ) rbtoken = 3'b111;
		else if ( runb==1 && rbzerosleft==1 ) rbtoken = 3'b000;
		else if ( runb==1 && rbzerosleft==2 ) rbtoken = 3'b001;
		else if ( runb==1 && rbzerosleft==3 ) rbtoken = 3'b010;
		else if ( runb==1 && rbzerosleft==4 ) rbtoken = 3'b010;
		else if ( runb==1 && rbzerosleft==5 ) rbtoken = 3'b010;
		else if ( runb==1 && rbzerosleft==6 ) rbtoken = 3'b000;
		else if ( runb==1 ) rbtoken = 3'b110;
		else if ( runb==2 && rbzerosleft==2 ) rbtoken = 3'b000;
		else if ( runb==2 && rbzerosleft==3 ) rbtoken = 3'b001;
		else if ( runb==2 && rbzerosleft==4 ) rbtoken = 3'b001;
		else if ( runb==2 && rbzerosleft==5 ) rbtoken = 3'b011;
		else if ( runb==2 && rbzerosleft==6 ) rbtoken = 3'b001;
		else if ( runb==2 ) rbtoken = 3'b101;
		else if ( runb==3 && rbzerosleft==3 ) rbtoken = 3'b000;
		else if ( runb==3 && rbzerosleft==4 ) rbtoken = 3'b001;
		else if ( runb==3 && rbzerosleft==5 ) rbtoken = 3'b010;
		else if ( runb==3 && rbzerosleft==6 ) rbtoken = 3'b011;
		else if ( runb==3 ) rbtoken = 3'b100;
		else if ( runb==4 && rbzerosleft==4 ) rbtoken = 3'b000;
		else if ( runb==4 && rbzerosleft==5 ) rbtoken = 3'b001;
		else if ( runb==4 && rbzerosleft==6 ) rbtoken = 3'b010;
		else if ( runb==4 ) rbtoken = 3'b011;
		else if ( runb==5 && rbzerosleft==5 ) rbtoken = 3'b000;
		else if ( runb==5 && rbzerosleft==6 ) rbtoken = 3'b101;
		else if ( runb==5 ) rbtoken = 3'b010;
		else if ( runb==6 && rbzerosleft==6 ) rbtoken = 3'b100;
		else rbtoken = 3'b001;

		READY = ~eenable;
		NOUT = etotalcoeffs;
	
	end


    always @( posedge CLK2 ) 
	begin

        if (ENABLE) 
		begin

			eenable <= 1;
			emaxcoeffs <= emaxcoeffs + 1;	//this is a coefficient
			es <= SIN;
			if (VIN != 0) 
			begin
				etotalcoeffs <= etotalcoeffs + 1;	//total nz coefficients
				ecnz <= 1;						//we've seen a non-zero
				if (VIN == 1 || VIN == 12'hFFF) 
				begin		// 1 or -1
					if (ecgt1 == 0 && etrailingones != 3 )
					begin
						etrailingones <= etrailingones + 1;
						et1signs <= {et1signs[1:0], VIN[11]};	//encode sign
					end
				end
				else
					ecgt1 <= 1;		//we've seen a greater-than-1
				//put coeffs into array; put runs into array
				//coeff is coded as sign & abscoeff
				if (VIN[11]==1) 
				begin 
					coeffarray[{eparity, eindex}] <= {1'b1, (11'd0 - VIN[10:0])};
				end
				else 
				begin
					coeffarray[{eparity, eindex}] <= VIN;
				end
				runbarray[{eparity, eindex}] <= erun;
				erun <= '0;
				eindex <= eindex+1;
			end

			else if (ecnz==1) 
			begin	//VIN=0 && ecnz
				etotalzeros <= etotalzeros + 1;		//totalzeros after first nz coeff
				erun <= erun + 1;
			end
			//select table for coeff_token (assume 4x4)
			if (NIN < 2) 
				etable <= CTABLE0[1:0];
			else if (NIN < 4) 
				etable <= CTABLE1[1:0];
			else if (NIN < 8) 
				etable <= CTABLE2[1:0];
			else
				etable <= CTABLE3[1:0];
			
		end

		else
		begin // ENABLE=0

			if (!hvalid && eenable) 
			begin
				//transfer to holding stage
				hmaxcoeffs <= emaxcoeffs;
				htotalcoeffs <= etotalcoeffs;
				htotalzeros <= etotalzeros;
				htrailingones <= etrailingones;
				htable <= etable;
				hs <= es;
				t1signs <= et1signs;
				hparity <= eparity;
				hvalidi <= 1'b1;
				assert (emaxcoeffs==16 || emaxcoeffs==15 || emaxcoeffs==4) else $error("H264CAVLC: maxcoeffs is not a valid value");
				//
				eenable <= 0;
				emaxcoeffs <= 5'd0;
				etotalcoeffs <= 5'd0;
				etotalzeros <= 5'd0;
				etrailingones <= 2'b00;
				erun <= '0;
				eindex <= '0;
				ecnz <= 0;
				ecgt1 <= 0;
				eparity <= ~eparity;
			end 
		end
		if (hvalid && (state==STATE_COEFFS) && (cindex > totalcoeffs[4:1]) && (parity==hparity) )
		begin
			//ok to clear holding register
			hvalidi <= 0;
		end 
		hvalid <= hvalidi;	//delay 1 cycle to overcome CLK/CLK2 sync problems
	end 

	logic [11:0] coeff;
	logic [4:0] tmpindex;

	logic [2:0] abscoeffa_sum1;
	logic [10:0] abscoeffa_sum2;
	logic [10:0] abscoeffa_sum3;
	logic [10:0] abscoeffa_sum4;
	logic [10:0] abscoeffa_sum5;
	logic [10:0] abscoeffa_sum6;
	logic [10:0] abscoeffa_sum7;

	assign abscoeffa_sum1 = abscoeffa[2:0]+1;
	assign abscoeffa_sum2 = abscoeffa-15;
	assign abscoeffa_sum3 = abscoeffa-30;
	assign abscoeffa_sum4 = abscoeffa-60;
	assign abscoeffa_sum5 = abscoeffa-120;
	assign abscoeffa_sum6 = abscoeffa-240;
	assign abscoeffa_sum7 = abscoeffa-480;

	always@(posedge CLK) 
	begin
		// maintain state
		if (state == STATE_IDLE)
		begin
			VALID <= 0; 
		end
		
		if ((state==STATE_IDLE || (state==STATE_RUNBF&& rbstate == 0)) && hvalid== 1) 
		begin	//done read, start processing
			maxcoeffs <= hmaxcoeffs;
			totalcoeffs <= htotalcoeffs;
			totalzeros <= htotalzeros;
			trailingones <= htrailingones;
			parity <= hparity;
			if (hmaxcoeffs==4) 
			begin
				ctable <= CTABLE4;	//special table for ChromaDC
				ztable <= 1;		//ditto
			end
			else 
			begin
				ctable <= {1'b0, htable};	//normal tables
				ztable <= 0;		//ditto
			end
			state <= STATE_CTOKEN;
			cindex <= {2'd0, htrailingones};
			if (htotalcoeffs>1)
			begin
				rbstate <= 1;	//runbefore processing starts
			end
			rbindex <= 2;
			tmpindex = {hparity,4'b0001};
			runb <= runbarray[tmpindex];
			rbzerosleft <= htotalzeros;
			rbvl <='0;
			rbve <= '0;
		end
		if (state == STATE_CTOKEN) 
		begin
			if (trailingones != 0) 
			begin
				state <= STATE_T1SIGN; 
			end
			else 
			begin
				state <= STATE_COEFFS; 
			end	//skip T1SIGN			
		end
		if (state == STATE_T1SIGN) 
		begin 
			state <= STATE_COEFFS;
		end
		if (state == STATE_COEFFS && (cindex>=totalcoeffs || cindex==0)) 
		begin
			if (totalcoeffs!=maxcoeffs && totalcoeffs!=0) 
			begin
				state <= STATE_TZEROS; 
			end
			else 
			begin 
				state <= STATE_RUNBF; 
			end	//skip TZEROS
		end 
		if (state == STATE_TZEROS)
		begin
			state <= STATE_RUNBF;
		end 
		if (state == STATE_RUNBF && rbstate == 1) 
		begin		//wait
			VALID <= 0; 
		end
		else if (state == STATE_RUNBF && rbstate == 0) 
		begin		//all done; reset && get ready to go again
			if (hvalid==0) 
			begin
				state <= STATE_IDLE;
			end
			if (rbvl != 0 && totalzeros != 0) 
			begin
				VALID <= 1;
				VE <= rbve;		//results of runbefore subprocessor
				VL <= rbvl;
			end
			else

				VALID <= 0;			
		end
		//
		//
		//runbefore subprocess
		//uses rbzerosleft, runarray with rbstate,rbindex,runb
		//(runb=runarray(0) when it starts)(no effect if rbzerosleft=0)
		if (rbstate == 1) 
		begin
			if (runb <= 7) 
			begin	//normal processing
				runb <= runbarray[{parity,rbindex}];
				rbindex <= rbindex+1;
				if (rbindex==totalcoeffs || rbzerosleft<=runb)
				 
				begin
					rbstate <= 0;	//done
				end
				//runb is currently runbarray(rbindex-1), since rbindex not yet loaded
				if (rbzerosleft + runb <= 2) 
				begin		//1 bit code
					rbve <= {rbve[23:0], ~runb[0]};
					rbvl <= rbvl + 1; 
				end
				else if (rbzerosleft + runb <= 6) 
				begin	//2 bit code
					rbve <= {rbve[22:0], rbtoken[1:0]};
					rbvl <= rbvl + 2; 
				end
				else if (runb <= 6) 
				begin				//3 bit code
					rbve <= {rbve[21:0], rbtoken[2:0]};
					rbvl <= rbvl + 3; 
				end
				else 
				begin	//runb=7					//4bit code
					rbve <= {rbve[20:0], 4'b0001};
					rbvl <= rbvl + 4; 
				end

				rbzerosleft <= rbzerosleft-runb;
			end
			else 
			begin		//runb > 7, emit a zero && reduce counters by 1
				rbve <= {rbve[23:0], 1'b0};
				rbvl <= rbvl + 1;
				rbzerosleft <= rbzerosleft-1;
				runb <= runb-1;
			end	
		end
		assert (rbvl <= 25) else $error("rbve overflow");
		//
		// output stuff...
		// CTOKEN
		if (state == STATE_CTOKEN) 
		begin
			//output coeff_token based on (totalcoeffs,trailingones)
			VE <= {16'h0, 3'b000, coeff_token};	//from tables above
			VL <= ctoken_len;
			VALID <= 1;
			VS <= hs;
			//setup for COEFFS (do it here 'cos T1SIGN may be skipped)
			//start at cindex=trailingones since we don't need to encode those
			coeff = coeffarray[{parity, 2'b0, trailingones}];
			
			cindex <= {2'b0, trailingones} + 1;
			signcoeff <= coeff[11];
			abscoeff <= coeff[10:0];
			if (trailingones==3) 
			begin
				abscoeffa <= coeff[10:0] - 1; 
			end	//normal case
			else 
			begin
				abscoeffa <= coeff[10:0] - 2; 
			end	//special case for t1s<3
			if (totalcoeffs>10 && trailingones!=3) 
			begin
				suffixlen <= 3'b001; 
			end	//start at 1
			else 
			begin
				suffixlen <= 3'b000; 
			end	//start at zero (normal)
		end
		// T1SIGN
		if (state == STATE_T1SIGN) 
		begin
			assert (trailingones != 0) else $error ;
			VALID <= 1;
			VE <= {20'h00000, 2'b00, t1signs};
			VL <= {3'b000, trailingones};
		end 
		// COEFFS
		// uses suffixlen, lesstwo, coeffarray, abscoeff, signcoeff, cindex
		if (state == STATE_COEFFS) 
		begin
			//uses abscoeff, signcoeff loaded from array last time
			//if "lessone" begin already applied to abscoeff
			//&& +ve has 1 subtracted from it
			if (suffixlen == 0)
		    begin
				//three sub-cases depending on size of abscoeff
				if (abscoeffa < 7) 
				begin
					//normal, just levelprefix which is unary encoded
					VE <= {1'b0, 24'h000001};
					VL <= {abscoeffa[3:0], signcoeff} + 1;
				end
				else if (abscoeffa < 15) 
				begin		//7..14
					//use level 14 with 4bit suffix
					//subtract 7 && use 3 bits of abscoeffa (same as add 1)
					VE <= {1'b0, 20'h00001, abscoeffa_sum1, signcoeff};
					VL <= 5'b10011;	//14+1+4 = 19 bits
				end
				else 
				begin
					//use level 15 with 12bit suffix
					VE <= {1'b0, 12'h001, abscoeffa_sum2, signcoeff};
					VL <= 5'b11100;	//15+1+12 = 28 bits
				end
				if (abscoeff > 3) 
				begin
					suffixlen <= 3'b010;	
				end //double increment
				else
				begin
					suffixlen <= 3'b001; 
				end	//always increment
			end
			else 
			begin //suffixlen > 0: 1..6
				if (suffixlen==1 && abscoeffa < 15) 
				begin
					VE <= {1'b0, 20'h00000, 3'b001, signcoeff};
					VL <= abscoeffa[4:0] + 2; 
				end
				else if (suffixlen==2 && abscoeffa < 30) 
				begin
					VE <= {1'b0, 20'h00000, 2'b01, abscoeffa[0], signcoeff};
					VL <= abscoeffa[5:1] + 3; 
				end
				else if (suffixlen==3 && abscoeffa < 60) 
				begin
					VE <= {1'b0, 20'h00000, 1'b1, abscoeffa[1:0], signcoeff};
					VL <= abscoeffa[6:2] + 4; 
				end
				else if (suffixlen==4 && abscoeffa < 120) 
				begin
					VE <= {1'b0, 20'h00001, abscoeffa[2:0], signcoeff};
					VL <= abscoeffa[7:3] + 5; 
				end
				else if (suffixlen==5 && abscoeffa < 240) 
				begin
					VE <= {1'b0, 16'h0000, 3'b001, abscoeffa[3:0], signcoeff};
					VL <= abscoeffa[8:4] + 6; 
				end
				else if (suffixlen==6 && abscoeffa < 480) 
				begin
					VE <= {1'b0, 16'h0000, 2'b01, abscoeffa[4:0], signcoeff};
					VL <= abscoeffa[9:5] + 7; 
				end
				else if (suffixlen==1) 
				begin			//use level 15 with 12bit suffix, VLC1
					VE <= {1'b0, 12'h001, abscoeffa_sum2, signcoeff};
					VL <= 5'b11100;	
				end //15+1+12 = 28 bits
				else if (suffixlen==2) 
				begin			//use level 15 with 12bit suffix, VLC2
					VE <= {1'b0, 12'h001, abscoeffa_sum3, signcoeff};
					VL <= 5'b11100;	
				end //15+1+12 = 28 bits
				else if (suffixlen==3) 
				begin			//use level 15 with 12bit suffix, VLC3
					VE <= {1'b0, 12'h001, abscoeffa_sum4, signcoeff};
					VL <= 5'b11100;	
				end //15+1+12 = 28 bits
				else if (suffixlen==4) 
				begin			//use level 15 with 12bit suffix, VLC4
					VE <= {1'b0, 12'h001, abscoeffa_sum5, signcoeff};
					VL <= 5'b11100; 
				end	//15+1+12 = 28 bits
				else if (suffixlen==5)
				begin			//use level 15 with 12bit suffix, VLC5
					VE <= {1'b0, 12'h001, abscoeffa_sum6, signcoeff};
					VL <= 5'b11100; 
				end	//15+1+12 = 28 bits
				else 
				begin			//use level 15 with 12bit suffix, VLC6
					VE <= {1'b0, 12'h001, abscoeffa_sum7, signcoeff};
					VL <= 5'b11100; 
				end	//15+1+12 = 28 bits
				if ((suffixlen==1 && abscoeff > 3) ||
				   (suffixlen==2 && abscoeff > 6) ||
				   (suffixlen==3 && abscoeff > 12) ||
				   (suffixlen==4 && abscoeff > 24) ||
				   (suffixlen==5 && abscoeff > 48)) 
				begin
					suffixlen <= suffixlen + 1;
				end 
			end 
			if (cindex<=totalcoeffs && totalcoeffs != 0) 
			begin
				VALID <= 1; 
			end
			else 
			begin
				VALID <= 0; 
			end
			
			coeff = coeffarray[{parity,cindex}];
			signcoeff <= coeff[11];
			abscoeff <= coeff[10:0];
			abscoeffa <= coeff[10:0] - 1;
			cindex <= cindex+1;
		end
		// TZEROS
		if (state == STATE_TZEROS) 
		begin
			assert (totalcoeffs!=maxcoeffs && totalcoeffs!=0) else $error;
			VALID <= 1;
			VE <= {20'h00000, 2'b00, ztoken};
			VL <= {1'b0, ztoken_len};
		end
		//
	end 
endmodule