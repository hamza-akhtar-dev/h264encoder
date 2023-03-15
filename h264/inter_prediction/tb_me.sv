module tb_me #
(
    parameter IMG_HEIGHT = 16,
    parameter IMG_WIDTH = 16,
    parameter MACRO_DIM  = 16,
    parameter SEARCH_DIM = 48
)

();

    localparam T = 10;

    integer i, j;

    logic [7:0] reference_picture [0:IMG_WIDTH*IMG_HEIGHT-1];
    logic [7:0] current_picture [0:IMG_WIDTH*IMG_HEIGHT-1];

    logic rst_n;
    logic clk;
    logic en_spr;
    logic en_cpr;
    logic [7:0]  pixel_spr_in [0:MACRO_DIM-1];
    logic [7:0]  pixel_cpr_in [0:MACRO_DIM-1];
    logic [15:0] sad;

    initial
    begin
        $readmemh("./memory/reference_picture.mem", reference_picture);
        $readmemh("./memory/current_picture.mem", current_picture);
    end

    initial 
    begin
        clk = 0;
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
        rst_n = 0;

        @(posedge clk);
        @(posedge clk);

        rst_n = 1;

        @(posedge clk);

        en_spr = 1;
        en_cpr = 1;

        for(i = 0; i < IMG_HEIGHT; i = i + 1)
        begin
            for(j = 0; j < MACRO_DIM; j = j + 1)
            begin
                pixel_cpr_in[j] = current_picture[j*IMG_HEIGHT+i];
                pixel_spr_in[j] = reference_picture[j*IMG_HEIGHT+i];
            end
            @(posedge clk);
        end

        #1000
        $finish;
    end

    initial 
    begin
        $dumpfile("tb_me.vcd");
        $dumpvars(0, tb_me);
    end

endmodule