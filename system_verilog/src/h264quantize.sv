module h264quantize (
    input logic CLK, ENABLE, DCCI,
    input logic [5:0] QP,
	input logic [15:0] YNIN,
    output logic VALID = 1'b0, DCCO,
    output logic [11:0] ZOUT = 12'd0
);
    logic [3:0] zig = 4'b1111;
	logic [13:0] qmf = 14'd0;
	logic [13:0] qmfA = 14'd0;
	logic [13:0] qmfB = 14'd0;
	logic [13:0] qmfC = 14'd0;
	logic enab1 = 1'b0;
	logic enab2 = 1'b0;
	logic enab3 = 1'b0;
	logic dcc1 = 1'b0;
	logic dcc2 = 1'b0;
	logic dcc3 = 1'b0;
	logic [15:0] yn1;
	logic [30:0] zr;
	logic [15:0] zz;
	logic [2:0] rr;
	//
	//quantisation multiplier factors
	//we need to multiply by PF (to complete transform) and divide by quantisation qstep (ie QP rescaled)
	//so we transform it PF/qstep(QP) to qmf/2^n and do a single multiply
    always_comb begin    
		// qmfA
        if ({1'b0, QP}==7'd0 || {1'b0, QP}==7'd6 || {1'b0, QP}==7'd12 || {1'b0, QP}==7'd18 || {1'b0, QP}==7'd24 || {1'b0, QP}==7'd30 || {1'b0, QP}==7'd36 || {1'b0, QP}==7'd42 || {1'b0, QP}==7'd48) 
            qmfA = 14'd13107;		
        else if ({1'b0, QP}==7'd1 || {1'b0, QP}==7'd7 || {1'b0, QP}==7'd13 || {1'b0, QP}==7'd19 || {1'b0, QP}==7'd25 || {1'b0, QP}==7'd31 || {1'b0, QP}==7'd37 || {1'b0, QP}==7'd43 || {1'b0, QP}==7'd49 )
            qmfA = 14'd11916;
        else if ({1'b0, QP}==7'd2 || {1'b0, QP}==7'd8 || {1'b0, QP}==7'd14 || {1'b0, QP}==7'd20 || {1'b0, QP}==7'd26 || {1'b0, QP}==7'd32 || {1'b0, QP}==7'd38 || {1'b0, QP}==7'd44 || {1'b0, QP}==7'd50) 
            qmfA = 14'd10082;
        else if ({1'b0, QP}==7'd3 || {1'b0, QP}==7'd9 || {1'b0, QP}==7'd15 || {1'b0, QP}==7'd21 || {1'b0, QP}==7'd27 || {1'b0, QP}==7'd33 || {1'b0, QP}==7'd39 || {1'b0, QP}==7'd45 || {1'b0, QP}==7'd51) 
            qmfA = 14'd9362;
		else if ({{1'b0, QP}==7'd4 || {1'b0, QP}==7'd10 || {1'b0, QP}==7'd16 || {1'b0, QP}==7'd22 || {1'b0, QP}==7'd28 || {1'b0, QP}==7'd34 || {1'b0, QP}==7'd40 || {1'b0, QP}==7'd46 })
            qmfA = 14'd8192;
        else
		    qmfA = 14'd7282;
        
        // qmfB        
        if ({1'b0, QP}==7'd0 || {1'b0, QP}==7'd6 || {1'b0, QP}==7'd12 || {1'b0, QP}==7'd18 || {1'b0, QP}==7'd24 || {1'b0, QP}==7'd30 || {1'b0, QP}==7'd36 || {1'b0, QP}==7'd42 || {1'b0, QP}==7'd48) 
            qmfB = 14'd5243;		
        else if ({1'b0, QP}==7'd1 || {1'b0, QP}==7'd7 || {1'b0, QP}==7'd13 || {1'b0, QP}==7'd19 || {1'b0, QP}==7'd25 || {1'b0, QP}==7'd31 || {1'b0, QP}==7'd37 || {1'b0, QP}==7'd43 || {1'b0, QP}==7'd49 )
            qmfB = 14'd4660;
        else if ({1'b0, QP}==7'd2 || {1'b0, QP}==7'd8 || {1'b0, QP}==7'd14 || {1'b0, QP}==7'd20 || {1'b0, QP}==7'd26 || {1'b0, QP}==7'd32 || {1'b0, QP}==7'd38 || {1'b0, QP}==7'd44 || {1'b0, QP}==7'd50) 
            qmfB = 14'd4194;
        else if ({1'b0, QP}==7'd3 || {1'b0, QP}==7'd9 || {1'b0, QP}==7'd15 || {1'b0, QP}==7'd21 || {1'b0, QP}==7'd27 || {1'b0, QP}==7'd33 || {1'b0, QP}==7'd39 || {1'b0, QP}==7'd45 || {1'b0, QP}==7'd51) 
            qmfB = 14'd3647;
		else if ({{1'b0, QP}==7'd4 || {1'b0, QP}==7'd10 || {1'b0, QP}==7'd16 || {1'b0, QP}==7'd22 || {1'b0, QP}==7'd28 || {1'b0, QP}==7'd34 || {1'b0, QP}==7'd40 || {1'b0, QP}==7'd46 })
            qmfB = 14'd3355;
        else
		    qmfB = 14'd2893;
        
        // qmfC        
        if ({1'b0, QP}==7'd0 || {1'b0, QP}==7'd6 || {1'b0, QP}==7'd12 || {1'b0, QP}==7'd18 || {1'b0, QP}==7'd24 || {1'b0, QP}==7'd30 || {1'b0, QP}==7'd36 || {1'b0, QP}==7'd42 || {1'b0, QP}==7'd48) 
            qmfC = 14'd8066;		
        else if ({1'b0, QP}==7'd1 || {1'b0, QP}==7'd7 || {1'b0, QP}==7'd13 || {1'b0, QP}==7'd19 || {1'b0, QP}==7'd25 || {1'b0, QP}==7'd31 || {1'b0, QP}==7'd37 || {1'b0, QP}==7'd43 || {1'b0, QP}==7'd49 )
            qmfC = 14'd7490;
        else if ({1'b0, QP}==7'd2 || {1'b0, QP}==7'd8 || {1'b0, QP}==7'd14 || {1'b0, QP}==7'd20 || {1'b0, QP}==7'd26 || {1'b0, QP}==7'd32 || {1'b0, QP}==7'd38 || {1'b0, QP}==7'd44 || {1'b0, QP}==7'd50) 
            qmfC = 14'd6554;
        else if ({1'b0, QP}==7'd3 || {1'b0, QP}==7'd9 || {1'b0, QP}==7'd15 || {1'b0, QP}==7'd21 || {1'b0, QP}==7'd27 || {1'b0, QP}==7'd33 || {1'b0, QP}==7'd39 || {1'b0, QP}==7'd45 || {1'b0, QP}==7'd51) 
            qmfC = 14'd5825;
		else if ({{1'b0, QP}==7'd4 || {1'b0, QP}==7'd10 || {1'b0, QP}==7'd16 || {1'b0, QP}==7'd22 || {1'b0, QP}==7'd28 || {1'b0, QP}==7'd34 || {1'b0, QP}==7'd40 || {1'b0, QP}==7'd46 })
            qmfC = 14'd5243;
        else
		    qmfC = 14'd4559;
	
	end

    always_ff @(posedge CLK) begin	
		if (!ENABLE || DCCI) begin
			zig <= 4'b1111; end
		else begin
			zig <= zig - 1; end
		//
		enab1 <= ENABLE;
		enab2 <= enab1;
		enab3 <= enab2;
		VALID <= enab3;
		//
		dcc1 <= DCCI;
		dcc2 <= dcc1;
		dcc3 <= dcc2;
		DCCO <= dcc3;
		//
		if (ENABLE) begin
			if (DCCI) begin
				//dc uses 0,0 parameters div 2
				qmf <= {1'b0, qmfA[13:1]}; end
			else if (zig==4'd0 || zig==4'd3 || zig==4'd5 || zig==4'd11) begin
				//positions 0,0; 0,2; 2,0; 2,2 need one set of parameters
				qmf <= qmfA; end
			else if (zig==4'd4 || zig==4'd10 || zig==4'd12 || zig==4'd15) begin
				//positions 1,1; 1,3; 3,1; 3,3 need another set of parameters
				qmf <= qmfB; end
			else begin
				//other positions: default parameters
				qmf <= qmfC; end

			yn1 <= YNIN;	//data ready for scaling
		end 
		if (enab1) begin
			zr <= yn1 * ({1'b0, qmf});		//quantise
		end
		//two bits of rounding (and leading zero)
		//rr := b"010";			//simple round-to-middle
		//rr := b"000";			//no rounding (=> -ve numbers round away from zero)
		rr <= {1'b0, zr[29], 1'b1};	//round to zero if <0.75
		if ( enab2 )  begin
			if ( {1'b0, QP} < 6 )
				zz <= zr[28:13] + rr;
			else if ( {1'b0, QP} < 12)
				zz <= zr[29:14] + rr;
			else if ( {1'b0, QP} < 18 )
				zz <= zr[30:15] + rr;
			else if ( {1'b0, QP} < 24 )
				zz <= {zr[30], zr[30:16] }+ rr;
			else if ( {1'b0, QP} < 30 )  
				zz <= { {2{zr[30]}}, zr[30:17] } + rr;
			else if ( {1'b0, QP} < 36 ) 
				zz <= { {3{zr[30]}}, zr[30:18] } + rr;
			else if ( {1'b0, QP} < 42 ) 
				zz <= { {4{zr[30]}}, zr[30:19] } + rr;
			else
				zz <= { {5{zr[30]}}, zr[30:20] } + rr;
		end 
		if (enab3) begin
			if (zz[15]==zz[14] && zz[15]==zz[13] && zz[13:2]!=12'h800)
				ZOUT <= zz[13:2];
			else if (zz[15]==1'b0 )
				ZOUT <= 12'h7FF;		//clip max
			else
				ZOUT <= 12'h801; 		//clip min
		end
    end
endmodule