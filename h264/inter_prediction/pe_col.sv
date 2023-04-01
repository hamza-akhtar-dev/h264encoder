module pe_col #
(
    parameter MACRO_DIM = 16
) 
(
    input  logic                   rst_n,
    input  logic                   clk,
    input  logic                   sel,
    input  logic                   en_spr,
    input  logic                   en_cpr,
    input  logic [7:0]             pixel_spr_in,
    input  logic [7:0]             pixel_cpr_in,
    output logic [7:0]             pixel_spr_out,
    output logic [7:0]             pixel_cpr_out,
    output logic [MACRO_DIM*8-1:0] ad
);

    logic [7:0] wire_spr [0:MACRO_DIM+1];
    logic [7:0] wire_cpr [0:MACRO_DIM+1];
    logic [7:0] wire_spr_mux [0:MACRO_DIM];
    logic [7:0] wire_cpr_mux [0:MACRO_DIM];
    logic [7:0] wire_ad  [0:MACRO_DIM-1];

    assign wire_spr[0]   = pixel_spr_in;
    assign wire_cpr[0]   = pixel_cpr_in;
    assign pixel_spr_out = wire_spr[MACRO_DIM];
    assign pixel_cpr_out = wire_cpr[MACRO_DIM];

    genvar i;

    generate
        for(i = 0; i < MACRO_DIM; i = i + 1) 
        begin: element
            pe pe_ins
            (
                .rst_n         ( rst_n           ),
                .clk           ( clk             ),
                .en_spr        ( en_spr          ),
                .en_cpr        ( en_cpr          ),
                .pixel_spr_in  ( wire_spr[i]     ),
                .pixel_cpr_in  ( wire_cpr_mux[i] ),
                .pixel_spr_out ( wire_spr[i+1]   ),
                .pixel_cpr_out ( wire_cpr[i+1]   ),
                .ad            ( wire_ad[i]      )
            );
        end
    endgenerate

    generate
        for(i = 0; i < MACRO_DIM; i = i + 1)
        begin
            mux2x1 mux2x1_ins
            (
                .sel( sel             ),
                .in1( wire_cpr[i]     ),
                .in2( wire_cpr[i+2]   ),
                .out( wire_cpr_mux[i] )
            );
        end 
    endgenerate
    assign wire_cpr[MACRO_DIM+1] = pixel_cpr_in;

    generate
        for(i = 0; i < MACRO_DIM; i = i + 1)
        begin
            mux2x1 mux2x1_ins
            (
                .sel( sel             ),
                .in1( wire_spr[i]     ),
                .in2( wire_spr[i+2]   ),
                .out( wire_spr_mux[i] )
            );
        end 
    endgenerate
    assign wire_spr[MACRO_DIM+1] = pixel_spr_in;

    generate
        for (i = 0; i < MACRO_DIM; i = i + 1) 
        begin
            assign ad[8*(i+1)-1:8*i] = wire_ad[i];
        end
    endgenerate

endmodule