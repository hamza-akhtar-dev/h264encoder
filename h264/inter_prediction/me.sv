module me #
(
    parameter MACRO_DIM  = 16,
    parameter SEARCH_DIM = 48
) 
(
    input  logic        rst_n,
    input  logic        clk,
    input  logic        start,
    input  logic [7:0]  pixel_spr_in [0:MACRO_DIM-1],
    input  logic [7:0]  pixel_cpr_in [0:MACRO_DIM-1],
    output logic        valid,
    output logic [15:0] min_sad
);

    datapath_me ins_datapath_me
    (
        .rst_n(rst_n),
        .clk(clk),
        .sel(sel),
        .en_spr(en_spr),
        .en_cpr(en_cpr),
        .valid(valid),
        .pixel_spr_in(pixel_spr_in),
        .pixel_cpr_in(pixel_cpr_in),
        .min_sad(min_sad)
    );

    controller_me ins_controller_me
    (
        .rst_n(rst_n), 
        .clk(clk), 
        .start(start),
        .en_cpr(en_cpr), 
        .en_spr(en_spr),
        .sel(sel),
        .valid(valid)
    );

endmodule