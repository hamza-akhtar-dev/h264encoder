module pe #
(
    PIX_WIDTH = 8;
) 
(
    input logic clk, rst;
    input logic [1:0] sel;
    input logic [PIX_WIDTH-1:0] curr_pix_in;
    input logic [PIX_WIDTH-1:0] pe_above, pe_down, pe_right;
    output logic [PIX_WIDTH-1:0] abs_diff;
    output logic [PIX_WIDTH-1:0] spr_out;
);

logic pe_sel;

always_comb 
begin : mu3x1
    case(sel)
        2'b00: pe_sel = pe_above;
        2'b01: pe_sel = pe_down;
        2'b10: pe_sel = pe_right;
        2'b11: pe_sel = pe_sel;
    endcase
end

logic [PIX_WIDTH-1:0] cpr;

always_ff @(posedge clk)
begin : cpr_ff
    if(rst)
    begin
        cpr <= 0;
    end
    else
    begin
        cpr <= curr_pix_in;
    end
end

always_ff @(posedge clk)
begin : spr_ff
    if(rst)
    begin
        spr <= 0;
    end
    else
    begin
        spr <= pix_sel;
    end
end

logic [PIX_WIDTH:0] diff 

always_comb
begin : abs_diff_unit
    diff = {0, cpr} - {0, spr};
    if(diff[0])
    begin
        abs_diff = 8'h00 - diff[PIX_WIDTH-1:0];
    end
    else
    begin
        abs_diff = diff[PIX_WIDTH-1:0];
    end
end

assign sp_out = spr;
    
endmodule