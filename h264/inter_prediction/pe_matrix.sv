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
    input  logic [7:0]                  pixel_spr_in       [0:MACRO_DIM-1],
    input  logic [7:0]                  pixel_cpr_in       [0:MACRO_DIM-1],
    input  logic [7:0]                  pixel_spr_right_in [0:MACRO_DIM-1],
    output logic [8*(MACRO_DIM**2)-1:0] ad
);

    logic [8*MACRO_DIM-1:0] wire_ad        [0:MACRO_DIM-1];
    logic [7:0]             wire_spr_right [0:MACRO_DIM]   [0:MACRO_DIM-1];

    // Debug

    // logic [7:0] debug0; 
    // logic [7:0] debug1; 
    // logic [7:0] debug2; 
    // logic [7:0] debug3; 
    // logic [7:0] debug4; 
    // logic [7:0] debug5; 
    // logic [7:0] debug6; 
    // logic [7:0] debug7; 
    // logic [7:0] debug8; 
    // logic [7:0] debug9; 
    // logic [7:0] debug10;
    // logic [7:0] debug11;
    // logic [7:0] debug12;
    // logic [7:0] debug13;
    // logic [7:0] debug14;
    // logic [7:0] debug15;

    // assign debug0 = pixel_spr_in[0];
    // assign debug1 = pixel_spr_in[1];
    // assign debug2 = pixel_spr_in[2];
    // assign debug3 = pixel_spr_in[3];
    // assign debug4 = pixel_spr_in[4];
    // assign debug5 = pixel_spr_in[5];
    // assign debug6 = pixel_spr_in[6];
    // assign debug7 = pixel_spr_in[7];
    // assign debug8 = pixel_spr_in[8];
    // assign debug9 = pixel_spr_in[9];
    // assign debug10 = pixel_spr_in[10];
    // assign debug11 = pixel_spr_in[11];
    // assign debug12 = pixel_spr_in[12];
    // assign debug13 = pixel_spr_in[13];
    // assign debug14 = pixel_spr_in[14];
    // assign debug15 = pixel_spr_in[15];


    assign wire_spr_right[0] = pixel_spr_right_in;

    genvar i;

    generate
        for(i = 0; i < MACRO_DIM; i = i + 1) 
        begin: column
            pe_col #
            (   
                .MACRO_DIM( MACRO_DIM )
            )
            ins_pe_col
            (
                .rst_n              ( rst_n                         ),
                .clk                ( clk                           ),
                .sel                ( sel                           ),
                .en_spr             ( en_spr                        ),
                .en_cpr             ( en_cpr                        ),
                .pixel_spr_in       ( pixel_spr_in[i]               ),
                .pixel_cpr_in       ( pixel_cpr_in[i]               ),
                .pixel_spr_right_in ( wire_spr_right[MACRO_DIM-i-1] ),
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