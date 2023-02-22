`timescale 10ns/10ps

module tb_pixel_addr();

    logic clk , rst, start;

    tb_pixel_addr dut 
    (
        .rst(rst), 
        .clk(clk), 
        .start(start) 
    );

    localparam T = 5;

    initial 
    begin
        clk = 0;
        forever #(T/2) clk =~ clk;
    end

    initial 
    begin
        rst = 1;
        #10
        rst = 0;
        #10
        start = 1;
        #10
        start = 0;
        #100;
    end

endmodule