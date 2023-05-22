module h264sim ();

    localparam IMGWIDTH     = 352;
    localparam IMGHEIGHT    = 288;
    localparam IWBITS       = 9;
    localparam IMGBITS      = 8;
    localparam MAXFRAMES    = 10;
    localparam INITQP       = 28;

    logic [IMGBITS-1:0] yvideo [0:IMGWIDTH-1  ][0:IMGHEIGHT-1  ];
    logic [IMGBITS-1:0] uvideo [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];
    logic [IMGBITS-1:0] vvideo [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];

    logic clk = 0, clk2;
    logic start;
    logic rst;

    logic        newslice;
    logic        newline;

    logic [5:0]  qp;

    logic        xbuffer_DONE;

    logic        intra4x4_READYI;
    logic        intra4x4_STROBEI;
    logic [31:0] intra4x4_DATAI;

    logic        intra8x8cc_READYI;
    logic        intra8x8cc_STROBEI;
    logic [31:0] intra8x8cc_DATAI;

    logic [7:0]  tobytes_BYTE;
    logic        tobytes_STROBE;
    logic        tobytes_DONE;

    logic        align_VALID;

    logic [31:0 ] addr_x;
    logic [31:0 ] addr_y;
    logic [31:0 ] addr_cx;
    logic [31:0 ] addr_cy;

    h264topskeleton #
    (
        .IMGWIDTH  ( IMGWIDTH  ),
        .IMGHEIGHT ( IMGHEIGHT ),
        .IWBITS    ( IWBITS    )
    )
    ins_h264topskeleton
    (  
        .clk                ( clk                ),
        .clk2               ( clk2               ),
        .NEWSLICE           ( newslice           ),       
        .NEWLINE            ( newline            ),     
        .qp                 ( qp                 ),
        .xbuffer_DONE       ( xbuffer_DONE       ),
        .intra4x4_READYI    ( intra4x4_READYI    ),   
        .intra4x4_STROBEI   ( intra4x4_STROBEI   ),
        .intra4x4_DATAI     ( intra4x4_DATAI     ),
        .intra8x8cc_READYI  ( intra8x8cc_READYI  ),   
        .intra8x8cc_STROBEI ( intra8x8cc_STROBEI ),
        .intra8x8cc_DATAI   ( intra8x8cc_DATAI   ),
        .tobytes_BYTE       ( tobytes_BYTE       ),
        .tobytes_STROBE     ( tobytes_STROBE     ),
        .tobytes_DONE       ( tobytes_DONE       ),
        .align_VALID        ( align_VALID        )
    );

    h264controller ins_h264controller
    (
        .clk                ( clk                ),
        .clk2               ( clk2               ),
        .start              ( start              ),
        .rst                ( rst                ),
        .newslice           ( newslice           ),       
        .newline            ( newline            ),     
        .xbuffer_DONE       ( xbuffer_DONE       ),
        .intra4x4_READYI    ( intra4x4_READYI    ),   
        .intra4x4_STROBEI   ( intra4x4_STROBEI   ),
        .intra8x8cc_READYI  ( intra8x8cc_READYI  ),   
        .intra8x8cc_STROBEI ( intra8x8cc_STROBEI ),
        .tobytes_STROBE     ( tobytes_STROBE     ),
        .tobytes_DONE       ( tobytes_DONE       ),
        .align_VALID        ( align_VALID        ),
        .x                  ( addr_x             ),
        .y                  ( addr_y             ),
        .cx                 ( addr_cx            ),
        .cy                 ( addr_cy            ),
        .cuv                ( cuv                )
    );

    always_comb
    begin
        intra4x4_DATAI = 
                {
                    yvideo[addr_x+3][addr_y], 
                    yvideo[addr_x+2][addr_y], 
                    yvideo[addr_x+1][addr_y], 
                    yvideo[addr_x+0][addr_y]
                };
        intra8x8cc_DATAI = cuv ?
                {
                    vvideo[addr_cx+3][addr_cy], 
                    vvideo[addr_cx+2][addr_cy], 
                    vvideo[addr_cx+1][addr_cy], 
                    vvideo[addr_cx+0][addr_cy] 
                } : 
                {
                    uvideo[addr_cx+3][addr_cy], 
                    uvideo[addr_cx+2][addr_cy], 
                    uvideo[addr_cx+1][addr_cy], 
                    uvideo[addr_cx+0][addr_cy]
                };
    end

    integer inb, outb;
    integer framenum = 0;
    integer x, y, i;
    reg [IMGBITS-1:0] c;

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
        qp = INITQP;
        rst = 1;
        @(posedge clk);
        rst = 0;
        start = 1;
        #10000;
        $finish;
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

        // while (!$feof(inb) && framenum < MAXFRAMES)
        // begin
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
        end
    // end

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
            end
            if (tobytes_DONE)
            begin
                $fwrite(outb, "%c", 8'b00000000);
                $fwrite(outb, "%c", 8'b00000000);
                $fwrite(outb, "%c", 8'b00000000);
                $fwrite(outb, "%c", 8'b00000001);
		    end
		@(posedge clk);
	    end
    end

    initial 
    begin
        $dumpfile("h264sim.vcd");
        $dumpvars(0, h264sim);
    end

endmodule