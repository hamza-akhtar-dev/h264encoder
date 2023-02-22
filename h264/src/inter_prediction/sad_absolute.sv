module sad_absolute #
(
    PIX_WIDTH = 8,
    PEX = 16,
    PEY = 16
)
(
    input logic clk, rst,
    input logic [PIX_WIDTH-1:0] sad[0:PEX-1][0:PEY-1],
    // output ports
    output logic [PIX_WIDTH-1:0] S4x4_00, S4x4_01, S4x4_02, S4x4_03, S4x4_10, S4x4_11, S4x4_12, S4x4_13, S4x4_20, S4x4_21,
                                 S4x4_22, S4x4_23, S4x4_30, S4x4_31, S4x4_32, S4x4_33, S4x8_00, S4x8_01, S4x8_02, S4x8_03,
                                 S4x8_10, S4x8_11, S4x8_12, S4x8_13, S8x4_00, S8x4_10, S8x4_20, S8x4_30, S8x4_01, S8x4_11,
                                 S8x4_21, S8x4_31, S8x8_00, S8x8_10, S8x8_01, S8x8_11, S16x8_0, S16x8_1, S8x16_0, S8x16_1,
                                 S16x16_0   
);

logic [PIX_WIDTH-1:0] out0, out1, out2, out3;

logic [PIX_WIDTH-1:0] S4x4 [0:3][0:3];
logic [PIX_WIDTH-1:0] S4x8 [0:1][0:3];
logic [PIX_WIDTH-1:0] S8x4 [0:3][0:1];
logic [PIX_WIDTH-1:0] S8x8 [0:1][0:1];
logic [PIX_WIDTH-1:0] S16x8 [0:1];
logic [PIX_WIDTH-1:0] S8x16 [0:1];
logic [PIX_WIDTH-1:0] S16x16;

logic [PIX_WIDTH-1:0] shifted_S4x4 [0:7];
logic [PIX_WIDTH-1:0] shifted_S8x8 [0:1];

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
                .in2(sad[i][j+1]),
                .in3(sad[i][j+2]),
                .in4(sad[i][j+3]),
                .temp(out0)
            );

            adder_tree add1
            (
                .in1(sad[i+1][j]),
                .in2(sad[i+1][j+1]),
                .in3(sad[i+1][j+2]),
                .in4(sad[i+1][j+3]),
                .temp(out1)
            ); 

            adder_tree add2
            (
                .in1(sad[i+2][j]),
                .in2(sad[i+2][j+1]),
                .in3(sad[i+2][j+2]),
                .in4(sad[i+2][j+3]),
                .temp(out2)
            );

            adder_tree add3
            (
                .in1(sad[i+3][j]),
                .in2(sad[i+3][j+1]),
                .in3(sad[i+3][j+2]),
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

shift_register_S4x4 #
    (
        .WIDTH(PIX_WIDTH),
        .NUM_OF_REG(4)
    )
    shift4x4_00
    (
        .rst(rst), 
        .clk(clk),
        .data_in(S4x4[0][0]),
        .data_out(shifted_S4x4[0])
    );

shift_register_S4x4 #
    (
        .WIDTH(PIX_WIDTH),
        .NUM_OF_REG(4)
    )
    shift4x4_01
    (
        .rst(rst), 
        .clk(clk),
        .data_in(S4x4[0][1]),
        .data_out(shifted_S4x4[1])
    );

shift_register_S4x4 #
    (
        .WIDTH(PIX_WIDTH),
        .NUM_OF_REG(4)
    )
    shift4x4_02
    (
        .rst(rst), 
        .clk(clk),
        .data_in(S4x4[0][2]),
        .data_out(shifted_S4x4[2])
    );   

shift_register_S4x4 #
    (
        .WIDTH(PIX_WIDTH),
        .NUM_OF_REG(4)
    )
    shift4x4_03
    (
        .rst(rst), 
        .clk(clk),
        .data_in(S4x4[0][3]),
        .data_out(shifted_S4x4[3])
    );

shift_register_S4x4 #
    (
        .WIDTH(PIX_WIDTH),
        .NUM_OF_REG(4)
    )
    shift4x4_20
    (
        .rst(rst), 
        .clk(clk),
        .data_in(S4x4[2][0]),
        .data_out(shifted_S4x4[4])
    );
    
shift_register_S4x4 #
    (
        .WIDTH(PIX_WIDTH),
        .NUM_OF_REG(4)
    )
    shift4x4_21
    (
        .rst(rst), 
        .clk(clk),
        .data_in(S4x4[2][1]),
        .data_out(shifted_S4x4[5])
    );

shift_register_S4x4 #
    (
        .WIDTH(PIX_WIDTH),
        .NUM_OF_REG(4)
    )
    shift4x4_22
    (
        .rst(rst), 
        .clk(clk),
        .data_in(S4x4[2][2]),
        .data_out(shifted_S4x4[6])
    );

shift_register_S4x4 #
    (
        .WIDTH(PIX_WIDTH),
        .NUM_OF_REG(4)
    )
    shift4x4_23
    (
        .rst(rst), 
        .clk(clk),
        .data_in(S4x4[2][3]),
        .data_out(shifted_S4x4[7])
    );

generate
    for (k = 0; k < PEX/4; k = k + 2)
    begin
        for (l = 0; l < PEY/4; l = l + 1)
        begin
            if (k == 2)
            begin
                adder sum4x8
                (
                    .in1(shifted_S4x4[l+4]),
                    .in2(S4x4[k+1][l]),
                    .temp(S4x8[k/2][l])
                );
            end
            else
            begin
                adder sum4x8
                (
                    .in1(shifted_S4x4[l]),
                    .in2(S4x4[k+1][l]),
                    .temp(S4x8[k/2][l])
                );
            end

            if (l == 0 )
            begin
                adder sum8x4
                (
                    .in1(shifted_S4x4[k]),
                    .in2(shifted_S4x4[k+1]),
                    .temp(S8x4[l][k/2])
                );
            end
            else if (l == 2)
            begin
                adder sum8x4
                (
                    .in1(shifted_S4x4[k+4]),
                    .in2(shifted_S4x4[k+5]),
                    .temp(S8x4[l][k/2])
                );
            end
            else
            begin
                adder sum8x4
                (
                    .in1(S4x4[l][k]),
                    .in2(S4x4[l][k+1]),
                    .temp(S8x4[l][k/2])
                );
            end            
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
                .temp(S8x8[n/2][m])
            );
        end
    end
endgenerate

shift_register_S4x4 #
    (
        .WIDTH(PIX_WIDTH),
        .NUM_OF_REG(8)
    )
    shift8x8_00
    (
        .rst(rst), 
        .clk(clk),
        .data_in(S8x8[0][0]),
        .data_out(shifted_S8x8[0])
    );

shift_register_S4x4 #
    (
        .WIDTH(PIX_WIDTH),
        .NUM_OF_REG(8)
    )
    shift8x8_01
    (
        .rst(rst), 
        .clk(clk),
        .data_in(S8x8[0][1]),
        .data_out(shifted_S8x8[1])
    );   

generate
    for (o = 0 ; o < PEY/8; o = o + 1)
    begin
        for (p = 0; p < PEY/16; p = p + 1)
        begin
            if (o == 0)
            begin
                adder sum16x8
                (   
                    .in1(shifted_S8x8[p]),
                    .in2(shifted_S8x8[p+1]),
                    .temp(S16x8[o])
                );
            end
            else
            begin
                adder sum16x8
                (   
                    .in1(S8x8[o][p]),
                    .in2(S8x8[o][p+1]),
                    .temp(S16x8[o])
                );
            end

            adder sum8x16
            (
                .in1(shifted_S8x8[o]),
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

assign S4x4_00 = S4x4[0][0];
assign S4x4_01 = S4x4[0][1];
assign S4x4_02 = S4x4[0][2];
assign S4x4_03 = S4x4[0][3];
assign S4x4_10 = S4x4[1][0];
assign S4x4_11 = S4x4[1][1];
assign S4x4_12 = S4x4[1][2];
assign S4x4_13 = S4x4[1][3];
assign S4x4_20 = S4x4[2][0];
assign S4x4_21 = S4x4[2][1];
assign S4x4_22 = S4x4[2][2];
assign S4x4_23 = S4x4[2][3];
assign S4x4_30 = S4x4[3][0];
assign S4x4_31 = S4x4[3][1];
assign S4x4_32 = S4x4[3][2];
assign S4x4_33 = S4x4[3][3];

assign S4x8_00 = S4x8[0][0];
assign S4x8_01 = S4x8[0][1];
assign S4x8_02 = S4x8[0][2];
assign S4x8_03 = S4x8[0][3];
assign S4x8_10 = S4x8[1][0];
assign S4x8_11 = S4x8[1][1];
assign S4x8_12 = S4x8[1][2];
assign S4x8_13 = S4x8[1][3];

assign S8x4_00 = S8x4[0][0];
assign S8x4_10 = S8x4[1][0];
assign S8x4_20 = S8x4[2][0];
assign S8x4_30 = S8x4[3][0];
assign S8x4_01 = S8x4[0][1];
assign S8x4_11 = S8x4[1][1];
assign S8x4_21 = S8x4[2][1];
assign S8x4_31 = S8x4[3][1];

assign S8x8_00 = S8x8[0][0];
assign S8x8_10 = S8x8[1][0];
assign S8x8_01 = S8x8[0][1];
assign S8x8_11 = S8x8[1][1];

assign S16x8_0 = S16x8[0];
assign S16x8_1 = S16x8[1];
assign S8x16_0 = S8x16[0];
assign S8x16_1 = S8x16[1];

assign S16x16_0 = S16x16;

endmodule