module h264dequantise #
(
    parameter LASTADVANCE = 1
) 
(
    input logic CLK, ENABLE, DCCI,
    input logic [5:0] QP,
    input logic [15:0] ZIN,
    output logic LAST = 1'b0, DCCO = 1'b0, VALID = 1'b0,
    output logic [15:0] WOUT = 16'b0
);

	logic [3:0] zig = 4'hF;
	logic [5:0] qmf = 6'd0;
	logic [4:0] qmfA = 5'd0;
	logic [4:0] qmfB = 5'd0;
	logic [4:0] qmfC = 5'd0;
	logic enab1 = 1'b0;
	logic enab2 = 1'b0;
	logic dcc1 = 1'b0;
	logic dcc2 = 1'b0;
	logic [15:0] z1 = 16'd0;
	logic [22:0] w2 = 23'd0;

  

    always_comb begin    
		// qmfA
        if ({1'b0, QP}==7'd0 || {1'b0, QP}==7'd6 || {1'b0, QP}==7'd12 || {1'b0, QP}==7'd18 || {1'b0, QP}==7'd24 || {1'b0, QP}==7'd30 || {1'b0, QP}==7'd36 || {1'b0, QP}==7'd42 || {1'b0, QP}==7'd48) 
            qmfA = 5'd10;		
        else if ({1'b0, QP}==7'd1 || {1'b0, QP}==7'd7 || {1'b0, QP}==7'd13 || {1'b0, QP}==7'd19 || {1'b0, QP}==7'd25 || {1'b0, QP}==7'd31 || {1'b0, QP}==7'd37 || {1'b0, QP}==7'd43 || {1'b0, QP}==7'd49 )
            qmfA = 5'd11;
        else if ({1'b0, QP}==7'd2 || {1'b0, QP}==7'd8 || {1'b0, QP}==7'd14 || {1'b0, QP}==7'd20 || {1'b0, QP}==7'd26 || {1'b0, QP}==7'd32 || {1'b0, QP}==7'd38 || {1'b0, QP}==7'd44 || {1'b0, QP}==7'd50) 
            qmfA = 5'd13;
        else if ({1'b0, QP}==7'd3 || {1'b0, QP}==7'd9 || {1'b0, QP}==7'd15 || {1'b0, QP}==7'd21 || {1'b0, QP}==7'd27 || {1'b0, QP}==7'd33 || {1'b0, QP}==7'd39 || {1'b0, QP}==7'd45 || {1'b0, QP}==7'd51) 
            qmfA = 5'd14;
		else if ({{1'b0, QP}==7'd4 || {1'b0, QP}==7'd10 || {1'b0, QP}==7'd16 || {1'b0, QP}==7'd22 || {1'b0, QP}==7'd28 || {1'b0, QP}==7'd34 || {1'b0, QP}==7'd40 || {1'b0, QP}==7'd46 })
            qmfA = 5'd16;
        else
		    qmfA = 5'd18;
        
        // qmfB        
        if ({1'b0, QP}==7'd0 || {1'b0, QP}==7'd6 || {1'b0, QP}==7'd12 || {1'b0, QP}==7'd18 || {1'b0, QP}==7'd24 || {1'b0, QP}==7'd30 || {1'b0, QP}==7'd36 || {1'b0, QP}==7'd42 || {1'b0, QP}==7'd48) 
            qmfB = 5'd16;		
        else if ({1'b0, QP}==7'd1 || {1'b0, QP}==7'd7 || {1'b0, QP}==7'd13 || {1'b0, QP}==7'd19 || {1'b0, QP}==7'd25 || {1'b0, QP}==7'd31 || {1'b0, QP}==7'd37 || {1'b0, QP}==7'd43 || {1'b0, QP}==7'd49 )
            qmfB = 5'd18;
        else if ({1'b0, QP}==7'd2 || {1'b0, QP}==7'd8 || {1'b0, QP}==7'd14 || {1'b0, QP}==7'd20 || {1'b0, QP}==7'd26 || {1'b0, QP}==7'd32 || {1'b0, QP}==7'd38 || {1'b0, QP}==7'd44 || {1'b0, QP}==7'd50) 
            qmfB = 5'd20;
        else if ({1'b0, QP}==7'd3 || {1'b0, QP}==7'd9 || {1'b0, QP}==7'd15 || {1'b0, QP}==7'd21 || {1'b0, QP}==7'd27 || {1'b0, QP}==7'd33 || {1'b0, QP}==7'd39 || {1'b0, QP}==7'd45 || {1'b0, QP}==7'd51) 
            qmfB = 5'd23;
		else if ({{1'b0, QP}==7'd4 || {1'b0, QP}==7'd10 || {1'b0, QP}==7'd16 || {1'b0, QP}==7'd22 || {1'b0, QP}==7'd28 || {1'b0, QP}==7'd34 || {1'b0, QP}==7'd40 || {1'b0, QP}==7'd46 })
            qmfB = 5'd25;
        else
		    qmfB = 5'd29;
        
        // qmfC        
        if ({1'b0, QP}==7'd0 || {1'b0, QP}==7'd6 || {1'b0, QP}==7'd12 || {1'b0, QP}==7'd18 || {1'b0, QP}==7'd24 || {1'b0, QP}==7'd30 || {1'b0, QP}==7'd36 || {1'b0, QP}==7'd42 || {1'b0, QP}==7'd48) 
            qmfC = 5'd13;		
        else if ({1'b0, QP}==7'd1 || {1'b0, QP}==7'd7 || {1'b0, QP}==7'd13 || {1'b0, QP}==7'd19 || {1'b0, QP}==7'd25 || {1'b0, QP}==7'd31 || {1'b0, QP}==7'd37 || {1'b0, QP}==7'd43 || {1'b0, QP}==7'd49 )
            qmfC = 5'd14;
        else if ({1'b0, QP}==7'd2 || {1'b0, QP}==7'd8 || {1'b0, QP}==7'd14 || {1'b0, QP}==7'd20 || {1'b0, QP}==7'd26 || {1'b0, QP}==7'd32 || {1'b0, QP}==7'd38 || {1'b0, QP}==7'd44 || {1'b0, QP}==7'd50) 
            qmfC = 5'd16;
        else if ({1'b0, QP}==7'd3 || {1'b0, QP}==7'd9 || {1'b0, QP}==7'd15 || {1'b0, QP}==7'd21 || {1'b0, QP}==7'd27 || {1'b0, QP}==7'd33 || {1'b0, QP}==7'd39 || {1'b0, QP}==7'd45 || {1'b0, QP}==7'd51) 
            qmfC = 5'd18;
		else if ({{1'b0, QP}==7'd4 || {1'b0, QP}==7'd10 || {1'b0, QP}==7'd16 || {1'b0, QP}==7'd22 || {1'b0, QP}==7'd28 || {1'b0, QP}==7'd34 || {1'b0, QP}==7'd40 || {1'b0, QP}==7'd46 })
            qmfC = 5'd20;
        else
		    qmfC = 5'd23;	
	end
    
    always_ff @( posedge CLK ) begin
        if (!ENABLE || DCCI) begin 
			zig <= 4'hF; end
		else begin
			zig <= zig - 1;
		end
		//
		if (zig == LASTADVANCE) begin
			LAST <= 1'b1; end
		else begin
			LAST <= 1'b0; end
		//
		enab1 <= ENABLE;
		enab2 <= enab1;
		VALID <= enab2;
		dcc1 <= DCCI;
		dcc2 <= dcc1;
		DCCO <= dcc2;
		//
		if (ENABLE) begin 
			if (DCCI) 
				//positions 0,0 use table A; x1
				qmf <= {1'b0, qmfA};
			else if (zig == 4'd0 || zig == 4'd3 || zig == 4'd5 || zig == 4'd11 || DCCI==1'b1)  
				//positions 0,0; 0,2; 2,0; 2,2 use table A; x2
				qmf <= {qmfA, 1'b0};
			else if (zig == 4'd4 || zig == 4'd10 || zig == 4'd12 || zig == 4'd15)  
				//positions 1,1; 1,3; 3,1; 3,3 need table B; x2
				qmf <= {qmfB, 1'b0};
			else begin
				//other positions: table C; x2
				qmf <= {qmfC, 1'b0}; end
			z1 <= ZIN;	//data ready for scaling
		end
		if (enab1)  
			w2 <= {{7{z1[15]}}, z1} * {{16{{1'b0, qmf}[6]}}, {1'b0, qmf}};		// quantise

		if (enab2) begin  
			//here apply ">>1" to undo the x2 above, unless DCC where ">>1" needed
			//we don't clip because the stream is guarranteed to fit in 16bits
			//bit(0) is forced to zero in non-DC cases to meet standard
			if ({1'b0, QP} < 7'd6)  
				WOUT <= w2[16:1];
			else if ({1'b0, QP} < 7'd12) 
				WOUT <= {w2[15:1], (w2[0] && dcc2)};
			else if ({1'b0, QP} < 7'd18)  
				WOUT <= {w2[14:1], (w2[0] && dcc2), 1'b0};
			else if ({1'b0, QP} < 7'd24)  
				WOUT <= {w2[13:1], (w2[0] && dcc2), 2'd0};
			else if ({1'b0, QP} < 7'd30)  
				WOUT <= {w2[12:1], (w2[0] && dcc2), 3'd0};
			else if ({1'b0, QP} < 7'd36)  
				WOUT <= {w2[11:1], (w2[0] && dcc2), 4'd0};
			else if ({1'b0, QP} < 7'd42)  
				WOUT <= {w2[10:1], (w2[0] && dcc2), 5'd0};
			else
				WOUT <= {w2[9:1], (w2[0] && dcc2), 6'd0};			
		end        
    end

endmodule