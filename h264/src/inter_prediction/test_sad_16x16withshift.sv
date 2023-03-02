module test_sad_16x16withoutshift #
(
    PIX_WIDTH = 8,
    PEX = 16,
    PEY = 16
)
(
    input logic clk, rst,
    input logic [1:0] sel,
    input logic [PIX_WIDTH-1:0] curr_bram [0:PEX-1],
    input logic [PIX_WIDTH-1:0] ref_bram [0:PEX],
    output logic [PIX_WIDTH-1:0] S4x4_00, S4x4_01, S4x4_02, S4x4_03, S4x4_10, S4x4_11, S4x4_12, S4x4_13, S4x4_20, S4x4_21,
                                 S4x4_22, S4x4_23, S4x4_30, S4x4_31, S4x4_32, S4x4_33, S4x8_00, S4x8_01, S4x8_02, S4x8_03,
                                 S4x8_10, S4x8_11, S4x8_12, S4x8_13, S8x4_00, S8x4_10, S8x4_20, S8x4_30, S8x4_01, S8x4_11,
                                 S8x4_21, S8x4_31, S8x8_00, S8x8_10, S8x8_01, S8x8_11, S16x8_0, S16x8_1, S8x16_0, S8x16_1,
                                 S16x16_0 
);

logic [PIX_WIDTH-1:0] sad[0:PEX-1][0:PEY-1];

vbs_me #
    (
        .PIX_WIDTH(PIX_WIDTH),
        .PEX(PEX),
        .PEY(PEY)
    )
    vbs_me4x4
    (
        .clk(clk),
        .rst(rst),
        .sel(sel),
        .curr_bram(curr_bram),
        .ref_bram(ref_bram),
        .sad(sad)
    );

sad_absolute #
    (
        .PIX_WIDTH(PIX_WIDTH),
        .PEX(PEX),
        .PEY(PEY)
    )
    sad16x16
    (
        .clk(clk),
        .rst(rst),
        .sad(sad),
        .S4x4_00(S4x4_00), 
        .S4x4_01(S4x4_01), 
        .S4x4_02(S4x4_02), 
        .S4x4_03(S4x4_03), 
        .S4x4_10(S4x4_10), 
        .S4x4_11(S4x4_11), 
        .S4x4_12(S4x4_12), 
        .S4x4_13(S4x4_13), 
        .S4x4_20(S4x4_20), 
        .S4x4_21(S4x4_21),
        .S4x4_22(S4x4_22), 
        .S4x4_23(S4x4_23), 
        .S4x4_30(S4x4_30), 
        .S4x4_31(S4x4_31), 
        .S4x4_32(S4x4_32), 
        .S4x4_33(S4x4_33), 
        .S4x8_00(S4x8_00), 
        .S4x8_01(S4x8_01), 
        .S4x8_02(S4x8_02), 
        .S4x8_03(S4x8_03),
        .S4x8_10(S4x8_10), 
        .S4x8_11(S4x8_11), 
        .S4x8_12(S4x8_12), 
        .S4x8_13(S4x8_13), 
        .S8x4_00(S8x4_00), 
        .S8x4_10(S8x4_10), 
        .S8x4_20(S8x4_20), 
        .S8x4_30(S8x4_30), 
        .S8x4_01(S8x4_01), 
        .S8x4_11(S8x4_11),
        .S8x4_21(S8x4_21), 
        .S8x4_31(S8x4_31), 
        .S8x8_00(S8x8_00), 
        .S8x8_10(S8x8_10), 
        .S8x8_01(S8x8_01), 
        .S8x8_11(S8x8_11), 
        .S16x8_0(S16x8_0), 
        .S16x8_1(S16x8_1), 
        .S8x16_0(S8x16_0), 
        .S8x16_1(S8x16_1),
        .S16x16_0(S16x16_0) 
    );

endmodule

