module h264sim ();

    localparam IMGWIDTH     = 352;
    localparam IMGHEIGHT    = 288;
    localparam IWBITS       = 9;
    localparam IMGBITS      = 8;
    localparam MAXFRAMES    = 10;
    localparam INITQP       = 28;

    logic clk = 0, clk2;

    logic        newslice = 1;
    logic        newline  = 0;

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

    xpm_memory_spram #
    (
         .ADDR_WIDTH_A(6),              // DECIMAL
         .AUTO_SLEEP_TIME(0),           // DECIMAL
         .BYTE_WRITE_WIDTH_A(32),       // DECIMAL
         .ECC_MODE("no_ecc"),           // String
         .MEMORY_INIT_FILE("instruction_mem.mem"),     // String
         .MEMORY_INIT_PARAM("0"),       // String
         .MEMORY_OPTIMIZATION("true"),  // String
         .MEMORY_PRIMITIVE("block"),     // String
         .MEMORY_SIZE(2048),            // DECIMAL
         .MESSAGE_CONTROL(0),           // DECIMAL
         .READ_DATA_WIDTH_A(32),        // DECIMAL
         .READ_LATENCY_A(1),            // DECIMAL
         .READ_RESET_VALUE_A("0"),      // String
         .USE_MEM_INIT(1),              // DECIMAL
         .WAKEUP_TIME("disable_sleep"), // String
         .WRITE_DATA_WIDTH_A(32),       // DECIMAL
         .WRITE_MODE_A("read_first")    // String
      )
      xpm_memory_spram_inst 
      (
         .dbiterra(dbiterra),             // 1-bit output: Status signal to indicate double bit error occurrence
                                          // on the data output of port A.
    
         .douta(Instruction),                   // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
         .sbiterra(sbiterra),             // 1-bit output: Status signal to indicate single bit error occurrence
                                          // on the data output of port A.
    
         .addra(PC_next[5:0]/4),                   // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
         .clka(clk),                     // 1-bit input: Clock signal for port A.
         .dina(dina),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
         .ena(1'b1),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                          // cycles when read or write operations are initiated. Pipelined
                                          // internally.
    
         .injectdbiterra(injectdbiterra), // 1-bit input: Controls double bit error injection on input data when
                                          // ECC enabled (Error injection capability is not available in
                                          // "decode_only" mode).
    
         .injectsbiterra(injectsbiterra), // 1-bit input: Controls single bit error injection on input data when
                                          // ECC enabled (Error injection capability is not available in
                                          // "decode_only" mode).
    
         .regcea(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                          // data path.
    
         .rsta(rsta),                     // 1-bit input: Reset signal for the final port A output register stage.
                                          // Synchronously resets output port douta to the value specified by
                                          // parameter READ_RESET_VALUE_A.
    
         .sleep(sleep),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
         .wea(1'b0)                        // WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input
                                          // data port dina. 1 bit wide when word-wide writes are used. In
                                          // byte-wide write configurations, each bit controls the writing one
                                          // byte of dina to address addra. For example, to synchronously write
                                          // only bits [15-8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be
                                          // 4'b0010.
        );

    logic [IMGBITS-1:0] yvideo [0:IMGWIDTH-1  ][0:IMGHEIGHT-1  ];
    logic [IMGBITS-1:0] uvideo [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];
    logic [IMGBITS-1:0] vvideo [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];

    integer framenum = 0;
    integer inb, outb;
    integer x, y, cx, cy, cuv, i, j, w;
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

            newline  = 1;
            newslice = 1;
            x = 0;
            y = 0;
            cx = 0;
            cy = 0;
            cuv = 0;

            @(posedge clk2);

            while((y < IMGHEIGHT) || (cy < IMGHEIGHT/2))
            begin
                if (newline)
                begin
                    cx = 0;
                    cy = cy - (cy % 8);
                    cuv = 0;
                end
                if ((intra4x4_READYI) && (y < IMGHEIGHT))
                begin

                    @(posedge clk2);

                    intra4x4_STROBEI = 1;
                    newline          = 0;
                    newslice         = 0;

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
                            newline = 1;
                            $display("Newline pulsed Line: %2d Progress: %2d%%", y, y*100/IMGHEIGHT);
                        end
                    end
                end

                if (intra8x8cc_READYI == 1 && cy < IMGHEIGHT/2)
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

    // initial 
    // begin
    //     $dumpfile("h264sim.vcd");
    //     $dumpvars(0, h264sim);
    // end

endmodule