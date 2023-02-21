module sad_absolute #
(
    PIX_WIDTH = 8,
    PEX = 16,
    PEY = 16
)
(
    input logic clk, reset, shift_en_4x4,
    input logic [PIX_WIDTH-1:0] sad[0:PEX-1][0:PEY-1],
    output logic [PIX_WIDTH-1:0] S16x16
    
);

logic [PIX_WIDTH-1:0] out0, out1, out2, out3;

logic [PIX_WIDTH-1:0] S4x4 [0:3][0:3];
logic [PIX_WIDTH-1:0] S4x8 [0:3][0:1];
logic [PIX_WIDTH-1:0] S8x4 [0:1][0:3];
logic [PIX_WIDTH-1:0] S8x8 [0:1][0:1];
logic [PIX_WIDTH-1:0] S16x8 [0:1];
logic [PIX_WIDTH-1:0] S8x16 [0:1];

logic [PIX_WIDTH-1:0] shifted_S4x4 [0:7];

genvar i, j, k, l, m, n, o, p, q;

// calculate all S4x4 components
generate
    for(i = 0; i < PEX; i = i + 4)
    begin
        for(j = 0; j < PEY; j = j + 4)
        begin
            adder_tree add0
            (
                .in1(sad[i][j]),
                .in2(sad[i+1][j]),
                .in3(sad[i+2][j]),
                .in4(sad[i+3][j]),
                .temp(out0)
            );

            adder_tree add1
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

            adder_tree add4
            (
                .in1(out0),
                .in2(out1),
                .in3(out2),
                .in4(out3),
                .temp(S4x4[i/4][j/4])
            );
        end
    end
endgenerate

shift_register shift4x4_00 
    (
        .clk(clk), 
        .reset(reset), 
        .shift_en(shift_en_4x4), 
        .in_data(S4x4[0][0]), 
        .out_data(shifted_S4x4[0])
    );

shift_register shift4x4_10 
    (
        .clk(clk), 
        .reset(reset), 
        .shift_en(shift_en_4x4), 
        .in_data(S4x4[1][0]), 
        .out_data(shifted_S4x4[1])
    );

shift_register shift4x4_20 
    (
        .clk(clk), 
        .reset(reset), 
        .shift_en(shift_en_4x4), 
        .in_data(S4x4[2][0]), 
        .out_data(shifted_S4x4[2])
    );    

shift_register shift4x4_30 
    (
        .clk(clk), 
        .reset(reset), 
        .shift_en(shift_en_4x4), 
        .in_data(S4x4[3][0]), 
        .out_data(shifted_S4x4[3])
    );

shift_register shift4x4_02 
    (
        .clk(clk), 
        .reset(reset), 
        .shift_en(shift_en_4x4), 
        .in_data(S4x4[0][2]), 
        .out_data(shifted_S4x4[4])
    );    

shift_register shift4x4_12 
    (
        .clk(clk), 
        .reset(reset), 
        .shift_en(shift_en_4x4), 
        .in_data(S4x4[1][2]), 
        .out_data(shifted_S4x4[5])
    );

shift_register shift4x4_22 
    (
        .clk(clk), 
        .reset(reset), 
        .shift_en(shift_en_4x4), 
        .in_data(S4x4[2][2]), 
        .out_data(shifted_S4x4[6])
    );

shift_register shift4x4_32 
    (
        .clk(clk), 
        .reset(reset), 
        .shift_en(shift_en_4x4), 
        .in_data(S4x4[3][2]), 
        .out_data(shifted_S4x4[7])
    );    

generate
    for (k = 0; k < PEY/4; k = k + 2)
    begin
        for (l = 0; l < PEX/4; l = l + 1)
        begin
            if (k == 2)
            begin
                adder sum4x8
                (
                    .in1(shifted_S4x4[l+3]),
                    .in2(S4x4[l][k+1]),
                    .temp(S4x8[k/2][l])
                );
            end
            else
            begin
                adder sum4x8
                (
                    .in1(shifted_S4x4[l]),
                    .in2(S4x4[l][k+1]),
                    .temp(S4x8[k/2][l])
                );
            end

            adder sum8x4
            (
                .in1(S4x4[k][l]),
                .in2(S4x4[k+1][l]),
                .temp(S8x4[l][k/2])
            );
        end
    end
endgenerate
    
generate
    for (m = 0; m < PEY/8; m = m + 1)
    begin
        for (n = 0; n < PEX/4; n = n + 2)
        begin
            adder sum8x8
            (
                .in1(S8x4[n][m]),
                .in2(S8x4[n+1][m]),
                .temp(S8x8[m][n/2])
            );
        end
    end
endgenerate

generate
    for (o = 0 ; o < PEY/8; o = o + 1)
    begin
        for (p = 0; p < PEY/16; p = p + 1)
        begin
            adder sum16x8
            (   
                .in1(S8x8[o][p]),
                .in2(S8x8[o][p+1]),
                .temp(S16x8[o])
            );

            adder sum8x16
            (
                .in1(S8x8[p][o]),
                .in2(S8x8[p+1][o]),
                .temp(S8x16[o])
            );
        end
    end
endgenerate

generate
    for (q = 0; q < PEY/16; q = q + 1)
    begin
        adder sum16x16
        (
            .in1(S8x16[q]),
            .in2(S8x16[q+1]),
            .temp(S16x16)  
        );
    end
endgenerate
endmodule