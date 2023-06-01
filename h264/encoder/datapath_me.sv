module datapath_me #
(
    parameter MACRO_DIM  = 16,
    parameter SEARCH_DIM = 48
) 
(
    input  logic         rst_n,
    input  logic         clk,
    input  logic [5:0]   addr,
    input  logic [5:0]   amt,
    input  logic         en_spr,
    input  logic         en_cpr,
    input  logic         valid,
    input  logic [1:0 ]  sel,
    input  logic [7:0 ]  pixel_spr_in [0:MACRO_DIM  ],
    input  logic [7:0 ]  pixel_cpr_in [0:MACRO_DIM-1],
    output logic [5:0]   mv_x,
    output logic [5:0]   mv_y,
    output logic [15:0]  min_sad
);
    logic [7:0]                  wire_reg_right          [0:MACRO_DIM+1];
    logic [7:0]                  wire_reg_right_mux      [0:MACRO_DIM  ];
    logic [7:0]                  wire_pixel_spr_right_in [0:MACRO_DIM-1];
    logic [15:0]                 wire_sad;
    logic [8*(MACRO_DIM**2)-1:0] wire_ad;

    pe_matrix #
    (
        .MACRO_DIM  ( MACRO_DIM  ),
        .SEARCH_DIM ( SEARCH_DIM )
    )
    ins_pe_matrix 
    (
        .rst_n              ( rst_n                       ),
        .clk                ( clk                         ),
        .sel                ( sel                         ),
        .en_spr             ( en_spr                      ),
        .en_cpr             ( en_cpr                      ),
        .pixel_spr_in       ( pixel_spr_in[0:MACRO_DIM-1] ),
        .pixel_cpr_in       ( pixel_cpr_in                ),
        .pixel_spr_right_in ( wire_pixel_spr_right_in     ),
        .ad                 ( wire_ad                     )
    );

    genvar i;

    generate
        for (i = 0; i < MACRO_DIM; i = i + 1) 
        begin
            register ins_register 
            (
                .rst_n ( rst_n                 ),
                .clk   ( clk                   ),
                .en    ( en_spr                ),
                .in    ( wire_reg_right_mux[i] ),
                .out   ( wire_reg_right[i+1]   )
            );
            assign wire_pixel_spr_right_in[i] = wire_reg_right[i+1];
        end
    endgenerate
    
    assign wire_reg_right[0]           = pixel_spr_in[MACRO_DIM];
    assign wire_reg_right[MACRO_DIM+1] = pixel_spr_in[MACRO_DIM];
    
    generate
        for(i = 0; i < MACRO_DIM; i = i + 1)
        begin
            mux2x1 ins_mux2x1
            (
                .sel ( sel[0]                ),
                .in1 ( wire_reg_right[i]     ),     // Down Shift
                .in2 ( wire_reg_right[i+2]   ),     // Up Shift
                .out ( wire_reg_right_mux[i] )
            );
        end 
    endgenerate

    sum #
    (   
        .MACRO_DIM( MACRO_DIM )
    )
    ins_sum
    (
        .rst_n ( rst_n    ),
        .clk   ( clk      ),
        .ad    ( wire_ad  ),
        .sum   ( wire_sad )
    );
    
    comparator ins_comparator
    (
        .clk     ( clk      ),
        .rst_n   ( rst_n    ),
        .valid   ( valid    ),
        .addr    ( addr     ),
        .amt     ( amt      ),
        .sad     ( wire_sad ),
        .min_sad ( min_sad  ),
        .mv_x    ( mv_x     ),
        .mv_y    ( mv_y     )
    );

endmodule