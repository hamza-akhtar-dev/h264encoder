module me #
(
    parameter MACRO_DIM  = 16,
    parameter SEARCH_DIM = 48
) 
(
    input  logic        rst_n,
    input  logic        clk,
    input  logic        start,
    input  logic [7:0]  pixel_spr_in [0:MACRO_DIM],
    input  logic [7:0]  pixel_cpr_in [0:MACRO_DIM-1],
    output logic        ready,
    output logic        valid, 
    output logic        en_ram,
    output logic        done,
    output logic [5:0]  addr,
    output logic [5:0]  amt,
    output logic [5:0]  mv_x,
    output logic [5:0]  mv_y,
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
        .amt                ( amt                ),
        .addr               ( addr               ),
        .en_spr             ( en_spr             ),
        .en_cpr             ( en_cpr             ),
        .valid              ( valid              ),
        .sel                ( sel                ),
        .pixel_spr_in       ( pixel_spr_in       ),
        .pixel_cpr_in       ( pixel_cpr_in       ),
        .min_sad            ( min_sad            ),
        .mv_x               ( mv_x               ),
        .mv_y               ( mv_y               )
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
        .ready  ( ready  ),
        .valid  ( valid  ),
        .en_cpr ( en_cpr ), 
        .en_spr ( en_spr ),
        .en_ram ( en_ram ),
        .done   ( done   ),
        .addr   ( addr   ),
        .amt    ( amt    ),
        .sel    ( sel    )
    );

endmodule