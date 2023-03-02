module vbs_me #
(
    PIX_WIDTH = 8,
    PEX = 4,
    PEY = 4
) 
(
    input logic clk, rst,
    input logic [1:0] sel,
    input logic [PIX_WIDTH-1:0] curr_bram [0:PEX-1],
    input logic [PIX_WIDTH-1:0] ref_bram [0:PEX],
    output logic [PIX_WIDTH-1:0] sad [0:PEX-1][0:PEY-1]
);

logic [PIX_WIDTH-1:0] spr_taps [0:PEX-1][0:PEY-1];
logic [PIX_WIDTH-1:0] cpr_taps [0:PEX-1][0:PEY-1];
logic [PIX_WIDTH-1:0] right_reg_taps [0:PEY-1];

genvar i, j, k;

generate
    for(i = 0; i < PEX; i++)
    begin
        for(j = 0; j < PEY; j++)
        begin
            if(i == PEX-1)
            begin
                if(j == 0)
                begin
                    pe pe_ins 
                    (
                        .clk(clk),
                        .rst(rst),
                        .sel(sel),
                        .cpr_in(curr_bram[i]),
                        .pe_above(ref_bram[i]),
                        .pe_down(spr_taps[i][1]),
                        .pe_right(right_reg_taps[0]),
                        .cpr_out(cpr_taps[i][0]),
                        .spr_out(spr_taps[i][0]),
                        .sad(sad[i][j])
                    );
                end
                else if(j == PEY-1)
                begin
                    pe pe_ins 
                    (
                        .clk(clk),
                        .rst(rst),
                        .sel(sel),
                        .cpr_in(cpr_taps[i][PEY-2]),
                        .pe_above(spr_taps[i][PEY-2]),
                        .pe_down(ref_bram[i]),
                        .pe_right(right_reg_taps[PEY-1]),
                        .cpr_out(cpr_taps[i][PEY-1]), // This tap is not connected anywhere further
                        .spr_out(spr_taps[i][PEY-1]),
                        .sad(sad[i][j])
                    );
                end
                else
                begin
                    pe pe_ins 
                    (
                        .clk(clk),
                        .rst(rst),
                        .sel(sel),
                        .cpr_in(cpr_taps[i][j-1]),
                        .pe_above(spr_taps[i][j-1]),
                        .pe_down(spr_taps[i][j+1]),
                        .pe_right(right_reg_taps[j]),
                        .cpr_out(cpr_taps[i][j]),
                        .spr_out(spr_taps[i][j]),
                        .sad(sad[i][j])
                    );
                end
            end
            else
            begin
                if(j == 0)
                begin
                    pe pe_ins 
                    (
                        .clk(clk),
                        .rst(rst),
                        .sel(sel),
                        .cpr_in(curr_bram[i]),
                        .pe_above(ref_bram[i]),
                        .pe_down(spr_taps[i][1]),
                        .pe_right(spr_taps[i+1][j]),
                        .cpr_out(cpr_taps[i][0]),
                        .spr_out(spr_taps[i][0]),
                        .sad(sad[i][j])
                    );
                end
                else if(j == PEY-1)
                begin
                    pe pe_ins 
                    (
                        .clk(clk),
                        .rst(rst),
                        .sel(sel),
                        .cpr_in(cpr_taps[i][PEY-2]),
                        .pe_above(spr_taps[i][PEY-2]),
                        .pe_down(ref_bram[i]),
                        .pe_right(spr_taps[i+1][j]),
                        .cpr_out(cpr_taps[i][PEY-1]), // This tap is not connected anywhere further
                        .spr_out(spr_taps[i][PEY-1]),
                        .sad(sad[i][j])
                    );
                end
                else
                begin
                    pe pe_ins 
                    (
                        .clk(clk),
                        .rst(rst),
                        .sel(sel),
                        .cpr_in(cpr_taps[i][j-1]),
                        .pe_above(spr_taps[i][j-1]),
                        .pe_down(spr_taps[i][j+1]),
                        .pe_right(spr_taps[i+1][j]),
                        .cpr_out(cpr_taps[i][j]), 
                        .spr_out(spr_taps[i][j]),
                        .sad(sad[i][j])
                    );
                end
            end
        end
    end
endgenerate


generate
    for(k = 0; k < PEY; k++)
    begin
        if(k == 0)
        begin
            reg_mux reg_mux_ins
            (
                .clk(clk),
                .rst(rst),
                .sel(sel),
                .reg_above(ref_bram[PEX]),
                .reg_down(right_reg_taps[1]),
                .reg_out(right_reg_taps[0])
            );
        end
        else if(k == PEY-1)
        begin
            reg_mux reg_mux_ins
            (
                .clk(clk),
                .rst(rst),
                .sel(sel),
                .reg_above(right_reg_taps[PEY-2]),
                .reg_down(ref_bram[PEY]),
                .reg_out(right_reg_taps[PEY-1])
            );
        end
        else
        begin
            reg_mux reg_mux_ins
            (
                .clk(clk),
                .rst(rst),
                .sel(sel),
                .reg_above(right_reg_taps[k-1]),
                .reg_down(right_reg_taps[k+1]),
                .reg_out(right_reg_taps[k])
            );
        end
    end
endgenerate

endmodule