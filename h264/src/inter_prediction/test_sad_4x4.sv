module test_sad_4x4 #
(
    PIX_WIDTH = 8,
    PEX = 4,
    PEY = 4
)
(
    input logic clk, rst,
    input logic [1:0] sel,
    input logic [PIX_WIDTH-1:0] curr_bram [0:PEX-1],
    input logic [PIX_WIDTH-1:0] ref_bram [0:PEX],
    output logic [PIX_WIDTH-1:0] S4x4
);

logic sad[0:PEX-1][0:PEY-1];
logic [PIX_WIDTH-1:0] out0, out1, out2, out3;

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
sad_absolute_withoutshift #
    (
        .PIX_WIDTH(PIX_WIDTH),
        .PEX(PEX),
        .PEY(PEY)
    )
    (
        .clk(clk),
        .rst(rst),
        .sad(sad),
        .S16x16_0(S4x4)
    );

endmodule

