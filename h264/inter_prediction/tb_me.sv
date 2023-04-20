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
    logic [5:0]  addr;
    logic [5:0]  amt;
    logic [7:0]  pixel_spr_in [0:MACRO_DIM];
    logic [7:0]  pixel_cpr_in [0:MACRO_DIM-1];
    logic [15:0] min_sad;

    logic [15:0] trans_addr [MACRO_DIM:0];
    logic [15:0] addr0, addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8, addr9, 
    addr10, addr11, addr12, addr13, addr14, addr15, addr16; //debug
    assign addr0 = trans_addr[0];
    assign addr1 = trans_addr[1];
    assign addr2 = trans_addr[2];
    assign addr3 = trans_addr[3];
    assign addr4 = trans_addr[4];
    assign addr5 = trans_addr[5];
    assign addr6 = trans_addr[6];
    assign addr7 = trans_addr[7];
    assign addr8 = trans_addr[8];
    assign addr9 = trans_addr[9];
    assign addr10 = trans_addr[10];
    assign addr11 = trans_addr[11];
    assign addr12 = trans_addr[12];
    assign addr13 = trans_addr[13];
    assign addr14 = trans_addr[14];
    assign addr15 = trans_addr[15];
    assign addr16 = trans_addr[16];

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
        .addr               ( addr               ),
        .amt                ( amt                ),
        .min_sad            ( min_sad            )
    );

    // Simulating RAM

    always_comb
    begin
        for(l = 0; l < MACRO_DIM; l++)
        begin
            pixel_cpr_in[l] = c_bram[l][addr];
        end
        for(l = 0; l < PORT_WIDTH; l++)
        begin
            pixel_spr_in[l] = s_bram[(l+amt)%PORT_WIDTH][trans_addr[(l+amt)%PORT_WIDTH]];
            //pixel_spr_in[l] = s_bram[l][trans_addr[g]]
            //pixel_spr_in[l] = s_bram[(l+amt)%PORT_WIDTH][((l+amt) > 17) ? amt*SEARCH_DIM+addr : (amt-1)*SEARCH_DIM + addr];
            //pixel_spr_in[l] = s_bram[(l+amt)%PORT_WIDTH][((l+amt) > 16)  ? (amt)*SEARCH_DIM+addr : SEARCH_DIM];
            
        end
    end

    logic [7:0] value;
    assign value = s_bram[0][79];

    //Address Translation
    // 0->48 32
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


        #10000 // use this for simulation for now. Until you are sure that every signal is behaving fine.

        //wait(done == 1); // done is never being asserted so simulation is stuck at wait and is never reaching to $finish.

        @(posedge clk);
        $finish;
    end

    initial 
    begin
        $dumpfile("tb_me.vcd");
        $dumpvars(0, tb_me);
    end

endmodule