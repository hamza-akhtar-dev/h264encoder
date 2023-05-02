module tb_me #
(
    parameter MACRO_DIM  = 16,
    parameter SEARCH_DIM = 48
)

();

    localparam T = 10;
    localparam PORT_WIDTH = MACRO_DIM + 1;

    integer i, j, k, l, m, f, g;

    logic [7:0] curr_picture   [MACRO_DIM][MACRO_DIM];
    logic [7:0] search_picture [SEARCH_DIM][SEARCH_DIM];

    initial
    begin
        $readmemh("./memory/curr_picture.mem", curr_picture);
        $readmemh("./memory/search_picture.mem", search_picture);
    end

    // Initializing Block Rams

    reg [7:0] c_bram [MACRO_DIM ][MACRO_DIM                        ];
    reg [7:0] s_bram [PORT_WIDTH][SEARCH_DIM*(SEARCH_DIM/MACRO_DIM)];

    initial
    begin
        for(i = 0; i < MACRO_DIM; i++)
        begin
            for(j = 0; j < MACRO_DIM; j++)
            begin
                c_bram[i][j] = curr_picture[j][i];
            end
        end

        for(i = 0; i < PORT_WIDTH; i++)
        begin
            for(k = 0; k < SEARCH_DIM/MACRO_DIM; k++)
            begin
                for(j = 0; j < SEARCH_DIM; j++)
                begin
                    s_bram[i][k*SEARCH_DIM+j] = search_picture[j][k*PORT_WIDTH+i];
                end
            end
        end
    end

    // Signals

    logic        rst_n;
    logic        clk;
    logic        start;
    logic        en_ram;
    logic        done;
    logic [5:0]  addr;
    logic [5:0]  amt;
    logic [5:0]  mv_y;
    logic [5:0]  mv_x;
    logic [7:0]  pixel_spr_in [0:MACRO_DIM];
    logic [7:0]  pixel_cpr_in [0:MACRO_DIM-1];
    logic [15:0] min_sad;

    logic [15:0] trans_addr [MACRO_DIM:0];

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
        .ready              ( ready              ),
        .valid              ( valid              ),
        .en_ram             ( en_ram             ),
        .done               ( done               ),
        .addr               ( addr               ),
        .amt                ( amt                ),
        .mv_x               ( mv_x               ),
        .mv_y               ( mv_y               ),
        .min_sad            ( min_sad            )
    );

    // Simulating RAM

    always_comb
    begin
        for(l = 0; l < MACRO_DIM; l++)
        begin
            if (en_ram)
            begin
                pixel_cpr_in[l] = c_bram[l][addr];
            end
        end
        for(l = 0; l < PORT_WIDTH; l++)
        begin
            if (en_ram)   
            begin         
                pixel_spr_in[l] = s_bram[(l+amt)%PORT_WIDTH][trans_addr[(l+amt)%PORT_WIDTH]];
            end
        end
    end

    always_comb
    begin
        for (f = 0; f < PORT_WIDTH; f++) 
        begin
            if (f < amt) 
            begin
                trans_addr[f] = addr + SEARCH_DIM;
            end
            else
            begin
                trans_addr[f] = addr;
            end
        end
    end           

    initial
    begin
        rst_n = 0;
        start = 0;
        @(posedge clk);
        rst_n = 1;

        @(posedge clk);
       
        start = 1;
    
        @(posedge clk);

        start = 0;


        //#12000 
        wait (done == 1)
        @(posedge clk);
        $finish;
    end

    initial 
    begin
        $dumpfile("tb_me.vcd");
        $dumpvars(0, tb_me);
    end

endmodule