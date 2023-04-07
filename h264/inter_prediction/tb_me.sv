module tb_me #
(
    parameter MACRO_DIM  = 16,
    parameter SEARCH_DIM = 48
)

();

    localparam T = 10;

    localparam PORT_WIDTH = MACRO_DIM + 1;

    integer i, j, k;

    logic [7:0] curr_pixels   [0:MACRO_DIM*MACRO_DIM-1];
    logic [7:0] search_pixels [0:SEARCH_DIM*SEARCH_DIM-1];

    logic        rst_n;
    logic        clk;
    logic        start;
    logic [7:0]  pixel_spr_in     [0:MACRO_DIM];
    logic [7:0]  pixel_cpr_in     [0:MACRO_DIM-1];
    logic [15:0] min_sad;
    logic        en_ram;

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
        .en_ram             ( en_ram             ),
        .valid              ( valid              ),
        .ready              ( ready              ),
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

        wait(ready == 1);

        start = 1;

        @(posedge clk);

        fork

            begin
                #10000;
                $finish;
            end
            
            begin   
                wait (en_ram == 1);
                for(j = 0; j < MACRO_DIM; j = j + 1)
                begin
                    pixel_cpr_in[j] = curr_pixels[j*MACRO_DIM];
                end
            end

            begin
            
                // for(k = 0; k < PORT_WIDTH; k = k + 1)
                // begin
                //     pixel_spr_in[k] = search_pixels[k*SEARCH_DIM];
                //     if( $isunknown(pixel_spr_in[k]))
                //     begin
                //         pixel_spr_in[k] = 8'd0;
                //     end
                // end

                // #(23*T);

                // for(i = 0; i < 16; i = i + 1)
                // begin
                    wait (en_ram == 1);
                    for(k = 0; k < PORT_WIDTH; k = k + 1)
                    begin
                        pixel_spr_in[k] = search_pixels[k*SEARCH_DIM];
                        if( $isunknown(pixel_spr_in[k]))
                        begin
                            pixel_spr_in[k] = 8'd0;
                        end
                    end
                    @(posedge clk);
                //end
                // @(posedge clk);

                // for(k = 0; k < PORT_WIDTH; k = k + 1)
                // begin
                //     pixel_spr_in[k] = search_pixels[(34+k)*SEARCH_DIM];
                //     if( $isunknown(pixel_spr_in[k]))
                //     begin
                //         pixel_spr_in[k] = 8'd0;
                //     end
                // end

                // for(i = 0; i < SEARCH_DIM; i = i + 1)
                // begin
                //     for(j = 0; j < SEARCH_DIM; j = j + 1)
                //     begin
                //         if( (j % PORT_WIDTH) == 0 )
                //         begin
                //             for(k = 0; k < PORT_WIDTH; k = k + 1)
                //             begin
                //                 pixel_spr_in[k] = search_pixels[(j+k)*SEARCH_DIM+i];
                //                 if( $isunknown(pixel_spr_in[k]))
                //                 begin
                //                     pixel_spr_in[k] = 8'd0;
                //                 end
                //             end
                //             @(posedge clk);
                //         end
                //     end
                //     //@(posedge clk);
                // end
            end
        join
    end

    initial 
    begin
        $dumpfile("tb_me.vcd");
        $dumpvars(0, tb_me);
    end

endmodule