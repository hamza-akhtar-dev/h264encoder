module reg_mux #
(
    PIXWIDTH = 8
) 
(
    input logic clk, rst,
    input logic [1:0] sel,
    input logic [PIXWIDTH-1:0] reg_above, reg_down,
    output logic [PIXWIDTH-1:0] reg_out
);

logic [PIXWIDTH-1:0] reg_sel;

always_comb 
begin : mu3x1
    case(sel)
        2'b00: reg_sel = reg_above;
        2'b01: reg_sel = reg_down;
        default: reg_sel = 2'b00;
    endcase
end

logic [PIXWIDTH-1:0] reg_val;

register # (.WIDTH(PIXWIDTH)) right_reg (.rst(rst), .clk(clk), .D(reg_sel), .Q(reg_val));

assign reg_out = reg_val;

endmodule