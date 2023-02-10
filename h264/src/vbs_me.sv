module vbs_me #
(
    PIX_WIDTH = 8;
    PE_X = 2;
    PE_Y = 2;
) 
(
    input logic [7:0] curr_bram_in [0:PE_X];
    input logic [7:0] ref_bram_in [0:PE_X];
    output logic [PIX_WIDTH-1:0] sad;
);

logic [7:0] above_lines [0:PE_X-1][0:PE_Y-1];
logic [7:0] down_lines [0:PE_X-1][0:PE_Y-1];
logic [7:0] right_lines [0:PE_X-1][0:PE_X-1];

assign above_lines[0][0] = ref_bram_in[0];

pe pe_ins_0
(
    .clk(clk),
    .rst(rst),
    .sel(sel),
    .curr_pix_in(curr_bram_in[i]),
    .pe_above(above_lines[0][0]),
    .pe_down(down_lines[0][0]),
    .pe_right(right_lines[0][0])
    .spr_out(above_lines[0][1])
);

pe pe_ins_1
(
    .clk(clk),
    .rst(rst),
    .sel(sel),
    .curr_pix_in(curr_bram_in[i]),
    .pe_above(above_lines[0][1]),
    .pe_down(down_lines[0][1]),
    .pe_right(right_lines[0][1]),
    .spr_out(down_lines[0][0])
);

assign down_lines[0][1] = ref_bram_in[0];

assign above_lines[1][0] = ref_bram_in[1];

pe pe_ins_2
(
    .clk(clk),
    .rst(rst),
    .sel(sel),
    .curr_pix_in(curr_bram_in[i]),
    .pe_above(above_lines[1][0]),
    .pe_down(down_lines[1][0]),
    .pe_right(right_lines[1][0])
    .spr_out(above_lines[1][1])
);

pe pe_ins_3
(
    .clk(clk),
    .rst(rst),
    .sel(sel),
    .curr_pix_in(curr_bram_in[i]),
    .pe_above(above_lines[1][1]),
    .pe_down(above_lines[i][j]),
    .pe_right(right_lines[1][1])
    .spr_out(down_lines[1][1])
);



endmodule