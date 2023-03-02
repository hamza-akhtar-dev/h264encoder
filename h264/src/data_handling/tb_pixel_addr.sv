`timescale 1ns/10ps

module tb_pixel_addr();

    logic clk , rst, start;

    logic [31:0] x_out, y_out;

    pixel_addr dut 
    (
        .x_out(x_out),
        .y_out(y_out),
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
        #5000;
        $finish;
    end

    initial begin
        $dumpfile("tb_pixel_addr.vcd");
        $dumpvars(0, tb_pixel_addr);
    end

endmodule