module pe #
(
    PIXWIDTH = 8
) 
(
    input logic clk, rst,
    input logic [1:0] sel,
    input logic [PIXWIDTH-1:0] cpr_in,
    input logic [PIXWIDTH-1:0] pe_above, pe_down, pe_right,
    output logic [PIXWIDTH-1:0] spr_out, cpr_out,
    output logic [PIXWIDTH-1:0] sad
);

logic [PIXWIDTH-1:0] pe_sel;

always_comb 
begin
    case(sel)
        2'b00: pe_sel = pe_above;
        2'b01: pe_sel = pe_down;
        2'b10: pe_sel = pe_right;
        default: pe_sel = 2'b00;
    endcase
end

logic [PIXWIDTH-1:0] cpr_val;
logic [PIXWIDTH-1:0] spr_val;

register # (.WIDTH(PIXWIDTH)) cpr (.rst(rst), .clk(clk), .D(cpr_in), .Q(cpr_val));

register # (.WIDTH(PIXWIDTH)) spr (.rst(rst), .clk(clk), .D(pe_sel), .Q(spr_val));

logic [PIXWIDTH:0] diff;

always_comb
begin
    diff = {1'b0, cpr_val} - {1'b0, spr_val};
    if(diff[8])
    begin
        sad = 8'h00 - diff[PIXWIDTH-1:0];
    end
    else
    begin
        sad = diff[PIXWIDTH-1:0];
    end
end

assign spr_out = spr_val;
assign cpr_out = cpr_val;
    
endmodule