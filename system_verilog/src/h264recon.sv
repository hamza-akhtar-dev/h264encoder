module h264recon
    (
        input logic CLK2,				// x2 clock
		// in interface:
		input logic NEWSLICE,			// reset
		input logic STROBEI,		    // data here
		input logic [39:0] DATAI,       // 4x10bit
		input logic BSTROBEI,           // base data here
		input logic BCHROMAI,           // set if base is chroma
		input logic [31:0] BASEI,       // 4x8bit
		// out interface:
		output logic STROBEO,	        // data here (luma)
		output logic CSTROBEO,	        // data here (chroma)
		output logic [31:0] DATAO
	);

    logic [31:0] basevec[7:0];
    logic [31:0] basex;
    logic [3:0] basein, baseout;
    logic [9:0] byte0, byte1, byte2, byte3;
    logic strobex, chromax;
    logic [1:0] chromaf;

    initial begin
        STROBEO = 1'd0;
        CSTROBEO = 1'd0;
        DATAO = 32'd0;
        basein = 4'd0;
        baseout = 4'd0;
        byte0 = 8'd0;
        byte1 = 8'd0;
        byte2 = 8'd0;
        byte3 = 8'd0;
        strobex = 1'd0;
        chromax = 1'd0;
        basevec[7] = 32'd0;
        basevec[6] = 32'd0;
        basevec[5] = 32'd0;
        basevec[4] = 32'd0;
        basevec[3] = 32'd0;
        basevec[2] = 32'd0;
        basevec[1] = 32'd0;
        basevec[0] = 32'd0;
    end

    assign basex = basevec[baseout[2:0]];
    
    always@(posedge CLK2) begin

        if (NEWSLICE) begin    // reset
			basein <= 4'd0;
			baseout <= 4'd0;
		end

		// load in base
		if (BSTROBEI && ~NEWSLICE) begin
			basevec[basein[2:0]] <= BASEI;
			chromaf[basein[2]] <= BCHROMAI;
			basein <= basein + 1;
			assert (basein+8 != baseout) else $error("basein wrapped");
        end
		else
			assert (basein[1:0] == 2'b00) else $error("basein not aligned when strobe falls");

        // reconstruct +0: add
        byte0 <= {2'b00, basex[7:0]} + DATAI[9:0];
		byte1 <= {2'b00, basex[15:8]} + DATAI[19:10];
		byte2 <= {2'b00, basex[23:16]} + DATAI[29:20];
		byte3 <= {2'b00, basex[31:24]} + DATAI[39:30];

        chromax = chromaf[baseout[2]];
        strobex <= STROBEI;

        if (STROBEI && ~NEWSLICE) begin
            baseout <= baseout + 1;
            assert (baseout != basein) else $error("baseout wrapped");
        end
        else begin
            assert (baseout[2:0] == 2'b00) else $error("baseout not aligned when strobe falls");
        end

        // reconstruct +1: clip to [0,255]
        if (byte0[9:8] == 2'b01 || byte0[9:7] == 3'b100)
            DATAO[7:0] = 8'hFF;
        else if (byte0[9] && byte0[9:7] != 3'b100)
            DATAO[7:0] = 8'h00;
        else
            DATAO[7:0] = byte0[7:0];
        
        if (byte1[9:8] == 2'b01 || byte1[9:7] == 3'b100)
            DATAO[15:8] = 8'hFF;
        else if (byte1[9] && byte1[9:7] != 3'b100)
            DATAO[15:8] = 8'h00;
        else
            DATAO[15:8] = byte1[7:0];

        if (byte2[9:8] == 2'b01 || byte2[9:7] == 3'b100)
            DATAO[23:16] = 8'hFF;
        else if (byte2[9] && byte2[9:7] != 3'b100)
            DATAO[23:16] = 8'h00;
        else
            DATAO[23:16] = byte2[7:0];

        if (byte3[9:8] == 2'b01 || byte3[9:7] == 3'b100)
            DATAO[31:24] = 8'hFF;
        else if (byte3[9] && byte3[9:7] != 3'b100)
            DATAO[31:24] = 8'h00;
        else
            DATAO[31:24] = byte3[7:0];

        STROBEO <= strobex & (~chromax);
        CSTROBEO <= strobex & chromax;
    end

endmodule