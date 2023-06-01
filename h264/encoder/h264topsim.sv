module h264topsim();

    localparam IMGWIDTH     = 352;
    localparam IMGHEIGHT    = 288;
    localparam MAXFRAMES    = 300;
    localparam MAXQP        = 28;
    localparam IWBITS       = 9;
    localparam IMGBITS      = 8;
    localparam INITQP       = 28;

	// Verbose Switches

	bit computesnr = 1;
	bit dumprecon  = 1;

	// File Handles
    
	integer inb, outb, recb;
	
	// Variables

    integer framenum = 0;
    integer x, y, cx, cy, cuv, i, j, w, count;
    reg [IMGBITS-1:0] c;
	
	// Signals

    logic clk = 0, clk2;

    logic [5:0] qp = INITQP;

    logic [IMGBITS-1:0] yvideo [0:IMGWIDTH-1][0:IMGHEIGHT-1];
    logic [IMGBITS-1:0] uvideo [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];
    logic [IMGBITS-1:0] vvideo [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];

    logic [IMGBITS-1:0] yrvideo [0:IMGWIDTH-1  ][0:IMGHEIGHT-1  ];
    logic [IMGBITS-1:0] urvideo [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];
    logic [IMGBITS-1:0] vrvideo [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];

    // Intra4x4 Wires
    logic top_NEWSLICE = 1'b1;			      
	logic top_NEWLINE = 1'b0;			        
	logic intra4x4_READYI;				
	logic intra4x4_STROBEI = 1'b0;				
	logic [31:0] intra4x4_DATAI;
	logic [31:0] intra4x4_TOPI;
	logic [3:0] intra4x4_TOPMI;
	logic intra4x4_STROBEO;			 
	logic intra4x4_READYO;				
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
    logic intra8x8cc_READYI;
	logic intra8x8cc_STROBEI;				
	logic [31:0] intra8x8cc_DATAI;
	logic [31:0] intra8x8cc_TOPI;
	logic intra8x8cc_STROBEO;
	logic intra8x8cc_READYO = 1'b0;
	logic [35:0] intra8x8cc_DATAO;
	logic [31:0] intra8x8cc_BASEO;
	logic intra8x8cc_DCSTROBEO;			
	logic [15:0] intra8x8cc_DCDATAO;
	logic [1:0] intra8x8cc_CMODEO;
	logic [1:0] intra8x8cc_XXO;
	logic intra8x8cc_XXC;
	logic intra8x8cc_XXINC;

    logic [1:0] header_CMODE = 2'b00;
    logic [19:0] header_VE;
    logic [4:0] header_VL;
    logic header_VALID;

    logic coretransform_READY;
    logic coretransform_ENABLE;
    logic [35:0] coretransform_XXIN;
    logic coretransform_VALID;
    logic [13:0] coretransform_YNOUT;

    logic dctransform_VALID;
    logic [15:0] dctransform_YYOUT;
    logic dctransform_READYO;

    logic quantise_ENABLE;
    logic [15:0] quantise_YNIN;
    logic quantise_VALID;
    logic [11:0] quantise_ZOUT;
    logic quantise_DCCO;

    logic dequantise_ENABLE;
    logic [15:0] dequantise_ZIN;
    logic dequantise_LAST;
    logic dequantise_VALID;
    logic dequantise_DCCO = 1'b0;
    logic [15:0] dequantise_WOUT;

    logic invdctransform_ENABLE;
	logic [15:0] invdctransform_ZIN;
	logic invdctransform_VALID;
	logic [15:0] invdctransform_YYOUT;
	logic invdctransform_READY;

    logic invtransform_VALID;
    logic [39:0] invtransform_XOUT;

    logic recon_BSTROBEI;
    logic [31:0] recon_BASEI;
    logic recon_FBSTROBE;
    logic recon_FBCSTROBE;
    logic [31:0] recon_FEEDB;

    logic xbuffer_NLOAD;
	logic [2:0] xbuffer_NX;
	logic [2:0] xbuffer_NY;	
	logic [1:0] xbuffer_NV;
	logic xbuffer_NXINC;		
	logic xbuffer_READYI;
	logic xbuffer_CCIN;
	logic xbuffer_DONE;

    logic cavlc_ENABLE;
	logic cavlc_READY;
	logic [11:0] cavlc_VIN;
	logic [4:0] cavlc_NIN;
	logic [24:0] cavlc_VE;
	logic [4:0] cavlc_VL;
	logic cavlc_VALID;
	logic [2:0] cavlc_XSTATE;
	logic [4:0] cavlc_NOUT;

    logic tobytes_READY;		
	logic [24:0] tobytes_VE;
	logic [4:0] tobytes_VL;
	logic tobytes_VALID;
	logic [7:0] tobytes_BYTE;
	logic tobytes_STROBE;
	logic tobytes_DONE;

    logic align_VALID = 1'b0;
    logic [5:0] QP = INITQP;

    logic [7:0] ninx = 8'h00;
    logic [4:0] ninl = 5'b00000;
    logic [4:0] nint = 5'b00000;
    logic [5:0] ninsum;

    logic [4:0] ninleft [7:0] = '{default: '0};
    logic [4:0] nintop [2047:0] = '{default: '0};

    logic [31:0] toppix [0:IMGWIDTH-1] = '{default: '0};
    logic [31:0] toppixcc [0:IMGWIDTH-1] = '{default: '0};

    logic [3:0] topmode [0:IMGWIDTH-1] = '{default: '0};

    logic [IWBITS-1:0] mbx = '0;
    logic [IWBITS-1:0] mbxcc = '0;

    logic nop1; //No operation
    logic nop2; //No operation
    logic nop3; //No operation
    logic nop4; //No operation

    // Mode Decision
    integer frame_distance = 3;
    logic pred_type; // 0->I, 1->P
    assign pred_type = ((framenum % (frame_distance + 1)) == 0) ? 0 : 1;

    h264intra4x4 intra4x4
    (
        .CLK(clk2), 
        .NEWSLICE(top_NEWSLICE), 
        .NEWLINE(top_NEWLINE),
        .STROBEI(intra4x4_STROBEI),
        .DATAI(intra4x4_DATAI), 
        .READYI(intra4x4_READYI),
        .TOPI(intra4x4_TOPI), 
        .TOPMI(intra4x4_TOPMI), 
        .XXO(intra4x4_XXO),
        .XXINC(intra4x4_XXINC), 
        .FEEDBI(recon_FEEDB[31:24]), 
        .FBSTROBE(recon_FBSTROBE),
        .STROBEO(intra4x4_STROBEO), 
        .DATAO(intra4x4_DATAO), 
        .BASEO(intra4x4_BASEO),
        .READYO(intra4x4_READYO),
        .MSTROBEO(intra4x4_MSTROBEO),
        .MODEO(intra4x4_MODEO), 
        .PMODEO(intra4x4_PMODEO),
        .RMODEO(intra4x4_RMODEO), 
        .CHREADY(intra4x4_CHREADY)
    );

    assign intra4x4_READYO = coretransform_READY & xbuffer_READYI;
    assign intra4x4_TOPI   = toppix[{mbx, intra4x4_XXO}];
    assign intra4x4_TOPMI  = topmode[{mbx, intra4x4_XXO}];

    h264intra8x8cc intra8x8cc
    (
        .CLK2(clk2),
        .NEWSLICE(top_NEWSLICE), 
        .NEWLINE(top_NEWLINE), 
        .STROBEI(intra8x8cc_STROBEI), 
        .DATAI(intra8x8cc_DATAI), 
        .READYI(intra8x8cc_READYI),
        .TOPI(intra8x8cc_TOPI), 
        .XXO(intra8x8cc_XXO), 
        .XXC(intra8x8cc_XXC),
        .XXINC(intra8x8cc_XXINC), 
        .FEEDBI(recon_FEEDB[31:24]), 
        .FBSTROBE(recon_FBCSTROBE),
        .STROBEO(intra8x8cc_STROBEO), 
        .DATAO(intra8x8cc_DATAO), 
        .BASEO(intra8x8cc_BASEO),
        .READYO(intra4x4_CHREADY), 
        .DCSTROBEO(intra8x8cc_DCSTROBEO), 
        .DCDATAO(intra8x8cc_DCDATAO), 
        .CMODEO(intra8x8cc_CMODEO)
    );

    assign intra8x8cc_TOPI = toppixcc[{mbxcc, intra8x8cc_XXO}];

    h264header header
    (
		.CLK(clk),
		.NEWSLICE(top_NEWSLICE),
        .LASTSLICE(1'b0), //Not Used
		.SINTRA(1'b1),	
		.MINTRA(1'b1) ,
		.LSTROBE(intra4x4_STROBEO),
		.CSTROBE(intra4x4_STROBEO),
		.QP(qp),
		.PMODE(intra4x4_PMODEO),
		.RMODE(intra4x4_RMODEO),
		.CMODE(header_CMODE),
		.PTYPE(2'b00),
		.PSUBTYPE(2'b00),
		.MVDX(12'h000),
		.MVDY(12'h000),
		.VE(header_VE),
		.VL(header_VL),
		.VALID(header_VALID)
	);

    h264coretransform coretransform
    (
        .CLK(clk2), 
        .READY(coretransform_READY), 
        .ENABLE(coretransform_ENABLE),
        .XXIN(coretransform_XXIN), 
        .VALID(coretransform_VALID), 
        .YNOUT(coretransform_YNOUT)
    );

    assign coretransform_ENABLE = intra4x4_STROBEO | intra8x8cc_STROBEO;
	assign coretransform_XXIN = intra4x4_STROBEO ? intra4x4_DATAO : intra8x8cc_DATAO;
	assign recon_BSTROBEI = intra4x4_STROBEO | intra8x8cc_STROBEO;
	assign recon_BASEI = intra4x4_STROBEO ? intra4x4_BASEO : intra8x8cc_BASEO;

    h264dctransform #
    (
        .TOGETHER(1)
    )
    dctransform
    (
        .CLK2(clk2), 
        .RESET(top_NEWSLICE),
        .READYI(nop3),
        .ENABLE(intra8x8cc_DCSTROBEO),
        .XXIN(intra8x8cc_DCDATAO), 
        .VALID(dctransform_VALID), 
        .YYOUT(dctransform_YYOUT),
        .READYO(dctransform_READYO)
    );

    assign dctransform_READYO = (intra4x4_CHREADY & ~coretransform_VALID);

    h264quantise quantise
    (
		.CLK(clk2),
		.ENABLE(quantise_ENABLE), 
		.QP(qp),
		.DCCI(dctransform_VALID),
		.YNIN(quantise_YNIN),
		.ZOUT(quantise_ZOUT),
		.DCCO(quantise_DCCO),
		.VALID(quantise_VALID)
	);

	assign quantise_YNIN = coretransform_VALID ? $signed(coretransform_YNOUT) : $signed(dctransform_YYOUT);
	assign quantise_ENABLE = coretransform_VALID | dctransform_VALID;

    h264dctransform invdctransform
    (
        .CLK2(clk2), 
        .RESET(top_NEWSLICE), 
        .READYI(nop4),
        .ENABLE(invdctransform_ENABLE),
        .XXIN(invdctransform_ZIN), 
        .VALID(invdctransform_VALID), 
        .YYOUT(invdctransform_YYOUT),
        .READYO(invdctransform_READY)
    );

    assign invdctransform_ENABLE = quantise_VALID & quantise_DCCO;
	assign invdctransform_READY = dequantise_LAST & xbuffer_CCIN;
	assign invdctransform_ZIN = $signed(quantise_ZOUT);

    h264dequantise #
    (
        .LASTADVANCE(2)
    )
    h264dequantise
	(
		.CLK(clk2),
		.ENABLE(dequantise_ENABLE),
		.QP(qp),
		.ZIN(dequantise_ZIN),
		.DCCI(invdctransform_VALID),
        .DCCO(nop1),
		.LAST(dequantise_LAST),
		.WOUT(dequantise_WOUT),
		.VALID(dequantise_VALID)
	);

	assign dequantise_ENABLE = quantise_VALID & ~quantise_DCCO;
	assign dequantise_ZIN = !invdctransform_VALID ? $signed(quantise_ZOUT) : $signed(invdctransform_YYOUT);

    h264invtransform invtransform
	(
		.CLK(clk2),
		.ENABLE(dequantise_VALID),
		.WIN(dequantise_WOUT),
		.VALID(invtransform_VALID),
		.XOUT(invtransform_XOUT)
	);

    h264recon recon
    (
        .CLK2(clk2), 
        .NEWSLICE(top_NEWSLICE), 
        .STROBEI(invtransform_VALID), 
        .DATAI(invtransform_XOUT),
        .BSTROBEI(recon_BSTROBEI),
        .BCHROMAI(intra8x8cc_STROBEO), 
        .BASEI(recon_BASEI),
        .STROBEO(recon_FBSTROBE), 
        .CSTROBEO(recon_FBCSTROBE), 
        .DATAO(recon_FEEDB)
    );

    h264buffer xbuffer
    (
        .CLK(clk2), 
        .NEWSLICE(top_NEWSLICE), 
        .NEWLINE(top_NEWLINE), 
        .VALIDI(quantise_VALID),
        .ZIN(quantise_ZOUT), 
        .READYI(xbuffer_READYI), 
        .CCIN(xbuffer_CCIN), 
        .DONE(xbuffer_DONE),
        .VOUT(cavlc_VIN), 
        .VALIDO(cavlc_ENABLE), 
        .NLOAD(xbuffer_NLOAD), 
        .NX(xbuffer_NX),
        .NY(xbuffer_NY), 
        .NV(xbuffer_NV), 
        .NXINC(xbuffer_NXINC), 
        .READYO(cavlc_READY),
        .TREADYO(tobytes_READY), 
        .HVALID(header_VALID) 
    );

    h264cavlc cavlc
    (
        .CLK(clk), 
        .CLK2(clk2), 
        .VS(nop2),
        .ENABLE(cavlc_ENABLE), 
        .READY(cavlc_READY), 
        .VIN(cavlc_VIN),
        .NIN(cavlc_NIN), 
        .SIN(1'b0), 
        .VE(cavlc_VE), 
        .VL(cavlc_VL), 
        .VALID(cavlc_VALID),
        .XSTATE(cavlc_XSTATE), 
        .NOUT(cavlc_NOUT)
    );

    h264tobytes tobytes
    (
        .CLK(clk), 
        .VALID(tobytes_VALID), 
        .READY(tobytes_READY), 
        .VE(tobytes_VE), 
        .VL(tobytes_VL), 
        .BYTE(tobytes_BYTE), 
        .STROBE(tobytes_STROBE), 
        .DONE(tobytes_DONE)
    );

    // Inter-Prediction
    localparam MACRO_DIM  = 16;
    localparam SEARCH_DIM = 48;
    localparam PORT_WIDTH = MACRO_DIM + 1;

    logic        rst_n;
    //logic        clk;
    logic        start;
    logic        en_ram;
    logic        done;
    logic [5:0]  addr;
    logic [5:0]  amt;
    logic [5:0]  mv_y;
    logic [5:0]  mv_x;
    logic [7:0]  pixel_spr_in [0:MACRO_DIM];
    logic [7:0]  pixel_cpr_in [0:MACRO_DIM-1];
    logic [15:0] min_sad;

    logic [15:0] trans_addr [MACRO_DIM:0];

    me # 
    (
        .MACRO_DIM  ( MACRO_DIM  ),
        .SEARCH_DIM ( SEARCH_DIM )
    )
    ins_me
    (
        .rst_n              ( rst_n              ),
        .clk                ( clk2               ),
        .start              ( start              ),
        .pixel_spr_in       ( pixel_spr_in       ),
        .pixel_cpr_in       ( pixel_cpr_in       ),
        .ready              ( ready              ),
        .valid              ( valid              ),
        .en_ram             ( en_ram             ),
        .done               ( done               ),
        .addr               ( addr               ),
        .amt                ( amt                ),
        .mv_x               ( mv_x               ),
        .mv_y               ( mv_y               ),
        .min_sad            ( min_sad            )
    );

   	assign tobytes_VE = header_VALID ? {5'b00000, header_VE} : cavlc_VALID ? cavlc_VE : {1'b0, 24'h030080};
	assign tobytes_VL = header_VALID ? header_VL : cavlc_VALID ? cavlc_VL : 5'b01000;
	assign tobytes_VALID = header_VALID | align_VALID | cavlc_VALID;

    always_ff @(posedge clk2)
    begin
        if (xbuffer_NLOAD)
        begin
			ninleft[xbuffer_NY] <= cavlc_NOUT;
			nintop[{ninx, xbuffer_NX}] <= cavlc_NOUT;
        end
		else
        begin
			ninl <= ninleft[xbuffer_NY];
			nint <= nintop[{ninx, xbuffer_NX}];
		end
		if (top_NEWLINE)
        begin
			ninx <= '0;
        end
		else if (xbuffer_NXINC)
        begin
			ninx <= ninx + 1;
		end
        if (recon_FBSTROBE)
        begin
            toppix[{mbx, intra4x4_XXO}] <= recon_FEEDB;
        end 
        if (intra4x4_MSTROBEO)
        begin
            topmode[{mbx, intra4x4_XXO}] <= intra4x4_MODEO;
        end
        if (top_NEWLINE) 
        begin
            mbx <= '0;
        end
        else if (intra4x4_XXINC) 
        begin
            mbx <= mbx + 1;
        end 
        if (recon_FBCSTROBE)
        begin
            toppixcc[{mbxcc, intra8x8cc_XXO}] <= recon_FEEDB;
        end
        if (top_NEWLINE)
        begin
            mbxcc <= '0;
        end
        else if (intra8x8cc_XXINC) 
        begin
            mbxcc <= mbxcc + 1;
        end
    end

    assign cavlc_NIN = xbuffer_NV==1 ? ninl : xbuffer_NV==2 ? nint : xbuffer_NV==3 ? ninsum[5:1] : '0;
	assign ninsum = {1'b0, ninl} + {1'b0, nint} + 1;

    initial
    begin
        forever 
        begin
            clk2 = 0;
            #5;
            clk2 = 1;
            clk = ~clk;
            #5;
        end
       
    end

    initial
    begin
        inb = $fopen("sample_int.yuv", "rb");

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

            @(posedge clk2);

            framenum++;

            $display("Frame %2d read succesfully", framenum);
            $display("Using QP: %2d", qp);

            top_NEWLINE = 1;
            top_NEWSLICE = 1;
            x = 0;
            y = 0;
            cx = 0;
            cy = 0;
            cuv = 0;

            @(posedge clk2);

            while((y < IMGHEIGHT) || (cy < IMGHEIGHT/2))
            begin
                if (top_NEWLINE)
                begin
                    cx = 0;
                    cy = cy - (cy % 8);
                    cuv = 0;
                end
                if ((intra4x4_READYI) && (y < IMGHEIGHT))
                begin

                    @(posedge clk2);

                    intra4x4_STROBEI = 1;
                    top_NEWLINE = 0;
                    top_NEWSLICE = 0;

                    for (i = 0; i <= 1; i++)
                    begin
                        for (j = 0; j <= 3; j++)
                        begin
                            intra4x4_DATAI = 
                            {
                                yvideo[x+3][y], 
                                yvideo[x+2][y], 
                                yvideo[x+1][y], 
                                yvideo[x][y]
                            };
                            @(posedge clk2);
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
                            $display("Newline pulsed Line: %2d Progress: %2d%%", y, y*100/IMGHEIGHT);
                        end
                    end
                end

                if ((intra8x8cc_READYI == 1) && (cy < IMGHEIGHT/2))
                begin
                    @(posedge clk2);
                    intra8x8cc_STROBEI = 1;
                    for (j = 0; j <= 3; j++)
                    begin
                        for (i = 0; i <= 1; i++)
                        begin
                            if (cuv == 0)
                            begin
                                intra8x8cc_DATAI = 
                                {
                                    uvideo[cx+i*4+3][cy], 
                                    uvideo[cx+i*4+2][cy], 
                                    uvideo[cx+i*4+1][cy], 
                                    uvideo[cx+i*4][cy]
                                };
                            end
                            else
                            begin
                                intra8x8cc_DATAI = 
                                {
                                    vvideo[cx+i*4+3][cy], 
                                    vvideo[cx+i*4+2][cy], 
                                    vvideo[cx+i*4+1][cy], 
                                    vvideo[cx+i*4][cy]
                                };
                            end
                            @(posedge clk2);
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
                @(posedge clk2);
            end  
            // Inter-Prediction
            if (ready == 1)
            begin
                //start = 0;
                integer l, f;
                for(l = 0; l < MACRO_DIM; l++)
                begin
                    if (en_ram)
                    begin
                        pixel_cpr_in[l] = yvideo[l][addr];
                    end
                end
                for(l = 0; l < PORT_WIDTH; l++)
                begin
                    if (en_ram)   
                    begin         
                        pixel_spr_in[l] = yrvideo[(l+amt)%PORT_WIDTH][trans_addr[(l+amt)%PORT_WIDTH]]; 
                    end
                end
                for (f = 0; f < PORT_WIDTH; f++) 
                begin
                    if (f < amt) 
                    begin
                        trans_addr[f] = addr + SEARCH_DIM;
                    end
                    else
                    begin
                        trans_addr[f] = addr;
                    end
                end
                @(posedge clk2);
                start = 1;
            end

            $display("Done push of data into intra4x4 and intra8x8cc");
            if (!xbuffer_DONE)
            begin
                wait (xbuffer_DONE == 1);
            end
            for (w = 1; w <= 32; w++)
            begin
			    @(posedge clk);
            end
            @(posedge clk);
            align_VALID = 1;	
            @(posedge clk);
            align_VALID = 0;
            @(posedge clk);
            $display("Done align at end of NAL");
            if (!tobytes_DONE)
            begin
			    wait (tobytes_DONE == 1);
		    end
            @(posedge clk);
            @(posedge clk);
		end

		$display("%2d frames processed", framenum);

		$fclose(inb);
		$fclose(outb);
		$fclose(recb);

		$finish;

    end

    localparam hd = 200'haa0000000167420028da0582590000000168ce388000000001;
    localparam hdsize = 24;

    initial
    begin
        outb = $fopen("sample_out.264", "wb");

        for (i = hdsize-1; i >= 0; i--)
        begin
            c = hd[ 8*i +: 8 ];
            $fwrite(outb, "%c", c);
        end
        forever
        begin
            if (tobytes_STROBE)
            begin
                $fwrite(outb, "%c", tobytes_BYTE);
                count = count + 1;
            end
            if (tobytes_DONE)
            begin
                count = 0;
                $fwrite(outb, "%c", 8'b00000000);
                $fwrite(outb, "%c", 8'b00000000);
                $fwrite(outb, "%c", 8'b00000000);
                $fwrite(outb, "%c", 8'b00000001);
		    end
		@(posedge clk);
	    end
    end

	always_ff @(posedge clk2)
	begin
		assert (!(header_VALID && cavlc_VALID)) else $error("Two strobes clash.");
		assert (!(coretransform_VALID && dctransform_VALID)) else $error("Two strobes clash.");
		assert (!(intra4x4_STROBEO && intra8x8cc_STROBEO)) else $error("Two strobes clash.");
		assert (!($isunknown(cavlc_VIN)));
	end



	integer xr     = 0; 
	integer yr     = 0;
	integer cxr    = 0;  
	integer cyr    = 0;
	integer cuvr   = 0;
	integer diff   = 0;

	real ssqdiff   = 0.0;
	real sqmaxval  = 255*255;
	real planesize = 0.0;
	real snr       = 0.0;

	initial 
	begin
		recb = $fopen("recon_out.yuv", "wb");
        if(recb)
        begin
            $display("File Opened Successfully");
        end
        else
        begin
            $display("File Opening Failed");
        end
	end

	always_ff @(posedge clk2)
	begin
		if (dumprecon || computesnr)
		begin
			if ( recon_FBSTROBE )
			begin
				yrvideo[xr  ][yr] = recon_FEEDB[ 7: 0];
				yrvideo[xr+1][yr] = recon_FEEDB[15: 8];
				yrvideo[xr+2][yr] = recon_FEEDB[23:16]; 
				yrvideo[xr+3][yr] = recon_FEEDB[31:24];
				yr = yr + 1;
				if (yr % 4 == 0)
				begin
					yr = yr - 4;
					xr = xr + 4;
					if (xr % 8 == 0)
					begin
						xr = xr - 8;
						yr = yr + 4;
						if (yr % 8 == 0)
						begin
							yr = yr - 8;
							xr = xr + 8;
							if (xr % 16 == 0)
							begin
								xr = xr - 16;
								yr = yr + 8;
								if (yr % 16 == 0)
								begin
									yr = yr - 16;
									xr = xr + 16;
									if (xr == IMGWIDTH)
									begin
										xr = 0;
										yr = yr + 16;
									end
								end
							end
						end
					end
				end
			end

			if ( recon_FBCSTROBE )
			begin
				if ( cuvr == 0 )
				begin
					urvideo[cxr  ][cyr] = recon_FEEDB[ 7: 0];
					urvideo[cxr+1][cyr] = recon_FEEDB[15: 8];
					urvideo[cxr+2][cyr] = recon_FEEDB[23:16];
					urvideo[cxr+3][cyr] = recon_FEEDB[31:24];
				end
				else
				begin
					vrvideo[cxr  ][cyr] = recon_FEEDB[ 7: 0];
					vrvideo[cxr+1][cyr] = recon_FEEDB[15: 8];
					vrvideo[cxr+2][cyr] = recon_FEEDB[23:16];
					vrvideo[cxr+3][cyr] = recon_FEEDB[31:24];
				end
				cyr = cyr + 1;
				if (cyr % 4 == 0)
				begin
					cyr = cyr - 4;
					cxr = cxr + 4;
					if (cxr % 8 == 0)
					begin
						cxr = cxr - 8;
						cyr = cyr + 4;
						if (cyr % 8 == 0)
						begin
							cyr  = cyr - 8;
							cuvr = cuvr + 1;
							if (cuvr == 2)
							begin
								cuvr = 0;
								cxr  = cxr + 8;
								if (cxr == IMGWIDTH/2)
								begin
									cxr = 0;
									cyr = cyr + 8;
								end
							end
						end
					end
				end
			end

			if ( ((yr == IMGHEIGHT) && (cyr == IMGHEIGHT/2)) && tobytes_DONE )
			begin

				if (dumprecon)
				begin
					for (yr = 0; yr < IMGHEIGHT; yr++)
					begin
						for (xr = 0; xr < IMGWIDTH; xr++)
						begin
							$fwrite(recb, "%c", yrvideo[xr][yr]);
						end
					end
					for (cyr = 0; cyr < IMGHEIGHT/2; cyr++)
					begin
						for (cxr = 0; cxr < IMGWIDTH/2; cxr++)
						begin
							$fwrite(recb, "%c", urvideo[cxr][cyr]);
						end
					end
					for (cyr = 0; cyr < IMGHEIGHT/2; cyr++)
					begin
						for (cxr = 0; cxr < IMGWIDTH/2; cxr++)
						begin
							$fwrite(recb, "%c", vrvideo[cxr][cyr]);
						end
					end
					$display("%0d bytes written to recon_out.yuv", IMGHEIGHT*IMGWIDTH*3/2);
				end

				if (computesnr)
				begin
					// Y Video SnR Computation

					ssqdiff = 0.0;

					for (yr = 0; yr < IMGHEIGHT; yr++)
					begin
						for (xr = 0; xr < IMGWIDTH; xr++)
						begin
							diff    = yrvideo[xr][yr] - yvideo[xr][yr];
							ssqdiff = diff*diff + ssqdiff;
						end
					end
					
					planesize = IMGHEIGHT*IMGWIDTH;

					if (ssqdiff != 0.0)
					begin
						snr  = 10.0 * $log10(sqmaxval*planesize/ssqdiff);
						$display("SNR Y: %2.3f dB.", snr);
					end
					else
					begin
						$display("SNR Y: %2.3f dB.", 0);
					end

					// U Video SnR Computation

					ssqdiff = 0.0;

					for (cyr = 0; cyr < IMGHEIGHT/2-1; cyr++)
					begin
						for (cxr = 0; cxr < IMGWIDTH/2-1; cxr++)
						begin
							diff    = urvideo[cxr][cyr] - uvideo[cxr][cyr];
							ssqdiff = diff*diff + ssqdiff;
						end
					end
					
					planesize = IMGHEIGHT*IMGWIDTH/4;

					if (ssqdiff != 0.0)
					begin
						snr  = 10.0 * $log10(sqmaxval*planesize/ssqdiff);
						$display("SNR U: %2.3f dB.", snr);
					end
					else
					begin
						$display("SNR U: %2.3f dB.", 0);
					end

					// V Video SnR Computation

					ssqdiff = 0.0;

					for (cyr = 0; cyr < IMGHEIGHT/2-1; cyr++)
					begin
						for (cxr = 0; cxr < IMGWIDTH/2-1; cxr++)
						begin
							diff    = vrvideo[cxr][cyr] - vvideo[cxr][cyr];
							ssqdiff = diff*diff + ssqdiff;
						end
					end
					
					planesize = IMGHEIGHT*IMGWIDTH/4;

					if (ssqdiff != 0.0)
					begin
						snr  = 10.0 * $log10(sqmaxval*planesize/ssqdiff);
						$display("SNR V: %2.3f dB; ", snr);
					end
					else
					begin
						$display("SNR V: %2.3f dB; ", 0);
					end
				end

				xr   = 0;
				yr   = 0;
				cxr  = 0;
				cyr  = 0;
				cuvr = 0;

			end
		end
	end

endmodule