module tb_tobytes();

    logic CLK, VALID, READY, STROBE, DONE;
    logic [24:0] VE;
    logic [4:0] VL;
    logic [7:0] BYTE;   


h264tobytes dut(
    .CLK(CLK), .VALID(VALID), .READY(READY), .VE(VE), .VL(VL),
    .STROBE(STROBE), .DONE(DONE), .BYTE(BYTE)
);


localparam T = 10; // Clock Period

initial begin
    CLK = 0;
    forever #(T/2) CLK=~CLK;
end

initial begin
VALID = 0;
VE = 0;
VL = 0;
@(posedge CLK);
VE = 25'd56789;
VL = 5'd25;
VALID = 1;

end

endmodule