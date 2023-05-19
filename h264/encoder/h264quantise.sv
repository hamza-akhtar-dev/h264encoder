module h264quantise
 (
    input logic CLK, 
	input logic ENABLE, 
	input logic DCCI,
    input logic [5:0] QP,
	input logic [15:0] YNIN,
    output logic VALID = '0, 
	output logic DCCO,
    output logic [11:0] ZOUT = '0
);

    logic [3:0] zig = 4'hf;
	logic [13:0] qmf = '0;
	logic [13:0] qmfA = '0;
	logic [13:0] qmfB = '0;
	logic [13:0] qmfC = '0;
	logic enab1 = '0;
	logic enab2 = '0;
	logic enab3 = '0;
	logic dcc1 = '0;
	logic dcc2 = '0;
	logic dcc3 = '0;
	logic [15:0] yn1;
	logic [30:0] zr;
	logic [15:0] zz;
	//
	//quantisation multiplier factors
	//we need to multiply by PF (to complete transform) and divide by quantisation qstep (ie QP rescaled)
	//so we transform it PF/qstep(QP) to qmf/2^n and do a single multiply


    always_comb 
	begin    
		// qmfA
        if ({1'b0, QP}==7'd0 || {1'b0, QP}==7'd6 || {1'b0, QP}==7'd12 || {1'b0, QP}==7'd18 || {1'b0, QP}==7'd24 || {1'b0, QP}==7'd30 || {1'b0, QP}==7'd36 || {1'b0, QP}==7'd42 || {1'b0, QP}==7'd48) 
		begin
            qmfA = 14'd13107;
		end		
        else if ({1'b0, QP}==7'd1 || {1'b0, QP}==7'd7 || {1'b0, QP}==7'd13 || {1'b0, QP}==7'd19 || {1'b0, QP}==7'd25 || {1'b0, QP}==7'd31 || {1'b0, QP}==7'd37 || {1'b0, QP}==7'd43 || {1'b0, QP}==7'd49)
		begin
            qmfA = 14'd11916;
		end
        else if ({1'b0, QP}==7'd2 || {1'b0, QP}==7'd8 || {1'b0, QP}==7'd14 || {1'b0, QP}==7'd20 || {1'b0, QP}==7'd26 || {1'b0, QP}==7'd32 || {1'b0, QP}==7'd38 || {1'b0, QP}==7'd44 || {1'b0, QP}==7'd50)
		begin 
            qmfA = 14'd10082;
		end
        else if ({1'b0, QP}==7'd3 || {1'b0, QP}==7'd9 || {1'b0, QP}==7'd15 || {1'b0, QP}==7'd21 || {1'b0, QP}==7'd27 || {1'b0, QP}==7'd33 || {1'b0, QP}==7'd39 || {1'b0, QP}==7'd45 || {1'b0, QP}==7'd51)
		begin 
            qmfA = 14'd9362;
		end
		else if ({1'b0, QP}==7'd4 || {1'b0, QP}==7'd10 || {1'b0, QP}==7'd16 || {1'b0, QP}==7'd22 || {1'b0, QP}==7'd28 || {1'b0, QP}==7'd34 || {1'b0, QP}==7'd40 || {1'b0, QP}==7'd46)
		begin
            qmfA = 14'd8192;
		end
        else
		begin
		    qmfA = 14'd7282;
		end
        
        // qmfB        
        if ({1'b0, QP}==7'd0 || {1'b0, QP}==7'd6 || {1'b0, QP}==7'd12 || {1'b0, QP}==7'd18 || {1'b0, QP}==7'd24 || {1'b0, QP}==7'd30 || {1'b0, QP}==7'd36 || {1'b0, QP}==7'd42 || {1'b0, QP}==7'd48)
		begin
            qmfB = 14'd5243;
		end
        else if ({1'b0, QP}==7'd1 || {1'b0, QP}==7'd7 || {1'b0, QP}==7'd13 || {1'b0, QP}==7'd19 || {1'b0, QP}==7'd25 || {1'b0, QP}==7'd31 || {1'b0, QP}==7'd37 || {1'b0, QP}==7'd43 || {1'b0, QP}==7'd49)
		begin
            qmfB = 14'd4660;
		end
        else if ({1'b0, QP}==7'd2 || {1'b0, QP}==7'd8 || {1'b0, QP}==7'd14 || {1'b0, QP}==7'd20 || {1'b0, QP}==7'd26 || {1'b0, QP}==7'd32 || {1'b0, QP}==7'd38 || {1'b0, QP}==7'd44 || {1'b0, QP}==7'd50) 
		begin
            qmfB = 14'd4194;
		end
        else if ({1'b0, QP}==7'd3 || {1'b0, QP}==7'd9 || {1'b0, QP}==7'd15 || {1'b0, QP}==7'd21 || {1'b0, QP}==7'd27 || {1'b0, QP}==7'd33 || {1'b0, QP}==7'd39 || {1'b0, QP}==7'd45 || {1'b0, QP}==7'd51)
		begin
            qmfB = 14'd3647;
		end
		else if ({{1'b0, QP}==7'd4 || {1'b0, QP}==7'd10 || {1'b0, QP}==7'd16 || {1'b0, QP}==7'd22 || {1'b0, QP}==7'd28 || {1'b0, QP}==7'd34 || {1'b0, QP}==7'd40 || {1'b0, QP}==7'd46 })
		begin
            qmfB = 14'd3355;
		end
        else
		begin
		    qmfB = 14'd2893;
		end
        
        // qmfC        
        if ({1'b0, QP}==7'd0 || {1'b0, QP}==7'd6 || {1'b0, QP}==7'd12 || {1'b0, QP}==7'd18 || {1'b0, QP}==7'd24 || {1'b0, QP}==7'd30 || {1'b0, QP}==7'd36 || {1'b0, QP}==7'd42 || {1'b0, QP}==7'd48)
		begin
            qmfC = 14'd8066;
		end
        else if ({1'b0, QP}==7'd1 || {1'b0, QP}==7'd7 || {1'b0, QP}==7'd13 || {1'b0, QP}==7'd19 || {1'b0, QP}==7'd25 || {1'b0, QP}==7'd31 || {1'b0, QP}==7'd37 || {1'b0, QP}==7'd43 || {1'b0, QP}==7'd49)
		begin
            qmfC = 14'd7490;
		end
        else if ({1'b0, QP}==7'd2 || {1'b0, QP}==7'd8 || {1'b0, QP}==7'd14 || {1'b0, QP}==7'd20 || {1'b0, QP}==7'd26 || {1'b0, QP}==7'd32 || {1'b0, QP}==7'd38 || {1'b0, QP}==7'd44 || {1'b0, QP}==7'd50)
		begin
            qmfC = 14'd6554;
		end
        else if ({1'b0, QP}==7'd3 || {1'b0, QP}==7'd9 || {1'b0, QP}==7'd15 || {1'b0, QP}==7'd21 || {1'b0, QP}==7'd27 || {1'b0, QP}==7'd33 || {1'b0, QP}==7'd39 || {1'b0, QP}==7'd45 || {1'b0, QP}==7'd51)
		begin
            qmfC = 14'd5825;
		end
		else if ({{1'b0, QP}==7'd4 || {1'b0, QP}==7'd10 || {1'b0, QP}==7'd16 || {1'b0, QP}==7'd22 || {1'b0, QP}==7'd28 || {1'b0, QP}==7'd34 || {1'b0, QP}==7'd40 || {1'b0, QP}==7'd46 })
		begin
            qmfC = 14'd5243;
		end
        else
		begin
		    qmfC = 14'd4559;
		end
	end

    always_ff @(posedge CLK) 
	begin	
		if (!ENABLE || DCCI) 
		begin
			zig <= 4'hf; 
		end
		else 
		begin
			zig <= zig - 1; 
		end
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
		if (ENABLE) 
		begin
			if (DCCI) 
			begin
				//dc uses 0,0 parameters div 2
				qmf <= {1'b0, qmfA[13:1]}; 
			end
			else if (zig==4'd0 || zig==4'd3 || zig==4'd5 || zig==4'd11)
			begin
				//positions 0,0; 0,2; 2,0; 2,2 need one set of parameters
				qmf <= qmfA; 
			end
			else if (zig==4'd4 || zig==4'd10 || zig==4'd12 || zig==4'd15) 
			begin
				//positions 1,1; 1,3; 3,1; 3,3 need another set of parameters
				qmf <= qmfB; 
			end
			else 
			begin
				//other positions: default parameters
				qmf <= qmfC; 
			end
			yn1 <= YNIN;	//data ready for scaling
		end 
		if (enab1) 
		begin
			zr <= {{15{yn1[15]}}, yn1} * {{16{{1'b0, qmf}[14]}}, {1'b0, qmf}};		//sign extension before multiplying 
		end
		//two bits of rounding (and leading zero)
		//rr := b"010";			//simple round-to-middle
		//rr := b"000";			//no rounding (=> -ve numbers round away from zero)

		if (enab2)  
		begin
			if ({1'b0, QP} < 6)
			begin
				zz <= zr[28:13] + {1'b0, zr[29], 1'b1};
			end
			else if ({1'b0, QP} < 12)
			begin
				zz <= zr[29:14] + {1'b0, zr[29], 1'b1};
			end
			else if ({1'b0, QP} < 18)
			begin
				zz <= zr[30:15] + {1'b0, zr[29], 1'b1};
			end
			else if ({1'b0, QP} < 24)
			begin
				zz <= {zr[30], zr[30:16] } + {1'b0, zr[29], 1'b1};
			end
			else if ({1'b0, QP} < 30)  
			begin
				zz <= { {2{zr[30]}}, zr[30:17] } + {1'b0, zr[29], 1'b1};
			end
			else if ({1'b0, QP} < 36) 
			begin
				zz <= { {3{zr[30]}}, zr[30:18] } + {1'b0, zr[29], 1'b1};
			end
			else if ({1'b0, QP} < 42) 
			begin
				zz <= { {4{zr[30]}}, zr[30:19] } + {1'b0, zr[29], 1'b1};
			end
			else
			begin
				zz <= { {5{zr[30]}}, zr[30:20] } + {1'b0, zr[29], 1'b1};
			end
		end
		
		if (enab3) 
		begin
			if ((zz[15]==zz[14]) && (zz[15]==zz[13]) && (zz[13:2]!=12'h800))
			begin
				ZOUT <= zz[13:2];
			end
			else if (zz[15]==1'b0 )
			begin
				ZOUT <= 12'h7FF;		//clip max
			end
			else
			begin
				ZOUT <= 12'h801; 		//clip min
			end
		end
    end
endmodule