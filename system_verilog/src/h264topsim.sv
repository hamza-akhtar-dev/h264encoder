module h264topsim();

    localparam IMGWIDTH     = 352;
    localparam IMGHEIGHT    = 288;
    localparam MAXFRAMES    = 1;
    localparam MAXQP        = 28;
    localparam IWBITS       = 9;
    localparam IMGBITS      = 8;

    integer inb;
    integer framenum = 0;
    integer x, y, cx, cy, cuv, i, j;

    reg[IMGBITS-1:0] c;

    logic clk;

    logic [IMGBITS-1:0] yvideo [0:IMGWIDTH-1][0:IMGHEIGHT-1];
    logic [IMGBITS-1:0] uvideo [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];
    logic [IMGBITS-1:0] vvideo [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];

    // Intra4x4 Wires
    logic top_NEWSLICE = 1'b1;			      
	logic top_NEWLINE = 1'b0;			        
	logic intra4x4_READYI = 1'b1;				
	logic intra4x4_STROBEI = 1'b0;				
	logic [31:0] intra4x4_DATAI = 32'd0;
	logic [31:0] intra4x4_TOPI = 32'd0;
	logic [3:0] intra4x4_TOPMI = 4'd0;
	logic intra4x4_STROBEO;			 
	logic intra4x4_READYO = 1'b0;				
	logic [35:0] intra4x4_DATAO;
	logic [31:0] intra4x4_BASEO;
	logic intra4x4_MSTROBEO;		       	
	logic [3:0] intra4x4_MODEO;	       
	logic intra4x4_PMODEO;              
	logic [2:0] intra4x4_RMODEO;	      
	logic [1:0] intra4x4_XXO;
	logic intra4x4_XXINC;
	logic intra4x4_CHREADY;

    //Intra8x8cc Wires
    logic intra8x8cc_READYI = 1;
	logic intra8x8cc_STROBEI = 0;				
	logic [31:0] intra8x8cc_DATAI = 0;
	logic [31:0] intra8x8cc_TOPI = 0;
	logic intra8x8cc_STROBEO = 0;
	logic intra8x8cc_READYO = 0;
	logic [35:0] intra8x8cc_DATAO = 0;
	logic [31:0] intra8x8cc_BASEO = 0;
	logic intra8x8cc_DCSTROBEO= 0;			
	logic [15:0] intra8x8cc_DCDATA0 = 0;
	logic [1:0] intra8x8cc_CMODEO = 0;
	logic [1:0] intra8x8cc_XXO = 0;
	logic intra8x8cc_XXC = 0;
	logic intra8x8cc_XXINC = 0;

    // Recon Wires
    logic recon_FBSTROBE;
    logic [31:0] recon_FEEDB;

    // Xbuffer Wires
    logic xbuffer_DONE;




    // h264intra4x4 intra4x4
    // (
    //     .CLK(clk), 
    //     .NEWSLICE(top_NEWSLICE), 
    //     .NEWLINE(top_NEWLINE),
    //     .STROBEI(intra4x4_STROBEI),
    //     .DATAI(intra4x4_DATAI), 
    //     //.READYI(intra4x4_READYI),
    //     .TOPI(intra4x4_TOPI), 
    //     .TOPMI(intra4x4_TOPMI), 
    //     .XXO(intra4x4_XXO),
    //     .XXINC(intra4x4_XXINC), 
    //     .FEEDBI(recon_FEEDB[31:24]), 
    //     .FBSTROBE(recon_FBSTROBE),
    //     .STROBEO(intra4x4_STROBEO), 
    //     .DATAO(intra4x4_DATAO), 
    //     .BASEO(intra4x4_BASEO),
    //     .READYO(intra4x4_READYO),
    //     .MSTROBEO(intra4x4_MSTROBEO),
    //     .MODEO(intra4x4_MODEO), 
    //     .PMODEO(intra4x4_PMODEO),
    //     .RMODEO(intra4x4_RMODEO), 
    //     .CHREADY(intra4x4_CHREADY)
    // );

    // assign intra4x4_readyo = coretransform_ready & xbuffer_readyi;
    // assign intra4x4_TOPI   = toppix(conv_integer(mbx & intra4x4_XXO));
    // assign intra4x4_TOPMI  = topmode(conv_integer(mbx & intra4x4_XXO));

    // h264intra8x8cc intra8x8cc
    // (
    //     .CLK2(CLK2), 
    //     .NEWSLICE(top_NEWSLICE), 
    //     .NEWLINE(top_NEWLINE), 
    //     .STROBEI(intra8x8cc_strobei), 
    //     .DATAI(intra8x8cc_datai), 
    //     .READYI(intra8x8cc_readyi),
    //     .TOPI(intra8x8cc_topi), 
    //     .XXO(intra8x8cc_xxo), 
    //     .XXC(intra8x8cc_xxc),
    //     .XXINC(intra8x8cc_xxinc), 
    //     .FEEDBI(recon_FEEDB[31:24]), 
    //     .FBSTROBE(recon_FBSTROBE),
    //     .STROBEO(intra8x8cc_strobeo), 
    //     .DATAO(intra8x8cc_datao), 
    //     .BASEO(intra8x8cc_baseo),
    //     .READYO(intra4x4_CHREADY), 
    //     .DCSTROBEO(intra8x8cc_dcstrobeo), 
    //     .DCDATAO(intra8x8cc_dcdatao), 
    //     .CMODEO(intra8x8cc_cmodeo)
    // );

    // assign intra8x8cc_TOPI = toppixcc(conv_integer(mbxcc & intra8x8cc_XXO));

    // h264header header
    // (
	// 	.CLK(clk),
	// 	.NEWSLICE(top_NEWSLICE),
	// 	.SINTRA(1'b1),	
	// 	.MINTRA(1'b1) ,
	// 	.LSTROBE(intra4x4_strobe),
	// 	.CSTROBE(intra4x4_strobeo),
	// 	.QP(qp),
	// 	.PMODE(intra4x4_PMODEO),
	// 	.RMODE(intra4x4_RMODEO),
	// 	.CMODE(header_cmode),
	// 	.PTYPE(2'b00),
	// 	.PSUBTYPE(2'b00),
	// 	.MVDX(3'b000),
	// 	.MVDY(3'b000),
	// 	.VE(header_ve),
	// 	.VL(header_vl),
	// 	.VALID(header_valid)
	// );

    // h264coretransform coretransform
    // (
    //     .CLK(CLK2), 
    //     .READY(coretransform_ready), 
    //     .ENABLE(coretransform_enable),
    //     .XXIN(coretransform_xxin), 
    //     .VALID(coretransform_valid), 
    //     .YNOUT(coretransform_ynout)
    // );

    // // coretransform_enable = (intra4x4_strobeo | intra8x8cc_strobeo);
	// // coretransform_xxin = intra4x4_datao when intra4x4_strobeo='1' else intra8x8cc_datao;
	// // recon_bstrobei = intra4x4_strobeo or intra8x8cc_strobeo;
	// // recon_basei = intra4x4_baseo when intra4x4_strobeo='1' else intra8x8cc_baseo;

    // h264dctransform dctransform
    // (
    //     .CLK2(CLK2), 
    //     .RESET(top_newslice), 
    //     .ENABLE(intra8x8cc_dcstrobeo),
    //     .XXIN(intra8x8cc_dcdatao), 
    //     .VALID(dctransform_valid), 
    //     .YNOUT(dctransform_yyout),
    //     .READYO(dctransform_readyo)
    // );

    // assign dctransform_readyo = (intra4x4_CHREADY & (!coretransform_valid));

    // h264quantize quantize
    // (
	// 	.CLK(clk2),
	// 	.ENABLE(quantise_ENABLE), 
	// 	.QP(qp),
	// 	.DCCI(dctransform_VALID),
	// 	.YNIN(quantise_YNIN),
	// 	.ZOUT(quantise_zout),
	// 	.DCCO(quantise_dcco),
	// 	.VALID(quantise_valid)
	// );

	// // assign quantise_YNIN = sxt(coretransform_ynout,16) when coretransform_valid='1' else dctransform_yyout;
	// // assign quantise_ENABLE = coretransform_valid or dctransform_VALID;


    // h264invtransform invdctransform
    // (
    //     .CLK2(CLK2), 
    //     .RESET(top_newslice), 
    //     .ENABLE(invdctransform_enable),
    //     .XXIN(invdctransform_zin), 
    //     .VALID(invdctransform_valid), 
    //     .YYOUT(invdctransform_yyout),
    //     .READYO(invdctransform_ready)
    // );

    // // assign invdctransform_enable = quantise_valid and quantise_dcco;
	// // assign invdctransform_ready = dequantise_last and xbuffer_CCIN;
	// // assign invdctransform_zin = sxt(quantise_zout,16);

    // h264dequantize h264dequantize
	// (
	// 	.CLK(clk2),
	// 	.ENABLE(dequantise_enable),
	// 	.QP(qp),
	// 	.ZIN(dequantise_zin),
	// 	.DCCI(invdctransform_valid),
	// 	.LAST(dequantise_last),
	// 	.WOUT(dequantise_wout),
	// 	.VALID(dequantise_valid)
	// );

	// // dequantise_enable <= quantise_valid and not quantise_dcco;
	// // dequantise_zin <= sxt(quantise_zout,16) when invdctransform_valid='0' else invdctransform_yyout;

    // h264intransform invtransform
	// (
	// 	.CLK(clk2),
	// 	.ENABLE(dequantise_valid),
	// 	.WIN(dequantise_wout),
	// 	.VALID(invtransform_valid),
	// 	.XOUT(invtransform_xout)
	// );


    // h264recon recon
    // (
    //     .CLK2(CLK2), 
    //     .NEWSLICE(top_NEWSLICE), 
    //     .STROBEI(invtransform_valid), 
    //     .DATAI(invtransform_xout),
    //     .BSTROBEI(recon_bstrobei),
    //     .BCHROMAI(intra8x8cc_strobeo), 
    //     .BASEI(recon_basei),
    //     .STROBEO(recon_FBSTROBE), 
    //     .CSTROBEO(recon_FBCSTROBE), 
    //     .DATAO(recon_FEEDB)
    // );

    // h264buffer xbuffer
    // (
    //     .CLK(CLK2), 
    //     .NEWSLICE(top_NEWSLICE), 
    //     .NEWLINE(top_NEWLINE), 
    //     .VALIDI(quantise_valid),
    //     .ZIN(quantise_zout), 
    //     .READYI(xbuffer_READYI), 
    //     .CCIN(xbuffer_CCIN), 
    //     .DONE(xbuffer_DONE),
    //     .VOUT(cavlc_vin), 
    //     .VALIDO(cavlc_enable), 
    //     .NLOAD(xbuffer_NLOAD), 
    //     .NX(xbuffer_NX),
    //     .NY(xbuffer_NY), 
    //     .NV(xbuffer_NV), 
    //     .NXINC(xbuffer_NXINC), 
    //     .READYO(cavlc_ready),
    //     .TREADYO(tobytes_ready), 
    //     .HVALID(header_valid) 
    // );

    // h264cavlc cavlc
    // (
    //     .CLK(CLK), 
    //     .CLK2(CLK2), 
    //     .ENABLE(cavlc_enable), 
    //     .READY(cavlc_ready), 
    //     .VIN(cavlc_vin),
    //     .NIN(cavlc_nin), 
    //     .SIN(1'b0), 
    //     .VE(cavlc_ve), 
    //     .VL(cavlc_vl), 
    //     .VALID(cavlc_valid),
    //     .XSTATE(cavlc_xstate), 
    //     .NOUT(cavlc_nout)
    // );

    // h264tobytes tobytes
    // (
    //     .CLK(CLK), 
    //     .VALID(tobytes_valid), 
    //     .READY(tobytes_ready), 
    //     .VE(tobytes_ve), 
    //     .VL(tobytes_vl), 
    //     .BYTE(tobytes_byte), 
    //     .STROBE(tobytes_strobe), 
    //     .DONE(tobytes_DONE)
    // );

   	// // assign tobytes_ve = b"00000"&header_ve when header_valid='1' else
	// // 				cavlc_ve when cavlc_valid='1' else
	// // 				'0'&x"030080";
	// // assign tobytes_vl = header_vl when header_valid='1' else
	// // 				cavlc_vl when cavlc_valid='1' else
	// // 				b"01000";			--8 bits (1 + 7 for align)
	// // assign tobytes_valid = header_valid or align_VALID or cavlc_valid;

    initial 
    begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial
    begin
        inb = $fopen("test_video.yuv", "rb");

        if(inb)
        begin
            $display("File Opened Successfully");
        end
        else
        begin
            $display("File Opening Failed");
        end

        while (!$feof(inb) && framenum < MAXFRAMES)
        begin
            for (y = 0; y < IMGHEIGHT; y++)
            begin
                for(x = 0; x < IMGWIDTH; x++)
                begin
                    $fread(c, inb); 
                    yvideo[x][y] = c;
                end
            end

            for (y = 0; y < IMGHEIGHT/2; y++)
            begin
                for(x = 0; x < IMGWIDTH/2; x++)
                begin
                    $fread(c, inb);
                    uvideo[x][y] = c;
                end
            end

            for (y = 0; y < IMGHEIGHT/2; y++)
            begin
                for(x = 0; x < IMGWIDTH/2; x++)
                begin
                    $fread(c, inb);
                    vvideo[x][y] = c;
                end
            end

            framenum++;

            $display("Frame %d Succesfully", framenum);

            top_NEWLINE = 1;
            top_NEWSLICE = 1;
            x = 0;
            y = 0;
            cx = 0;
            cy = 0;
            cuv = 0;

            while((y < IMGHEIGHT) || (cy < IMGHEIGHT/2))
            begin
                if (top_NEWLINE == 1)
                begin
                    cx = 0;
                    cy = cy - (cy % 8);
                    cuv = 0;
                end
                if ((intra4x4_READYI == 1) && (y < IMGHEIGHT))
                begin
                    //$display("Entered 4x4-Block");
                    @(posedge clk);
                    intra4x4_STROBEI = 1;
                    top_NEWLINE = 0;
                    top_NEWSLICE = 0;
                    for (i = 0; i <= 1; i++)
                    begin
                        for (j = 0; j <= 3; j++)
                        begin
                            intra4x4_DATAI = {yvideo[x+3][y], yvideo[x+2][y], yvideo[x+1][y], yvideo[x][y]};
                            @(posedge clk);
                            x = x + 4;
                        end
                        x = x - 16;	
                        y = y + 1;
                    end
                    intra4x4_STROBEI = 0;
                    if ((y % 16) == 0)
                    begin
                        x = x + 16;
                        y = y - 16;			
                        if (x == IMGWIDTH)
                        begin
                            x = 0;			
                            y = y + 16;
                            if (xbuffer_DONE == 0)
                            begin
                                wait (xbuffer_DONE == 1);
                            end
                            top_NEWLINE = 1;
                        end
                    end
                end

                if (intra8x8cc_READYI == 1 && cy < IMGHEIGHT/2)
                begin
                    //$display("Entered 8x8cc-Block");
                    @(posedge clk);
                    intra8x8cc_STROBEI = 1;
                    for (j = 0; j < 3; j++)
                    begin
                        for (i = 0; i < 1; i++)
                        begin
                            if (cuv == 0)
                            begin
                                intra8x8cc_DATAI = {uvideo[cx+i*4+3][cy], uvideo[cx+i*4+2][cy], uvideo[cx+i*4+1][cy], uvideo[cx+i*4][cy]};
                            end
                            else
                            begin
                                intra8x8cc_DATAI = {vvideo[cx+i*4+3][cy], vvideo[cx+i*4+2][cy], vvideo[cx+i*4+1][cy], vvideo[cx+i*4][cy]};
                            end
                            @(posedge clk);
                        end
                        cy = cy + 1;
                    end
                    intra8x8cc_STROBEI = 0;
                    if ((cy % 8) == 0) 
                    begin
                        if (cuv == 0) 
                        begin
                            cy = cy-8;
                            cuv = 1;
                        end
                        else
                        begin
                            cuv = 0;
                            cy = cy - 8;
                            cx = cx + 8;
                            if (cx == IMGWIDTH/2)
                            begin
                                cx = 0;	
                                cy = cy + 8;
                            end
                        end
                    end
                end
            end
        end
        
        $writememh("yvideo.mem", yvideo);
        $writememh("uvideo.mem", uvideo);
        $writememh("vvideo.mem", vvideo);

        $finish;
    end

endmodule