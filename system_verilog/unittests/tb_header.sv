module tb_header();

    logic CLK, VALID, NEWSLICE, LASTSLICE, SINTRA, MINTRA, LSTROBE, CSTROBE, PMODE;
    logic [11:0] MVDX, MVDY;
    logic [5:0] QP;
    logic [4:0] VL;
    logic [19:0] VE;
    logic [2:0] RMODE;
    logic [1:0] CMODE, PTYPE, PSUBTYPE;

h264header uut (.CLK(CLK), .VALID(VALID), .NEWSLICE(NEWSLICE), .LASTSLICE(LASTSLICE),
                .SINTRA(SINTRA), .MINTRA(MINTRA), .LSTROBE(LSTROBE), .CSTROBE(CSTROBE), 
                .PMODE(PMODE), .MVDX(MVDX), .MVDY(MVDY), .QP(QP), .VL(VL), .VE(VE),
                .RMODE(RMODE), .CMODE(CMODE), .PTYPE(PTYPE), .PSUBTYPE(PSUBTYPE));

localparam T = 10; // Clock Period

initial begin
    CLK = 0;
    forever #(T/2) CLK=~CLK;
end

initial begin
NEWSLICE = 0;
LASTSLICE = 0;
SINTRA = 0;
MINTRA = 0;
LSTROBE =0;
CSTROBE =0;
QP=0;
PMODE =0;
RMODE =0;
CMODE =0;
PTYPE =0;
PSUBTYPE =0;
MVDX =0;
MVDY=0;
@(posedge CLK);
NEWSLICE = 1;
QP = 32;
MINTRA =1;
LSTROBE=1;
PMODE =1;
RMODE =1;
CMODE =1;
PTYPE =2;
MVDX =234;
MVDY =876;

end

endmodule