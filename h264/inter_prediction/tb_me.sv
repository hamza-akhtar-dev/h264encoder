module tb_me #
(
    parameter MACRO_DIM  = 16,
    parameter SEARCH_DIM = 48
)

();

    localparam T = 10;

    logic [7:0] reference_picture [0:IMG_WIDTH*IMG_HEIGHT-1];
    logic [7:0] current_picture [0:IMG_WIDTH-1][0:IMG_HEIGHT-1];

    logic en_spr;
    logic en_cpr;
    logic [7:0]  pixel_spr_in [0:MACRO_DIM-1];
    logic [7:0]  pixel_cpr_in [0:MACRO_DIM-1];

    initial 
    begin
        forever #(T/2) clk = ~clk;
    end

    me ins_me
    (
        .rst_n(rst_n),
        .clk(clk),
        .en_spr(en_spr),
        .en_cpr(en_cpr),
        .pixel_spr_in(pixel_spr_in),
        .pixel_cpr_in(pixel_cpr_in),
        .sad(sad)
    );

    initial
    begin
        rst_n = 1;
        #20
        rst_n = 0;
    end

endmodule