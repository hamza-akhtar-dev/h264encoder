module controller_me
#
(
    parameter MACRO_DIM  = 16,
    parameter SEARCH_DIM = 48
) 
(
    input logic rst_n, clk, start,
    output logic en_cpr, en_spr, valid
);

logic [3:0] clk_count;

always_ff @(posedge clk)
begin
    if(rst_n)
    begin
        en_cpr <= 0;
        en_spr <= 0;
        valid <= 0;
        clk_count <= 0;
    end
    else
    begin
        if(start)
        begin
            en_cpr <= 1;
            en_spr <= 1;
            clk_count <= clk_count + 1;
        end
        else
        begin
            if(clk_count == 4'd16)
            begin
                valid <= 1;
            end
            else
            begin
                clk_count <= clk_count + 1;
            end
        end
    end
end

endmodule