module shift_register_S4x4 #
(
    parameter WIDTH = 8,
    parameter NUM_OF_REG = 4
)
(
    input logic rst, clk,
    input logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out
);

logic [WIDTH-1:0] reg_wires [0:NUM_OF_REG];

genvar i;

assign reg_wires[0] = data_in;

generate
    for (i = 0; i < 4; i++)
    begin
        register #
        (
            .WIDTH(8)
        )
            reg_8bit
        (
            .rst(rst),
            .clk(clk),
            .D(reg_wires[i]),
            .Q(reg_wires[i+1])
        );
    end
endgenerate

assign data_out = reg_wires[4];

endmodule