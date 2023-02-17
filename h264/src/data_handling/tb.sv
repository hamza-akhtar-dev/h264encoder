module tb();

logic clk , reset, start;

stg dut (.clk(clk), .reset(reset), .start(start) );
localparam T = 2; // Clock Period

initial begin
    clk = 0;
    forever #(T/2) clk=~clk;
end

initial begin
reset = 1;
@(posedge clk);
@(posedge clk);
reset = 0;
start = 1;
#1000;

end

endmodule