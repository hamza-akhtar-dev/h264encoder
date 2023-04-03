module tb_me #
(
    parameter MACRO_DIM  = 16,
    parameter SEARCH_DIM = 48
)

();

    localparam T = 10;

    integer i, j;

    logic [7:0] curr_pixels   [0:MACRO_DIM*MACRO_DIM-1];
    logic [7:0] search_pixels [0:SEARCH_DIM*SEARCH_DIM-1];

    logic        rst_n;
    logic        clk;
    logic        start;
    logic [7:0]  pixel_spr_in     [0:MACRO_DIM];
    logic [7:0]  pixel_cpr_in     [0:MACRO_DIM-1];
    logic [15:0] min_sad;

    //debug

    logic [7:0] debug;

    initial
    begin
        $readmemh("./memory/curr_pixels.mem"  , curr_pixels  );
        $readmemh("./memory/search_pixels.mem", search_pixels);
    end

    assign debug = search_pixels[0];

    initial 
    begin
        clk = 0;
        forever #(T/2) clk = ~clk;
    end

    me # 
    (
        .MACRO_DIM  ( MACRO_DIM  ),
        .SEARCH_DIM ( SEARCH_DIM )
    )
    ins_me
    (
        .rst_n              ( rst_n              ),
        .clk                ( clk                ),
        .start              ( start              ),
        .pixel_spr_in       ( pixel_spr_in       ),
        .pixel_cpr_in       ( pixel_cpr_in       ),
        .valid              ( valid              ),
        .min_sad            ( min_sad            )
    );            

    initial
    begin
        rst_n = 0;
        start = 0;

        @(posedge clk);
        @(posedge clk);

        rst_n = 1;

        @(posedge clk);

        start = 1;

        @(posedge clk);

        start = 0;
        
        for(i = 0; i < MACRO_DIM; i = i + 1)
        begin
            for(j = 0; j < MACRO_DIM; j = j + 1)
            begin
                pixel_cpr_in[j] = curr_pixels[j*MACRO_DIM+i];
            end
            @(posedge clk);
        end

        for(i = 0; i < SEARCH_DIM; i = i + 1)
        begin
            for(j = 0; j < SEARCH_DIM; j = j + 1)
            begin
                pixel_spr_in[j % (MACRO_DIM + 1)] = search_pixels[j*SEARCH_DIM];
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