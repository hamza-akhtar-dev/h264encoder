module tb();

    logic CLK2;
    logic NEWSLICE;
    logic NEWLINE;
    logic STROBEI; 
    logic FBSTROBE;
    logic READYO;
    logic [7:0] FEEDBI; 
    logic [31:0] DATAI; 
    logic [31:0] TOPI;
    
    logic STROBEO;
    logic DCSTROBEO;
    logic READYI;
    logic XXC;
    logic XXINC;
    logic [1:0] XXO;
    logic [1:0] CMODEO;
    logic [15:0] DCDATAO;
    logic [31:0] BASEO;
    logic [35:0] DATAO;


h264intra8x8cc dut(
    .CLK2(CLK2), .NEWSLICE(NEWSLICE), .NEWLINE(NEWLINE),
    .STROBEI(STROBEI), .FBSTROBE(FBSTROBE), .READYO(READYO),
    .FEEDBI(FEEDBI), .DATAI(DATAI), .TOPI(TOPI),
    .STROBEO(STROBEO), .DCSTROBEO(DCSTROBEO), .READYI(READYI), 
    .XXC(XXC), .XXINC(XXINC), .XXO(XXO), .CMODEO(CMODEO), 
    .DCDATAO(DCDATAO), .BASEO(BASEO), .DATAO(DATAO)
);


localparam T = 10; // Clock Period

initial begin
    CLK2 = 0;
    forever #(T/2) CLK2=~CLK2;
end

initial begin
NEWSLICE = 0;
NEWLINE = 0;
STROBEI = 0;
FBSTROBE = 0;
READYO = 0;
FEEDBI = 0;
DATAI = 0;
TOPI = 0;
@(posedge CLK2);
FEEDBI = 8'h67;
DATAI = 32'h12345678;
TOPI = 32'h87654321;
@(posedge CLK2);
NEWSLICE = 1;
NEWLINE = 1;
STROBEI = 1;
FBSTROBE = 1;
READYO = 1;
end

endmodule