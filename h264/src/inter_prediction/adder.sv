module adder #
(
    PIX_WIDTH = 8
)
(
    input logic [PIX_WIDTH-1:0] in1, in2,
    output logic [PIX_WIDTH-1:0] temp
);

assign temp = in1 + in2;

endmodule