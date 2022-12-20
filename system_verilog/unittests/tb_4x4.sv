module tb_4x4();

    logic CLK;
    logic NEWSLICE;
    logic NEWLINE;
    logic STROBEI; 
    logic [31:0] DATAI;
    logic READYI;
    logic [31:0] TOPI;
    logic [3:0] TOPMI;
    logic [1:0] XXO;
    logic XXINC;
    logic [7:0] FEEDBI;   
    logic FBSTROBE;
    logic STROBEO;    
    logic [35:0] DATAO;
    logic [31:0] BASEO;
    logic READYO;
    logic MSTROBEO;
    logic [3:0] MODEO;
    logic PMODEO;
    logic [2:0] RMODEO;
    logic CHREADY;


h264intra4x4 dut(
    .CLK(CLK), .NEWSLICE(NEWSLICE), .NEWLINE(NEWLINE),
    .STROBEI(STROBEI), .FBSTROBE(FBSTROBE), .READYO(READYO),
    .FEEDBI(FEEDBI), .DATAI(DATAI), .TOPI(TOPI), .TOPMI(TOPMI),
    .STROBEO(STROBEO), .MSTROBEO(MSTROBEO), .READYI(READYI), 
    .XXINC(XXINC), .XXO(XXO), 
    .BASEO(BASEO), .DATAO(DATAO), .MODEO(MODEO), .PMODEO(PMODEO),
    .RMODEO(RMODEO), .CHREADY(CHREADY)
);


localparam T = 10; // Clock Period

initial begin
    CLK = 0;
    forever #(T/2) CLK=~CLK;
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
TOPMI = 0;
@(posedge CLK);
FEEDBI = 8'h67;
DATAI = 32'h12345678;
TOPI = 32'h87654321;
TOPMI = 4'h6;
@(posedge CLK);
NEWSLICE = 1;
NEWLINE = 1;
STROBEI = 1;
FBSTROBE = 1;
READYO = 1;
end

endmodule