// -------------------------------------------------------------------------
// -- H264 dc transform - VHDL
// -- 
// -- Written by Andy Henson
// -- Copyright (c) 2008 Zexia Access Ltd
// -- All rights reserved.
// --

// -- This is the dc transform for H264, without quantisation
// -- this acts on a 2x2 matrix
// -- this is both the forward and inverse transform

// -- both input and output can be in stages, hence RESET input.

// -- XST: 50 slices; 214 MHz


module h264dctransform #
(
	parameter TOGETHER = 0
)
(
	input logic CLK2, 				//--fast clock
	input logic RESET, 				//--reset when 1
	output logic READYI = '0,	       //--set when ready for ENABLE   
	input logic ENABLE,				//--values input only when this is 1
	input logic [15:0] XXIN,	//--input data values (reverse order)
	output logic VALID = '0,				//--values output only when this is 1
	output logic [15:0] YYOUT = '0,	//--output values (reverse order)
	input logic READYO		//--set when ready for ENABLE
);

	//TOGETHER --1 if output kept together as one block
	
	logic [15:0] xxii = 16'd0;
	logic enablei = 1'd0;
	logic [15:0] xx00 = 16'd0;
	logic [15:0] xx01 = 16'd0;
	logic [15:0] xx10 = 16'd0;
	logic [15:0] xx11 = 16'd0;
	logic [1:0] ixx = 2'd0;
	logic iout = 1'd0;
  
always_comb 
begin
	READYI = !(iout);
end
	
always_ff @(posedge CLK2)
begin
	if (RESET== 1'b1) begin
		ixx <= 2'd0;
		iout <= 1'd0;
	end 

	enablei <= ENABLE;
	xxii <= XXIN;

	if (enablei==1'b1 && RESET==1'b0) begin	    //--input in raster scan order
		if (ixx==2'd0) begin
			xx00 <= xxii;
		end
		else if (ixx==2'd1) begin
			xx00 <= xx00 + xxii;	//--compute 2nd stage
			xx01 <= xx00 - xxii;
		end
		else if (ixx== 2'd2) begin
			xx10 <= xxii;
		end
		else begin
			xx10 <= xx10 + xxii;	//--compute 2nd stage
			xx11 <= xx10 - xxii;
			iout <= 1'b1;
		end 
		ixx <= ixx+1;
	end 

	if (iout==1'b1 && (READYO==1'b1 || (TOGETHER==8'd1 && ixx!==0)) && RESET==1'b0) begin
		if (ixx==2'd0)begin
			YYOUT <= xx00 + xx10;	//--out in raster scan order
		end
		else if (ixx==2'd1) begin
			YYOUT <= xx01 + xx11;
		end
		else if (ixx==2'd2) begin
			YYOUT <= xx00 - xx10;
		end
		else begin
			YYOUT <= xx01 - xx11;
			iout <= 1'b0;
		end 
		ixx <= ixx+1;
		VALID <= 1'b1;
	end
	else begin
		VALID <= 1'b0;
	end 
	
end
endmodule





