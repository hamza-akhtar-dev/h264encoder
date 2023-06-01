module pe #
(
    parameter MACRO_DIM = 16
)
(
    input  logic       rst_n,
    input  logic       clk,
    input  logic       en_spr,
    input  logic       en_cpr,
    input  logic [7:0] pixel_spr_in,
    input  logic [7:0] pixel_cpr_in,
    output logic [7:0] pixel_spr_out,
    output logic [7:0] pixel_cpr_out,
    output logic [7:0] ad
);

always @(posedge clk or negedge rst_n) 
begin
    if(~rst_n) 
    begin
        pixel_spr_out <= 0;
        pixel_cpr_out <= 0;
    end 
    else 
    begin
        if(en_spr)
        begin
            pixel_spr_out <= #1 pixel_spr_in;
        end
        if(en_cpr)
        begin
            pixel_cpr_out <= #1 pixel_cpr_in;
        end
    end
end

assign ad = (pixel_spr_out > pixel_cpr_out) ? pixel_spr_out - pixel_cpr_out : pixel_cpr_out - pixel_spr_out;

endmodule