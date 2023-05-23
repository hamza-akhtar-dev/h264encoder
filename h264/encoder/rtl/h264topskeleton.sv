module h264topskeleton #
(
	parameter integer IMGWIDTH  = 352,
    parameter integer IMGHEIGHT = 288,
    parameter integer IWBITS    = 9
)
(
	input logic clk, 
	input logic clk2,   

	input logic         NEWSLICE,       
	input logic         NEWLINE,     
	input logic  [5:0]  qp,
	output logic        xbuffer_DONE, 
 
	output logic        intra4x4_READYI,   
	input  logic        intra4x4_STROBEI,
	input  logic [31:0] intra4x4_DATAI,
	output logic        intra8x8cc_READYI,   
	input  logic        intra8x8cc_STROBEI,
	input  logic [31:0] intra8x8cc_DATAI,
 
	output logic [7:0]  tobytes_BYTE,
	output logic        tobytes_STROBE, 
	output logic        tobytes_DONE,
	
	input  logic        align_VALID 
);

	logic [31:0] intra4x4_TOPI;
	logic [3:0]  intra4x4_TOPMI;
	logic        intra4x4_STROBEO;
	logic        intra4x4_READYO;
	logic [35:0] intra4x4_DATAO;
	logic [31:0] intra4x4_BASEO;
	logic        intra4x4_MSTROBEO;
	logic [3:0]  intra4x4_MODEO;
	logic        intra4x4_PMODEO;
	logic [2:0]  intra4x4_RMODEO;
	logic [1:0]  intra4x4_XXO;
	logic        intra4x4_XXINC;
	logic        intra4x4_CHREADY;

	logic [31:0] intra8x8cc_TOPI;
	logic        intra8x8cc_STROBEO;
	logic        intra8x8cc_READYO;
	logic [35:0] intra8x8cc_DATAO;
	logic [31:0] intra8x8cc_BASEO;
	logic        intra8x8cc_DCSTROBEO;
	logic [15:0] intra8x8cc_DCDATAO;
	logic [1:0]  intra8x8cc_CMODEO;
	logic [1:0]  intra8x8cc_XXO;
	logic        intra8x8cc_XXC;
	logic        intra8x8cc_XXINC;

	logic [1:0]  header_CMODE = 2'b00;
	logic [19:0] header_VE;
	logic [4:0]  header_VL;
	logic        header_VALID;

	logic        coretransform_READY;
	logic        coretransform_ENABLE;
	logic [35:0] coretransform_XXIN;
	logic        coretransform_VALID;
	logic [13:0] coretransform_YNOUT;

	logic        dctransform_VALID;
	logic [15:0] dctransform_YYOUT;
	logic        dctransform_READYO;

	logic        quantise_ENABLE;
	logic [15:0] quantise_YNIN;
	logic        quantise_VALID;
	logic [11:0] quantise_ZOUT;
	logic        quantise_DCCO;

	logic        dequantise_ENABLE;
	logic [15:0] dequantise_ZIN;
	logic        dequantise_LAST;
	logic        dequantise_VALID;
	logic        dequantise_DCCO = 1'b0;
	logic [15:0] dequantise_WOUT;

	logic        invdctransform_ENABLE;
	logic [15:0] invdctransform_ZIN;
	logic        invdctransform_VALID;
	logic [15:0] invdctransform_YYOUT;
	logic        invdctransform_READY;

	logic        invtransform_VALID;
	logic [39:0] invtransform_XOUT;

	logic        recon_BSTROBEI;
	logic [31:0] recon_BASEI;
	logic        recon_FBSTROBE;
	logic        recon_FBCSTROBE;
	logic [31:0] recon_FEEDB;

	logic        xbuffer_NLOAD;
	logic [2:0]  xbuffer_NX;        
	logic [2:0]  xbuffer_NY;        
	logic [1:0]  xbuffer_NV;        
	logic        xbuffer_NXINC;
	logic        xbuffer_READYI;
	logic        xbuffer_CCIN;

	logic      cavlc_ENABLE;       
	logic      cavlc_READY;  
	logic [11:0] cavlc_VIN; 
	logic [4:0]  cavlc_NIN;     
	logic [24:0] cavlc_VE;
	logic [4:0]  cavlc_VL;
	logic        cavlc_VALID;      
	logic [2:0]  cavlc_XSTATE;
	logic [4:0]  cavlc_NOUT; 

	logic        tobytes_READY;                   
	logic [24:0] tobytes_VE;
	logic [4:0]  tobytes_VL;
	logic        tobytes_VALID;
  
	//logic        align_VALID;
  
	logic [7:0] ninx;
	logic [4:0] ninl;        
	logic [4:0] nint;      
	logic [5:0] ninsum;       
             
	logic [4:0]        ninleft [7:0]           = '{default: '0};
	logic [4:0]        nintop  [2047:0]        = '{default: '0};    
	
	logic [31:0]       toppix   [0:IMGWIDTH-1] = '{default: '0};
	logic [31:0]       toppixcc [0:IMGWIDTH-1] = '{default: '0};
	logic [3:0]        topmode  [0:IMGWIDTH-1] = '{default: '0};
	logic [IWBITS-1:0] mbx                     = '0;
	logic [IWBITS-1:0] mbxcc                   = '0;


	h264intra4x4 ins_intra4x4 
	(
		.CLK      ( clk2               ),
		.NEWSLICE ( NEWSLICE           ),
		.NEWLINE  ( NEWLINE            ),
		.STROBEI  ( intra4x4_STROBEI   ),
		.DATAI    ( intra4x4_DATAI     ),
		.READYI   ( intra4x4_READYI    ),
		.TOPI     ( intra4x4_TOPI      ),
		.TOPMI    ( intra4x4_TOPMI     ),
		.XXO      ( intra4x4_XXO       ),
		.XXINC    ( intra4x4_XXINC     ),
		.FEEDBI   ( recon_FEEDB[31:24] ),
		.FBSTROBE ( recon_FBSTROBE     ),
		.STROBEO  ( intra4x4_STROBEO   ),
		.DATAO    ( intra4x4_DATAO     ),
		.BASEO    ( intra4x4_BASEO     ),
		.READYO   ( intra4x4_READYO    ),
		.MSTROBEO ( intra4x4_MSTROBEO  ),
		.MODEO    ( intra4x4_MODEO     ),
		.PMODEO   ( intra4x4_PMODEO    ),
		.RMODEO   ( intra4x4_RMODEO    ),
		.CHREADY  ( intra4x4_CHREADY   )
	);
	assign intra4x4_READYO = coretransform_READY && xbuffer_READYI; // && slowready;
	assign intra4x4_TOPI   = toppix [{mbx, intra4x4_XXO}];
	assign intra4x4_TOPMI  = topmode[{mbx, intra4x4_XXO}];

	h264intra8x8cc ins_intra8x8cc 
	(
	    .CLK2      ( clk2                 ),
	    .NEWSLICE  ( NEWSLICE             ),
	    .NEWLINE   ( NEWLINE              ),
	    .STROBEI   ( intra8x8cc_STROBEI   ),
	    .DATAI     ( intra8x8cc_DATAI     ),
	    .READYI    ( intra8x8cc_READYI    ),
	    .TOPI      ( intra8x8cc_TOPI      ),
	    .XXO       ( intra8x8cc_XXO       ),
	    .XXC       ( intra8x8cc_XXC       ),
	    .XXINC     ( intra8x8cc_XXINC     ),
	    .FEEDBI    ( recon_FEEDB[31:24]   ),
	    .FBSTROBE  ( recon_FBCSTROBE      ),
	    .STROBEO   ( intra8x8cc_STROBEO   ),
	    .DATAO     ( intra8x8cc_DATAO     ),
	    .BASEO     ( intra8x8cc_BASEO     ),
	    .READYO    ( intra4x4_CHREADY     ),
	    .DCSTROBEO ( intra8x8cc_DCSTROBEO ),
	    .DCDATAO   ( intra8x8cc_DCDATAO   ),
	    .CMODEO    ( intra8x8cc_CMODEO    )
	);
	assign intra8x8cc_TOPI = toppixcc[{mbxcc, intra8x8cc_XXO}];

	h264header ins_header
	(
		.CLK       ( clk              ),
		.NEWSLICE  ( NEWSLICE         ),
		.LASTSLICE ( 1'b0    		  ),
		.SINTRA    ( 1'b1             ),
		.MINTRA    ( 1'b1             ),
		.LSTROBE   ( intra4x4_STROBEO ),
		.CSTROBE   ( intra4x4_STROBEO ),
		.QP        ( qp               ),
		.PMODE     ( intra4x4_PMODEO  ),
		.RMODE     ( intra4x4_RMODEO  ),
		.CMODE     ( header_CMODE     ),
		.PTYPE     ( 2'b00            ),
		.PSUBTYPE  ( 2'b00            ),
		.MVDX      ( 12'h000          ),
		.MVDY      ( 12'h000          ),
		.VE        ( header_VE        ),
		.VL        ( header_VL        ),
		.VALID     ( header_VALID     )
	);

	h264coretransform ins_coretransform
	(
		.CLK       ( clk2                 ),
		.READY     ( coretransform_READY  ),
		.ENABLE    ( coretransform_ENABLE ),
		.XXIN      ( coretransform_XXIN   ),
		.VALID     ( coretransform_VALID  ),
		.YNOUT     ( coretransform_YNOUT  )
	);
	    
    assign coretransform_ENABLE = intra4x4_STROBEO | intra8x8cc_STROBEO;
	assign coretransform_XXIN = intra4x4_STROBEO ? intra4x4_DATAO : intra8x8cc_DATAO;
	assign recon_BSTROBEI = intra4x4_STROBEO | intra8x8cc_STROBEO;
	assign recon_BASEI = intra4x4_STROBEO ? intra4x4_BASEO : intra8x8cc_BASEO;

	h264dctransform  #
	(
		.TOGETHER  ( 1 )
	)
	ins_dctransform
	(
		.CLK2      ( clk2                 ),
		.RESET     ( NEWSLICE             ),
		.ENABLE    ( intra8x8cc_DCSTROBEO ),
		.XXIN      ( intra8x8cc_DCDATAO   ),
		.VALID     ( dctransform_VALID    ),
		.YYOUT     ( dctransform_YYOUT    ),
		.READYO    ( dctransform_READYO   ),
		.READYI    (                      )
	);
	assign dctransform_READYO = (intra4x4_CHREADY & ~coretransform_VALID);

	h264quantise ins_quantise
	(
		.CLK	   ( clk2                 ),
		.ENABLE    ( quantise_ENABLE      ),
		.QP        ( qp                   ),
		.DCCI      ( dctransform_VALID    ),
		.YNIN      ( quantise_YNIN        ),
		.ZOUT      ( quantise_ZOUT        ),
		.DCCO      ( quantise_DCCO        ),
		.VALID     ( quantise_VALID       )
	);
	assign quantise_YNIN = coretransform_VALID ? $signed(coretransform_YNOUT) : $signed(dctransform_YYOUT);
	assign quantise_ENABLE = coretransform_VALID | dctransform_VALID;

	h264dctransform ins_invdctransform
	(
		.CLK2      ( clk2                  ),
		.RESET     ( NEWSLICE              ),
		.ENABLE    ( invdctransform_ENABLE ),
		.XXIN      ( invdctransform_ZIN    ),
		.VALID     ( invdctransform_VALID  ),
		.YYOUT     ( invdctransform_YYOUT  ),
		.READYO    ( invdctransform_READY  ),
		.READYI    (                       )
	);
	assign invdctransform_ENABLE = quantise_VALID & quantise_DCCO;
	assign invdctransform_READY = dequantise_LAST & xbuffer_CCIN;
	assign invdctransform_ZIN = $signed(quantise_ZOUT);

	h264dequantise #
	(
		.LASTADVANCE ( 2 )
	)
	ins_dequantise 
	(
		.CLK       ( clk2                 ),
		.ENABLE    ( dequantise_ENABLE    ),
		.QP        ( qp                   ),
		.ZIN       ( dequantise_ZIN       ),
		.DCCI	   ( invdctransform_VALID ),
	    .DCCO      (                      ),
		.LAST      ( dequantise_LAST      ),
		.WOUT      ( dequantise_WOUT      ),
		.VALID     ( dequantise_VALID     )
	);
	assign dequantise_ENABLE = quantise_VALID & ~quantise_DCCO;
	assign dequantise_ZIN = !invdctransform_VALID ? $signed(quantise_ZOUT) : $signed(invdctransform_YYOUT);

	h264invtransform ins_invtransform
	(
		.CLK        ( clk2                ),
		.ENABLE     ( dequantise_VALID    ),
		.WIN		( dequantise_WOUT     ),
		.VALID		( invtransform_VALID  ),
		.XOUT		( invtransform_XOUT   )
	);

	h264recon ins_recon
	(
		.CLK2        ( clk2               ),
		.NEWSLICE    ( NEWSLICE           ),
		.STROBEI     ( invtransform_VALID ),
		.DATAI       ( invtransform_XOUT  ),
		.BSTROBEI    ( recon_BSTROBEI     ),
		.BCHROMAI    ( intra8x8cc_STROBEO ),
		.BASEI       ( recon_BASEI        ),
		.STROBEO     ( recon_FBSTROBE     ),
		.CSTROBEO    ( recon_FBCSTROBE    ),
		.DATAO       ( recon_FEEDB        )
	);

	h264buffer ins_xbuffer 
	(
		.CLK           ( clk2             ),
		.NEWSLICE      ( NEWSLICE         ),
		.NEWLINE       ( NEWLINE          ),
		.VALIDI        ( quantise_VALID   ),
		.ZIN		   ( quantise_ZOUT    ),
		.READYI        ( xbuffer_READYI   ),
		.CCIN          ( xbuffer_CCIN     ),
		.DONE          ( xbuffer_DONE     ),
		.VOUT          ( cavlc_VIN		  ),
		.VALIDO        ( cavlc_ENABLE	  ),
		.NLOAD         ( xbuffer_NLOAD	  ),
		.NX            ( xbuffer_NX		  ),
		.NY            ( xbuffer_NY		  ),
		.NV            ( xbuffer_NV		  ),
		.NXINC         ( xbuffer_NXINC	  ),
		.READYO        ( cavlc_READY	  ),
		.TREADYO       ( tobytes_READY	  ),
		.HVALID        ( header_VALID	  )
	);

	h264cavlc ins_cavlc 
	(
		.CLK           ( clk 			 ),
		.CLK2          ( clk2 			 ),
		.VS            (                 ),
		.ENABLE        ( cavlc_ENABLE    ),
		.READY         ( cavlc_READY     ),
		.VIN           ( cavlc_VIN       ),
		.NIN           ( cavlc_NIN       ),
		.SIN           ( 1'b0            ),
		.VE            ( cavlc_VE        ),
		.VL            ( cavlc_VL        ),
		.VALID         ( cavlc_VALID     ),
		.XSTATE        ( cavlc_XSTATE    ),
		.NOUT          ( cavlc_NOUT      ) 
	);

	h264tobytes ins_tobytes 
	(
		.CLK           ( clk             ),
		.VALID         ( tobytes_VALID   ),
		.READY         ( tobytes_READY   ),
		.VE            ( tobytes_VE      ),
		.VL            ( tobytes_VL      ),
		.BYTE          ( tobytes_BYTE    ),
		.STROBE        ( tobytes_STROBE  ),
		.DONE          ( tobytes_DONE    )
	);

   	assign tobytes_VE    = header_VALID ? {5'b00000, header_VE} : cavlc_VALID ? cavlc_VE : {1'b0, 24'h030080};
	assign tobytes_VL    = header_VALID ? header_VL : cavlc_VALID ? cavlc_VL : 5'b01000;
	assign tobytes_VALID = header_VALID | align_VALID | cavlc_VALID;

	always_ff @(posedge clk2) 
	begin
		if ( xbuffer_NLOAD ) 
		begin
			ninleft[xbuffer_NY        ] <= cavlc_NOUT;
			nintop [{ninx, xbuffer_NX}] <= cavlc_NOUT;
		end
		else 
		begin
			ninl <= ninleft[xbuffer_NY        ];
			nint <= nintop [{ninx, xbuffer_NX}];
		end
		if ( NEWLINE ) 
		begin
			ninx <= 0;
		end
		else if ( xbuffer_NXINC ) 
		begin
			ninx <= ninx + 1;
		end
	end

	assign cavlc_NIN = xbuffer_NV==1 ? ninl : xbuffer_NV==2 ? nint : xbuffer_NV==3 ? ninsum[5:1] : '0;
	assign ninsum = {1'b0, ninl} + {1'b0, nint} + 1;

	always_ff @(posedge clk2)
	begin
		if ( recon_FBSTROBE )
		begin
			toppix [{mbx, intra4x4_XXO}] <= recon_FEEDB;
		end
		
		if ( intra4x4_MSTROBEO )
		begin
			topmode[{mbx, intra4x4_XXO}] <= intra4x4_MODEO;
		end
		
		if ( NEWLINE )
		begin
			mbx <= '0;
		end
		else if ( intra4x4_XXINC )
		begin
			mbx <= mbx + 1;
		end
		
		if ( recon_FBCSTROBE )
		begin
			toppixcc[{mbxcc, intra8x8cc_XXO}] <= recon_FEEDB;
		end
		
		if ( NEWLINE )
		begin
			mbxcc <= '0;
		end
		else if ( intra8x8cc_XXINC )
		begin
			mbxcc <= mbxcc + 1;
		end
	end

endmodule

