module h264intra4x4_tb;

logic        clk,  top_NEWSLICE,  top_NEWLINE,  intra4x4_STROBEI;
logic [31:0] intra4x4_DATAI,  intra4x4_TOPI;
logic [3:0]  intra4x4_TOPMI;
logic [7:0]  feedbi;
logic        recon_FBSTROBE, intra4x4_READYO;

logic intra4x4_READYI, intra4x4_XXINC, intra4x4_STROBEO, intra4x4_CHREADY, intra4x4_PMODEO, intra4x4_MSTROBEO;
logic [1:0]  intra4x4_XXO;
logic [35:0] intra4x4_DATAO;
logic [31:0] intra4x4_BASEO;
logic [2:0]  intra4x4_RMODEO;
logic [3:0]  intra4x4_MODEO;

h264intra4x4 UUT
(
    .CLK(clk), 
    .NEWSLICE(top_NEWSLICE), 
    .NEWLINE(top_NEWLINE),
    .STROBEI(intra4x4_STROBEI),
    .DATAI(intra4x4_DATAI), 
    .READYI(intra4x4_READYI),
    .TOPI(intra4x4_TOPI), 
    .TOPMI(intra4x4_TOPMI), 
    .XXO(intra4x4_XXO),
    .XXINC(intra4x4_XXINC), 
    .FEEDBI(feedbi), //recon_FEEDB[31:24]
    .FBSTROBE(recon_FBSTROBE),
    .STROBEO(intra4x4_STROBEO), 
    .DATAO(intra4x4_DATAO), 
    .BASEO(intra4x4_BASEO),
    .READYO(intra4x4_READYO),
    .MSTROBEO(intra4x4_MSTROBEO),
    .MODEO(intra4x4_MODEO), 
    .PMODEO(intra4x4_PMODEO),
    .RMODEO(intra4x4_RMODEO), 
    .CHREADY(intra4x4_CHREADY)
);

initial
begin
clk <= 0;
forever #5 clk <= ~clk;
end

initial
begin 
    
    top_NEWSLICE<=1;  top_NEWLINE<=1;  intra4x4_STROBEI<=0;  recon_FBSTROBE<=1; intra4x4_READYO<=1;
    intra4x4_DATAI<=32'h47;  intra4x4_TOPI<=32'h36;
    intra4x4_TOPMI<=4'h1;   feedbi<=8'h28;
    repeat(3)@(posedge CLK);

    top_NEWSLICE<=0;  top_NEWLINE<=1;  intra4x4_STROBEI<=0;  recon_FBSTROBE<=1; intra4x4_READYO<=1;
    intra4x4_DATAI<=32'h47;  intra4x4_TOPI<=32'h36;
    intra4x4_TOPMI<=4'h1;   feedbi<=8'h28;
    repeat(3)@(posedge CLK);

   top_NEWSLICE<=0;  top_NEWLINE<=0;  intra4x4_STROBEI<=1;  recon_FBSTROBE<=1; intra4x4_READYO<=1;
   intra4x4_DATAI<=32'h47;  intra4x4_TOPI<=32'h36;
   intra4x4_TOPMI<=4'h1;   feedbi<=8'h28;
   repeat(20)@(posedge CLK);

   recon_FBSTROBE<=0;
   repeat(300)@(posedge CLK);

   $stop;
end

endmodule