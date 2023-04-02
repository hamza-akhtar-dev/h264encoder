module me #
(
    parameter MACRO_DIM  = 16,
    parameter SEARCH_DIM = 48
) 
(
    input  logic        rst_n,
    input  logic        clk,
    input  logic        start,
    input  logic [7:0]  pixel_spr_in       [0:MACRO_DIM],
    input  logic [7:0]  pixel_cpr_in       [0:MACRO_DIM-1],
    output logic        valid,
    output logic [15:0] min_sad
);

    logic [1:0] sel;

    datapath_me # 
    (
        .MACRO_DIM  ( MACRO_DIM  ),
        .SEARCH_DIM ( SEARCH_DIM )
    )
    ins_datapath_me
    (
        .rst_n              ( rst_n              ),
        .clk                ( clk                ),
        .en_spr             ( en_spr             ),
        .en_cpr             ( en_cpr             ),
        .valid              ( valid              ),
        .sel                ( sel                ),
        .pixel_spr_in       ( pixel_spr_in       ),
        .pixel_cpr_in       ( pixel_cpr_in       ),
        .min_sad            ( min_sad            )
    );

    controller_me # 
    (
        .MACRO_DIM  ( MACRO_DIM  ),
        .SEARCH_DIM ( SEARCH_DIM )
    )
    ins_controller_me
    (
        .rst_n  ( rst_n  ), 
        .clk    ( clk    ), 
        .start  ( start  ),
        .en_cpr ( en_cpr ), 
        .en_spr ( en_spr ),
        .valid  ( valid  ),
        .sel    ( sel    )
    );

endmodule