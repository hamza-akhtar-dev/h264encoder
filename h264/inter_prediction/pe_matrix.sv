module pe_matrix #
( 
    parameter MACRO_DIM  = 16,
    parameter SEARCH_DIM = 48
) 
(
    input  logic                        rst_n,
    input  logic                        clk,
    input  logic                        en_spr,
    input  logic                        en_cpr,
    input  logic [1:0]                  sel,
    input  logic [7:0]                  pixel_spr_in [0:MACRO_DIM-1],
    input  logic [7:0]                  pixel_cpr_in [0:MACRO_DIM-1],
    input  logic [7:0]                  pixel_spr_right_in [0:MACRO_DIM-1],
    output logic [8*(MACRO_DIM**2)-1:0] ad
);

    logic [8*MACRO_DIM-1:0] wire_ad        [0:MACRO_DIM-1];
    logic [7:0]             wire_spr_right [0:MACRO_DIM]   [0:MACRO_DIM-1];

    assign wire_spr_right[0] = pixel_spr_right_in;

    genvar i;

    generate
        for(i = 0; i < MACRO_DIM; i = i + 1) 
        begin: column
            pe_col ins_pe_col
            (
                .rst_n              ( rst_n                         ),
                .clk                ( clk                           ),
                .sel                ( sel                           ),
                .en_spr             ( en_spr                        ),
                .en_cpr             ( en_cpr                        ),
                .pixel_spr_in       ( pixel_spr_in[i]               ),
                .pixel_cpr_in       ( pixel_cpr_in[i]               ),
                .pixel_spr_right_in ( wire_spr_right[MACRO_DIM-i-1] ),
                .pixel_spr_out      (                               ),
                .pixel_cpr_out      (                               ),
                .pixel_spr_taps     ( wire_spr_right[MACRO_DIM-i]   ),
                .ad                 ( wire_ad[i]                    )
            );  
        end
    endgenerate

    generate
        for (i = 0; i < MACRO_DIM; i = i + 1) 
        begin
            assign ad[(i+1)*8*MACRO_DIM-1:i*8*MACRO_DIM] = wire_ad[i];
        end
    endgenerate

endmodule