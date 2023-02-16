module sad_absolute #
(
    PIX_WIDTH = 8;
    PEX = 16;
    PEY = 16;
)
(
    input logic [PIX_WIDTH-1:0] sad [0:PEX-1][0:PEY-1]
    output logic [PIX_WIDTH-1:0] absolute_sad
);

logic [PIX_WIDTH-1:0] out0, out1, out2, out3;
logic [11:0] S4x4 [0:3][0:3];

genvar i, j, l, w;

generate
    l = 0;
    for(i = 0; i < PEX; i = i + 4)
    begin
        w = 0;
        for(j = 0; j < PEY; j = j + 4)
        begin
            adder_tree add1
            (
                .in1(sad[i][j]),
                .in2(sad[i+1][j]),
                .in3(sad[i+2][j]),
                .in4(sad[i+3][j]),
                .temp(out0)
            );

            adder_tree add2
            (
                .in1(sad[i][j+1]),
                .in2(sad[i+1][j+1]),
                .in3(sad[i+2][j+1]),
                .in4(sad[i+3][j+1]),
                .temp(out1)
            ); 

            adder_tree add2
            (
                .in1(sad[i][j+2]),
                .in2(sad[i+1][j+2]),
                .in3(sad[i+2][j+2]),
                .in4(sad[i+3][j+2]),
                .temp(out2)
            );

            adder_tree add3
            (
                .in1(sad[i][j+3]),
                .in2(sad[i+1][j+3]),
                .in3(sad[i+2][j+3]),
                .in4(sad[i+3][j+3]),
                .temp(out3)
            );

            adder_tree add1
            (
                .in1(out0),
                .in2(out1),
                .in3(out2),
                .in4(out3),
                .temp(S4x4[l][w])
            );
            w = w + 1;
        end
        l = l + 1;
    end
endgenerate


    
endmodule