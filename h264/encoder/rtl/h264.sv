module h264 #
(
    parameter integer IMGWIDTH  = 352,
    parameter integer IMGHEIGHT = 288,
    parameter integer IWBITS    = 9
)
(
    input logic         clk,
    input logic         NEWSLICE,       
	input logic         NEWLINE,     
	input logic  [5:0]  qp,

	output logic        xbuffer_DONE, 
 
	output logic        intra4x4_READYI,   
	input  logic        intra4x4_STROBEI,
	output logic        intra8x8cc_READYI,   
	input  logic        intra8x8cc_STROBEI,
 
	output logic [7:0]  tobytes_BYTE,
	output logic        tobytes_STROBE, 
	output logic        tobytes_DONE,
	
	input  logic        align_VALID
);

    clock_divider ins_clock_divider
    (
        .clk   ( clk   ),
        .clk_a ( clk_a ),
        .clk_b ( clk_b )
    );

    assign intra4x4_DATAI = 32'hb5b5c9c9;
    assign intra8x8cc_DATAI = 32'hd6a5d6a5;

    h264topskeleton #
    (
        .IMGWIDTH  ( IMGWIDTH  ),
        .IMGHEIGHT ( IMGHEIGHT ),
        .IWBITS    ( IWBITS    )
    )
    ins_h264topskeleton
    (  
        .clk                ( clk_a              ),
        .clk2               ( clk_b              ),
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



endmodule