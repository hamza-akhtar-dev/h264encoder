module h264topskeleton #
(
	parameter integer IMGWIDTH  = 352,
    parameter integer IMGHEIGHT = 288,
    parameter integer IWBITS    = 9
)
(
	input logic CLK, 
	input logic CLK2,   

	input logic         NEWSLICE,       
	input logic         NEWLINE,     
	input logic  [5:0]  qp,
	output logic        xbuffer_DONE       = '0, 

	output logic        intra4x4_READYI    = '0,   
	input  logic        intra4x4_STROBEI   = '0,
	input  logic [31:0] intra4x4_DATAI     = '0,
	output logic        intra8x8cc_READYI  = '0,   
	input  logic        intra8x8cc_STROBEI = '0,
	input  logic [31:0] intra8x8cc_DATAI   = '0,

	output logic [7:0]  tobytes_BYTE       = '0,
	output logic        tobytes_STROBE     = '0, 
	output logic        tobytes_DONE       = '0    
);

	bit [31:0] intra4x4_TOPI         ;
	bit [3:0]  intra4x4_TOPMI        ;
	bit        intra4x4_STROBEO      ;
	bit        intra4x4_READYO       ;
	bit [35:0] intra4x4_DATAO        ;
	bit [31:0] intra4x4_BASEO        ;
	bit        intra4x4_MSTROBEO     ;
	bit [3:0]  intra4x4_MODEO        ;
	bit        intra4x4_PMODEO       ;
	bit [2:0]  intra4x4_RMODEO       ;
	bit [1:0]  intra4x4_XXO          ;
	bit        intra4x4_XXINC        ;
	bit        intra4x4_CHREADY      ;

	bit [31:0] intra8x8cc_TOPI       ;
	bit        intra8x8cc_STROBEO    ;
	bit        intra8x8cc_READYO     ;
	bit [35:0] intra8x8cc_DATAO      ;
	bit [31:0] intra8x8cc_BASEO      ;
	bit        intra8x8cc_DCSTROBEO  ;
	bit [15:0] intra8x8cc_DCDATAO    ;
	bit [1:0]  intra8x8cc_CMODEO     ;
	bit [1:0]  intra8x8cc_XXO        ;
	bit        intra8x8cc_XXC        ;
	bit        intra8x8cc_XXINC      ;

	bit [1:0]  header_CMODE          ;
	bit [19:0] header_VE             ;
	bit [4:0]  header_VL             ;
	bit        header_VALID          ;

	bit        coretransform_READY   ;
	bit        coretransform_ENABLE  ;
	bit [35:0] coretransform_XXIN    ;
	bit        coretransform_VALID   ;
	bit [13:0] coretransform_YNOUT;

	bit        dctransform_VALID     ;
	bit [15:0] dctransform_YYOUT;
	bit        dctransform_READYO    ;

	bit        quantise_ENABLE       ;
	bit [15:0] quantise_YNIN;
	bit        quantise_VALID        ;
	bit [11:0] quantise_ZOUT;
	bit        quantise_DCCO         ;

	bit        dequantise_ENABLE     ;
	bit [15:0] dequantise_ZIN;
	bit        dequantise_LAST       ;
	bit        dequantise_VALID      ;
	bit        dequantise_DCCO       ;
	bit [15:0] dequantise_WOUT       ;

	bit        invdctransform_ENABLE ;
	bit [15:0] invdctransform_ZIN;
	bit        invdctransform_VALID  ;
	bit [15:0] invdctransform_YYOUT  ;
	bit        invdctransform_READY  ;

	bit        invtransform_VALID    ;
	bit [39:0] invtransform_XOUT     ;

	bit        recon_BSTROBEI        ;
	bit [31:0] recon_BASEI           ;
	bit        recon_FBSTROBE        ;
	bit        recon_FBCSTROBE       ;
	bit [31:0] recon_FEEDB           ;

	bit        xbuffer_NLOAD         ;
	bit [2:0]  xbuffer_NX            ;        
	bit [2:0]  xbuffer_NY            ;        
	bit [1:0]  xbuffer_NV            ;        
	bit        xbuffer_NXINC         ;
	bit        xbuffer_READYI        ;
	bit        xbuffer_CCIN          ;

	bit        cavlc_ENABLE          ;       
	logic      cavlc_READY           ;  
	bit [11:0] cavlc_VIN             ; 
	bit [4:0]  cavlc_NIN             ;     
	bit [24:0] cavlc_VE              ;
	bit [4:0]  cavlc_VL              ;
	bit        cavlc_VALID           ;      
	bit [2:0]  cavlc_XSTATE          ;
	logic [4:0]cavlc_NOUT            ;

	logic      tobytes_READY         ;                   
	bit [24:0] tobytes_VE            ;
	bit [4:0]  tobytes_VL            ;
	bit        tobytes_VALID         ;

	bit        align_VALID           ;

	bit [7:0]  ninx                  ;
	bit [4:0]  ninl                  ;        
	bit [4:0]  nint                  ;      
	bit [5:0]  ninsum                ;       
             
	logic [4:0]        ninleft [7:0]           = '{default: '0};
	logic [4:0]        nintop  [2047:0]        = '{default: '0};    
	
	logic [31:0]       toppix   [0:IMGWIDTH-1] = '{default: '0};
	logic [31:0]       toppixcc [0:IMGWIDTH-1] = '{default: '0};
	logic [3:0]        topmode  [0:IMGWIDTH-1] = '{default: '0};
	logic [IWBITS-1:0] mbx                     = '0;
	logic [IWBITS-1:0] mbxcc                   = '0;


	intra4x4 ins_intra4x4 
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

	intra8x8cc ins_intra8x8cc 
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
		// .LASTSLICE ( 1'b1			  ),
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
	assign coretransform_ENABLE = intra4x4_STROBEO || intra8x8cc_STROBEO;
	assign coretransform_XXIN   = (intra4x4_STROBEO) ? intra4x4_DATAO : intra8x8cc_DATAO;
	assign recon_BSTROBEI       = intra4x4_STROBEO || intra8x8cc_STROBEO;
	assign recon_BASEI          = (intra4x4_STROBEO) ? intra4x4_BASEO : intra8x8cc_BASEO;

	h264dctransform ins_dctransform
	(
		.CLK2      ( clk2                 ),
		.RESET     ( newslice             ),
		.ENABLE    ( intra8x8cc_DCSTROBEO ),
		.XXIN      ( intra8x8cc_DCDATAO   ),
		.VALID     ( dctransform_VALID    ),
		.YYOUT     ( dctransform_YYOUT    ),
		.READYO    ( dctransform_READYO   )
	);
	assign dctransform_READYO = intra4x4_CHREADY && !coretransform_VALID;

	h264quantise ins_quantise
	(
		.CLK	   ( clk2                 ),
		.ENABLE    ( quantise_ENABLE      ),
		.QP        ( qp                   ),
		.DCCI      ( dctransform_VALID    ),
		.YNIN      ( quantise_YNIN        ),
		.ZOUT      ( quantise_ZOUT        ),
		.DCCO      ( quantise_DCCO        ),
		.VALID     ( quantise_valid       )
	);
	assign quantise_YNIN   = (coretransform_VALID) ? $signed(coretransform_YNOUT) : dctransform_YYOUT;
	assign quantise_ENABLE = coretransform_VALID || dctransform_VALID;

	h264dctransform ins_invdctransform
	(
		.CLK2      ( clk2                  ),
		.RESET     ( newslice              ),
		.ENABLE    ( invdctransform_ENABLE ),
		.XXIN      ( invdctransform_ZIN    ),
		.VALID     ( invdctransform_VALID  ),
		.YYOUT     ( invdctransform_YYOUT  ),
		.READYO    ( invdctransform_READY  )
	);
	assign invdctransform_ENABLE = quantise_VALID && quantise_DCCO;
	assign invdctransform_READY = dequantise_LAST && xbuffer_CCIN;
	assign invdctransform_ZIN = $signed(quantise_ZOUT);

	h264dequantise #
	(
		.LASTADVANCE( 2                   )
	)
	ins_dequantise 
	(
		.CLK       ( clk2                 ),
		.ENABLE    ( dequantise_ENABLE    ),
		.QP        ( qp                   ),
		.ZIN       ( dequantise_ZIN       ),
		.DCCI	   ( invdctransform_VALID ),
		.LAST      ( dequantise_LAST      ),
		.WOUT      ( dequantise_WOUT      ),
		.VALID     ( dequantise_VALID     )
	);
	assign dequantise_ENABLE = quantise_VALID && !quantise_DCCO;
	assign dequantise_ZIN    = (invdctransform_VALID) ? invdctransform_YYOUT : $signed(quantise_ZOUT);

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

	assign tobytes_VE    = (header_VALID) ? {5'b00000, header_VE} : (cavlc_VALID) ? cavlc_VE : {1'b1, 24'h030080};
	assign tobytes_VL    = (header_VALID) ? header_VL : (cavlc_VALID) ? cavlc_VL : 5'b01000;
	assign tobytes_VALID = header_VALID || align_VALID || cavlc_VALID;

	always_ff @(posedge CLK2) 
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

	assign cavlc_NIN = (xbuffer_NV == 1) ? ninl : (xbuffer_NV == 2) ? nint : (xbuffer_NV == 3) ? ninsum[5:1] : 6'b0;
	assign ninsum    = {1'b0, ninl} + {1'b0, nint} + 1;

	always_ff @(posedge CLK2)
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
		
		if ( NEWLINE == 1'b1 )
		begin
			mbxcc <= '0;
		end
		else if ( intra8x8cc_XXINC == 1'b1 )
		begin
			mbxcc <= mbxcc + 1;
		end
	end

endmodule

