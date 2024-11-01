module h264intra4x4 
(
   input logic CLK,                    // pixel clock
   input logic NEWSLICE,               // indication this is the first in a slice
   input logic NEWLINE,                // indication this is the first on a line
   input logic STROBEI,                // data here
   input logic [31:0] DATAI,
   output logic READYI,
   //  top interface:
   input logic [31:0] TOPI,            // top pixels (to predict against)
   input logic [3:0] TOPMI,            // top block's mode (for P/RMODEO)
   output logic [1:0] XXO = 2'b00,     // which macroblock X
   output logic XXINC = 1'b0,          // when to increment XX macroblock
   //  feedback interface:
   input logic [7:0] FEEDBI,           // feedback for pixcol
   input logic FBSTROBE,               // feedback valid
   //  out interface:
   output logic STROBEO = 1'b0,        // data here
   output logic [35:0] DATAO = 36'd0,
   output logic [31:0] BASEO = 32'd0,  // base for reconstruct
   input  logic READYO = 1'b1,
   output logic MSTROBEO = 1'b0,       // modeo here
   output logic [3:0] MODEO = 4'd0,    // 0..8 prediction type
   output logic PMODEO = 1'b0,         // prev_i4x4_pred_mode_flag
   output logic [2:0] RMODEO = 3'd0,   // rem_i4x4_pred_mode_flag
   output logic CHREADY = 1'b0         // ready line to chroma
);

//logic [31:0] counter = '0; 

logic [31:0] pix [63:0] = '{default : '0};
logic [7:0] pixleft [15:0] = '{default : '0};
logic [3:0] lmode [3:0] = '{default: 4'd9};  // lmode = 9       // doubt in this line 

logic lvalid            = '0;

logic tvalid            = '0;

logic dconly        = '0;

logic [31:0] topih = '0;

logic [31:0] topii = '0;

  
logic [5:0] statei = '0;

logic outf1    = '0;

logic outf = '0;

logic chreadyi           = '0;


logic chreadyii             = '0;

logic readyod = '0;

logic [3:0] submb = '0;

logic [1:0] xx = '0;
logic [1:0] yy = '0;
logic [3:0] yyfull = '0;
logic [7:0] pixleft_yyfull = '0; 

logic [1:0] oldxx = '0;

logic [3:0] fbptr = '0;

logic fbpending = '0;

logic [3:0] modeoi = '0;

logic [3:0] prevmode = '0;


logic [31:0] dat0 = '0;

logic [8:0] vdif0 = '0;
logic [8:0] vdif1 = '0;
logic [8:0] vdif2 = '0;
logic [8:0] vdif3 = '0;
//

logic [7:0] vabsdif0 = '0;
logic [7:0] vabsdif1 = '0;
logic [7:0] vabsdif2 = '0;
logic [7:0] vabsdif3 = '0;
logic [11:0] vtotdif = '0;
//


logic [7:0] leftp = '0;
logic [7:0] leftpd = '0;
logic [8:0] hdif0 = '0;
logic [8:0] hdif1 = '0;
logic [8:0] hdif2 = '0;
logic [8:0] hdif3 = '0;
logic [7:0] habsdif0 = '0;
logic [7:0] habsdif1 = '0;
logic [7:0] habsdif2 = '0;
logic [7:0] habsdif3 = '0;
logic [11:0] htotdif = '0;
//

logic [7:0] left0 = '0;
logic [7:0] left1 = '0;
logic [7:0] left2 = '0;
logic [7:0] left3 = '0;
logic [8:0] ddif0 = '0;
logic [8:0] ddif1 = '0;
logic [8:0] ddif2 = '0;
logic [8:0] ddif3 = '0;
logic [7:0] dabsdif0 = '0;
logic [7:0] dabsdif1 = '0;
logic [7:0] dabsdif2 = '0;
logic [7:0] dabsdif3 = '0;
logic [11:0] dtotdif = '0;
//



   
logic [9:0] sumt    = '0;
logic [9:0] suml    = '0;
logic [10:0] sumtl  = '0;
//


logic [9:0] sumt_n = '0;
logic [9:0] suml_n = '0;
logic [10:0] sumtl_n  = '0;
logic [1:0] sumtl_sel = '0;

logic [35:0] DATAO_n        = '0;
logic [31:0] BASEO_n        = '0;
logic [1:0] R_P_mode_sel    = '0;
logic [2:0] RMODEO_m        = '0;
logic PMODEO_m  = '0;
logic rst_0     = '0;
logic en_12     = '0;
logic xxo_sel   = '0;

logic totdif_en  = '0;
logic totdif_rst = '0;
logic lvalid_n          = '0;
logic [1:0] lvalid_sel  = '0;
logic tvalid_n          = '0;
logic [1:0] tvalid_sel  = '0;
logic dconly_n      = '0;
logic dconly_m      = '0;
logic dconly_sel2   = '0;
logic dconly_sel1   = '0;
logic     topih_en = '0;
logic [3:0] prevmode_n = '0;
logic [3:0] modeoi_m = '0;
logic [1:0] modeoi_sel = '0;
logic       modeoi_en = '0;
logic fbpending_n = '0;
logic [1:0] fbpending_sel = '0;
logic  fbptr_rst = '0;
logic    oldxx_en = '0;
logic submb_en ='0;
logic outf1_en = '0;
logic     topii_en = '0;
logic chreadyi_n         = '0;
logic [1:0] chreadyi_sel = '0;
logic chreadyii_n           = '0;
logic [1:0] chreadyii_sel   = '0;
logic [31:0] dat0_n = '0;
logic [8:0] vdif0_n = '0;
logic [8:0] vdif1_n = '0;
logic [8:0] vdif2_n = '0;
logic [8:0] vdif3_n = '0;

logic [7:0] vabsdif0_n = '0;
logic [7:0] vabsdif1_n = '0;
logic [7:0] vabsdif2_n = '0;
logic [7:0] vabsdif3_n = '0;
logic [11:0] vtotdif_n = '0;
logic [8:0] hdif0_n = '0;
logic [8:0] hdif1_n = '0;
logic [8:0] hdif2_n = '0;
logic [8:0] hdif3_n = '0;
logic [7:0] habsdif0_n = '0;
logic [7:0] habsdif1_n = '0;
logic [7:0] habsdif2_n = '0;
logic [7:0] habsdif3_n = '0;
logic [11:0] htotdif_n = '0;

logic [8:0] ddif0_n = '0;
logic [8:0] ddif1_n = '0;
logic [8:0] ddif2_n = '0;
logic [8:0] ddif3_n = '0;
logic [7:0] dabsdif0_n = '0;
logic [7:0] dabsdif1_n = '0;
logic [7:0] dabsdif2_n = '0;
logic [7:0] dabsdif3_n = '0;
logic [11:0] dtotdif_n = '0;

//int fo;
//int fi;
//initial
//begin
//    //fo = $fopen ("output_file_up.log", "w");
//    fi = $fopen ("input_file.log", "w");
//end

h264intra4x4_controller CONT
(
    CLK,
    READYO,
    readyod,
    FBSTROBE,
    fbpending,
    chreadyi,
    chreadyii,
    STROBEI,
    NEWLINE,
    NEWSLICE,
    outf1,
    outf,
    lvalid,
    tvalid,
    dconly,
    statei,
    submb, //xx,yy these also create here with submb
    modeoi,
    prevmode,
    vtotdif,
    htotdif,
    dtotdif,

    rst_0,
    oldxx_en,
    xxo_sel,
    topih_en,
    topii_en,
    totdif_en,
    totdif_rst,
    dconly_sel1,
    dconly_sel2,
    modeoi_en,
    en_12,
    outf1_en,
    submb_en,
    fbptr_rst,
    XXINC,
    CHREADY,
    READYI ,
    modeoi_sel,
    tvalid_sel,
    lvalid_sel,
    fbpending_sel,
    chreadyi_sel,
    chreadyii_sel,
    sumtl_sel,
    yyfull,
    R_P_mode_sel
);

// Memory part 
always_ff @(posedge CLK ) 
begin
//    $fdisplay(fi,"NEWSLICE <= %h; NEWLINE <= %h; STROBEI <= %h; DATAI <= 32'h%h;  TOPI <= 32'h%h; TOPMI <= 4'h%h; FEEDBI <= 8'h%h; FBSTROBE <= %h; READYO <= %h; time = %0t;
//@(posedge CLK);", NEWSLICE,NEWLINE, STROBEI, DATAI,TOPI, TOPMI,FEEDBI, FBSTROBE, READYO , $time);
    
    //counter <= counter + 1;
    
    //submb_counter
    if(submb_en) submb <= submb+1;
    else 		 submb <= submb;

    //fbptr counter
    if(fbptr_rst) 		fbptr <= {yy, 2'b00};
    else if (FBSTROBE)	fbptr <= fbptr + 1;
    else				fbptr <= fbptr;

    //statei_counter
    if(rst_0)	      statei <= 6'b000000;
    else if (STROBEI) statei <= statei + 1;
    else			  statei <= statei;

    //pixleft 8x16 mem
    //FBSTROBE-->work as write signal
    if (FBSTROBE)  pixleft[fbptr] <= FEEDBI;

    // pix 32x64 mem, write on STROBEI
    if (STROBEI) pix[statei] <= DATAI;

    //lmode 4x4, write on en_12
    if (en_12) lmode[yy] <= modeoi;

end

always_comb 
begin
    
    xx = {submb[2], submb[0]};
    yy = {submb[3], submb[1]};

    //output from pixlef mem
    left0 = pixleft[{yy, 2'b00}];
    left1 = pixleft[{yy, 2'b01}];
    left2 = pixleft[{yy, 2'b10}];
    left3 = pixleft[{yy, 2'b11}];

    suml_n = {2'b00, left0} + {2'b00, left1} +
           {2'b00, left2} + {2'b00, left3}; 

    pixleft_yyfull = pixleft[yyfull];

    dat0_n = pix[{yyfull, xx}];


    //sumt
    sumt_n = {2'b00, TOPI[7:0]  } + {2'b00, TOPI[15:8]} + 
             {2'b00, TOPI[23:16]} + {2'b00, TOPI[31:24]};

    //from lmode mem
    prevmode_n = (TOPMI < lmode[yy]) ? TOPMI : lmode[yy];

    case (tvalid_sel)
       2'h3, 2'h1: tvalid_n = 1'b0;
       2'h2 :      tvalid_n = 1'b1;
       2'h0 :      tvalid_n = tvalid;
    endcase

    case (lvalid_sel)
       2'h3, 2'h1: lvalid_n = 1'b0;
       2'h2 :      lvalid_n = 1'b1;
       2'h0 :      lvalid_n = lvalid;
    endcase

    case (fbpending_sel)
       2'h3, 2'h1: fbpending_n = 1'b0;
       2'h2 :      fbpending_n = 1'b1;
       2'h0 :      fbpending_n = fbpending;
    endcase

    case (chreadyi_sel)
       2'h3, 2'h1: chreadyi_n = 1'b0;
       2'h2 :      chreadyi_n = 1'b1;
       2'h0 :      chreadyi_n = chreadyi;
    endcase

    case (chreadyii_sel)
       2'h3, 2'h1: chreadyii_n = 1'b0;
       2'h2 :      chreadyii_n = 1'b1;
       2'h0 :      chreadyii_n = chreadyii;
    endcase

    dconly_m = dconly_sel2 ? 1'b0 : 1'b1;
    dconly_n = dconly_sel1  ? dconly_m: dconly;

end

//pipe_line_1
always_ff @(posedge CLK) 
begin
    //reg before pipeline
    if(outf1_en)   outf1 <= 1'b1;
    else           outf1 <= 1'b0;

    // TOPI_reg with en signal
    if(topih_en)
    begin
       topih    <= TOPI;
       sumt     <= sumt_n;
       prevmode <= prevmode_n;
    end
    else
    begin
       topih    <= topih   ;
       sumt     <= sumt    ;
       prevmode <= prevmode;
    end

    //Data pass from pipline
    suml     <= suml_n;
    dat0     <= dat0_n; 
    leftp    <= pixleft_yyfull;

    //controller signal pass from pipeline 
    //and goes to controller
    readyod     <= READYO;
    outf        <= outf1;
    tvalid      <= tvalid_n ;     
    lvalid      <= lvalid_n ;
    fbpending   <= fbpending_n ;      
    chreadyi    <= chreadyi_n ;
    chreadyii   <= chreadyii_n ;
    dconly      <= dconly_n ;


end

always_comb
begin
    case (sumtl_sel)
        2'b11: sumtl_n = {1'b0, sumt} + {1'b0, suml} + 4;
        2'b10: sumtl_n = {suml, 1'b0} + 4;			
        2'b01: sumtl_n = {sumt, 1'b0} + 4;
        2'b00: sumtl_n = {8'h80, 3'b000};
    endcase
end

always_ff @(posedge CLK) 
begin
    if(topii_en)
    begin
        sumtl <= sumtl_n;
        topii <= topih;
    end
end



always_comb
begin
    //pipeline_1
    vdif0_n = {1'b0, dat0[7:0]}   - {1'b0, topii[7:0]};
    vdif1_n = {1'b0, dat0[15:8]}  - {1'b0, topii[15:8]};
    vdif2_n = {1'b0, dat0[23:16]} - {1'b0, topii[23:16]};
    vdif3_n = {1'b0, dat0[31:24]} - {1'b0, topii[31:24]};
    
    hdif0_n = {1'b0, dat0[7:0]}   - {1'b0, leftp};
    hdif1_n = {1'b0, dat0[15:8]}  - {1'b0, leftp};
    hdif2_n = {1'b0, dat0[23:16]} - {1'b0, leftp};
    hdif3_n = {1'b0, dat0[31:24]} - {1'b0, leftp};
    
    ddif0_n = {1'b0, dat0[7:0]}   - {1'b0, sumtl[10:3]};
    ddif1_n = {1'b0, dat0[15:8]}  - {1'b0, sumtl[10:3]};
    ddif2_n = {1'b0, dat0[23:16]} - {1'b0, sumtl[10:3]};
    ddif3_n = {1'b0, dat0[31:24]} - {1'b0, sumtl[10:3]};
end


//pipeline 2
always_ff @(posedge CLK) 
begin
   //pipeline_1
    vdif0 <= vdif0_n;
    vdif1 <= vdif1_n;
    vdif2 <= vdif2_n;
    vdif3 <= vdif3_n;
    
    hdif0 <= hdif0_n;
    hdif1 <= hdif1_n;
    hdif2 <= hdif2_n;
    hdif3 <= hdif3_n;
    leftpd <= leftp;
    
    ddif0 <= ddif0_n;
    ddif1 <= ddif1_n;
    ddif2 <= ddif2_n;
    ddif3 <= ddif3_n;
end

always_comb
begin
    if (vdif0[8])  vabsdif0_n = 8'h00 - vdif0[7:0];
    else           vabsdif0_n = vdif0[7:0];
    if (vdif1[8])  vabsdif1_n = 8'h00 - vdif1[7:0];
    else           vabsdif1_n = vdif1[7:0];
    if (vdif2[8])  vabsdif2_n = 8'h00 - vdif2[7:0];
    else           vabsdif2_n = vdif2[7:0];
    if (vdif3[8])  vabsdif3_n = 8'h00 - vdif3[7:0];
    else           vabsdif3_n = vdif3[7:0];


    if (hdif0[8])  habsdif0_n = 8'h00 - hdif0[7:0];
    else           habsdif0_n = hdif0[7:0];	
    if (hdif1[8])  habsdif1_n = 8'h00 - hdif1[7:0];
    else           habsdif1_n = hdif1[7:0];	
    if (hdif2[8])  habsdif2_n = 8'h00 - hdif2[7:0];
    else           habsdif2_n = hdif2[7:0];	
    if (hdif3[8])  habsdif3_n = 8'h00 - hdif3[7:0];
    else           habsdif3_n = hdif3[7:0];	
   

    if (ddif0[8])  dabsdif0_n = 8'h00 - ddif0[7:0];
    else           dabsdif0_n = ddif0[7:0];
    if (ddif1[8])  dabsdif1_n = 8'h00 - ddif1[7:0];
    else           dabsdif1_n = ddif1[7:0];
    if (ddif2[8])  dabsdif2_n = 8'h00 - ddif2[7:0];
    else           dabsdif2_n = ddif2[7:0];	
    if (ddif3[8]) dabsdif3_n = 8'h00 - ddif3[7:0];
    else           dabsdif3_n = ddif3[7:0];
end

always_ff @(posedge CLK )
begin
    vabsdif0 <= vabsdif0_n;
    vabsdif1 <= vabsdif1_n;
    vabsdif2 <= vabsdif2_n;
    vabsdif3 <= vabsdif3_n;
    
    habsdif0 <= habsdif0_n;
    habsdif1 <= habsdif1_n;
    habsdif2 <= habsdif2_n;
    habsdif3 <= habsdif3_n;
    
    dabsdif0 <= dabsdif0_n;
    dabsdif1 <= dabsdif1_n;
    dabsdif2 <= dabsdif2_n;
    dabsdif3 <= dabsdif3_n;
end

always_comb
begin
    vtotdif_n = {8'h0, vabsdif0} + {8'h0, vabsdif1} +
                {8'h0, vabsdif2} + {8'h0, vabsdif3} + vtotdif;
    htotdif_n = {8'h0, habsdif0} + {8'h0, habsdif1} +
                {8'h0, habsdif2} + {8'h0, habsdif3} + htotdif;
    dtotdif_n = {8'h0, dabsdif0} + {8'h0, dabsdif1} +
                {8'h0, dabsdif2} + {8'h0, dabsdif3} + dtotdif;

    case (modeoi_sel)
        2'h3, 2'h2:    modeoi_m = 4'h2;
        2'h1:          modeoi_m = 4'h1;
        2'h0:          modeoi_m = 4'h0;
    endcase
end

//Dif REG and modeoi-REG
always_ff @(posedge CLK)
begin
    if(totdif_rst)
    begin 
        vtotdif <= '0;
        htotdif <= '0;
        dtotdif <= '0;
    end
    else
    begin 

        if(totdif_en)
        begin 
            vtotdif <= vtotdif_n;
            htotdif <= htotdif_n;
            dtotdif <= dtotdif_n;
        end
        else 
        begin
            vtotdif <= vtotdif;
            htotdif <= htotdif;
            dtotdif <= dtotdif;         
        end

    end

    if(modeoi_en) modeoi <= modeoi_m;
    else          modeoi <= modeoi;

end

always_comb 
begin
    case (modeoi)
        4'h0: 
        begin //....
            DATAO_n = {vdif3, vdif2, vdif1, vdif0};
            BASEO_n = topii;
        end
        4'h1: 
        begin 
            DATAO_n = {hdif3, hdif2, hdif1, hdif0};
            BASEO_n = {leftpd, leftpd, leftpd, leftpd};
        end
        4'h2:
        begin
            DATAO_n = {ddif3, ddif2, ddif1, ddif0};
            BASEO_n = {sumtl[10:3], sumtl[10:3], sumtl[10:3], sumtl[10:3]}; 
        end
        default:
        begin 
            DATAO_n = '0;
            BASEO_n = '0;
        end
    endcase

    case (R_P_mode_sel)
        2'b00: RMODEO_m = modeoi[2:0] - 1;
        2'b01: RMODEO_m = modeoi[2:0];
        2'b10, 2'b11: RMODEO_m = RMODEO;
    endcase

    PMODEO_m = (R_P_mode_sel[1]) ? 1'b1: 1'b0;

end

//output reg's
always_ff @(posedge CLK)
begin

    if(outf)
    begin
        DATAO    <= DATAO_n;
        BASEO    <= BASEO_n;
        MSTROBEO <= ~outf1;
    end
    else
    begin   
        DATAO    <= DATAO   ;
        BASEO    <= BASEO   ;
        MSTROBEO <= 1'b0    ;
    end


    if(en_12)
    begin
        RMODEO <= RMODEO_m;
        PMODEO <= PMODEO_m;
    end
    else
    begin
        RMODEO <= RMODEO;
        PMODEO <= PMODEO;
    end

    //STROBEO
    if(rst_0)   STROBEO <= 1'b0;
    if (outf)   STROBEO <= 1'b1;
    else        STROBEO <= 1'b0;

    //OLDXX
    if (oldxx_en) oldxx <= xx;
    else          oldxx <= oldxx;
//    $fdisplay(fo,"READYI <= %h; XXO <= 2'h%h; XXINC <= %h; STROBEO <= %h; DATAO <= 36'h%h; BASEO <= 32'h%h; MSTROBEO <= %h; MODEO <= 4'h%h; PMODEO <= %h; RMODEO <= 3'h%h; CHREADY <= %h; 
//@(posedge CLK);",READYI, XXO , XXINC , STROBEO , DATAO , BASEO , MSTROBEO , MODEO , PMODEO, RMODEO ,CHREADY);
/*
$fdisplay(fi,"counter = %d, lvalid = %h; tvalid = %h; dconly = %h; outf1 = %h; outf = %h; chreadyi = %h; chreadyii = %h; readyod = %h; fbpending = %h;
xx = 2'h%h; yy = 2'h%h; oldxx = 2'h%h;
submb = 3'h%h; yyfull = 3'h%h; fbptr = 3'h%h; modeoi = 3'h%h; prevmode = 3'h%h; statei = 6'h%h;
vabsdif0 = 8'h%h; vabsdif1 = 8'h%h; vabsdif2 = 8'h%h; vabsdif3 = 8'h%h; leftp = 8'h%h; leftpd = 8'h%h; habsdif0 = 8'h%h; 
habsdif1 = 8'h%h; habsdif2 = 8'h%h; habsdif3 = 8'h%h; vdif0 = 9'h%h; vdif1 = 9'h%h; vdif2 = 9'h%h; vdif3 = 9'h%h; 
hdif0 = 9'h%h; hdif1 = 9'h%h; hdif2 = 9'h%h; hdif3 = 9'h%h; ddif0 = 9'h%h; ddif1 = 9'h%h; ddif2 = 9'h%h; ddif3 = 9'h%h;
sumt = 10'h%h; suml = 10'h%h; sumtl = 11'h%h; topih = 32'h%h; topii = 32'h%h;",counter ,lvalid, tvalid, dconly, outf1, outf, chreadyi, chreadyii, readyod, fbpending,
xx, yy, oldxx, submb, yyfull, fbptr, modeoi, prevmode, statei,
vabsdif0, vabsdif1, vabsdif2, vabsdif3, leftp, leftpd, habsdif0, habsdif1, habsdif2, habsdif3,
vdif0, vdif1, vdif2, vdif3, hdif0, hdif1, hdif2, hdif3, ddif0, ddif1, ddif2, ddif3,
sumt, suml, sumtl, topih, topii);
*/
end

//output
always_comb 
begin
    XXO      = xxo_sel ? xx: oldxx;
    MODEO    = modeoi;
end

    
endmodule  