module adder_tree # 
(
    PIX_WIDTH = 8
)
(
    input logic [PIX_WIDTH-1:0] in1, in2, in3, in4,
    output logic [PIX_WIDTH-1:0] temp
);

logic [PIX_WIDTH-1:0] temp1, temp2;

assign temp1 = in1 + in2;
assign temp2 = in3 + in4;
assign temp = temp1 + temp2;

endmodule