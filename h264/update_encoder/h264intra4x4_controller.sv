module h264intra4x4_controller
(
    input logic CLK,
    input logic READYO,
    input logic readyod,
    input logic FBSTROBE,
    input logic fbpending,
    input logic chreadyi,
    input logic chreadyii,
    input logic STROBEI,
    input logic NEWLINE,
    input logic NEWSLICE,
    input logic outf1,
    input logic outf,
    input logic lvalid,
    input logic tvalid,
    input logic dconly,
    input logic [5:0] statei,
    input logic [3:0] submb, //xx,yy these also create here with submb
    input logic [3:0] modeoi,
    input logic [3:0] prevmode,
    input logic [11:0] vtotdif,
    input logic [11:0] htotdif,
    input logic [11:0] dtotdif,

    output logic rst_0 = '0,
    output logic oldxx_en = '0,
    output logic xxo_sel = '0,
    output logic topih_en = '0,
    output logic topii_en = '0,
    output logic totdif_en = '0,
    output logic totdif_rst = '0,
    output logic dconly_sel1 = '0,
    output logic dconly_sel2 = '0,
    output logic modeoi_en = '0,
    output logic en_12 = '0,
    output logic outf1_en = '0,
    output logic submb_en = '0,
    output logic fbptr_rst = '0,
    output logic XXINC = '0,
    output logic CHREADY = '0,
    output logic READYI  = '0,
    output logic [1:0] modeoi_sel = '0,
    output logic [1:0] tvalid_sel = '0,
    output logic [1:0] lvalid_sel = '0,
    output logic [1:0] fbpending_sel = '0,
    output logic [1:0] chreadyi_sel = '0,
    output logic [1:0] chreadyii_sel = '0,
    output logic [1:0] sumtl_sel = '0,
    output logic [3:0] yyfull = '0,
    output logic [1:0] R_P_mode_sel = '0
);

logic [1:0] xx      = '0;
logic [1:0] yy      = '0;
logic l_xx    = '0;
logic t_yy    = '0;
logic [4:0] c_state = '0;
logic [4:0] n_state = '0;
logic fbpending_en  = '0;
logic chreadyi_en   = '0;

parameter S0    =   5'd0;
parameter S1    =   5'd1;
parameter S2    =   5'd2;
parameter S3    =   5'd3;
parameter S4    =   5'd4;
parameter S5    =   5'd5;
parameter S6    =   5'd6;
parameter S7    =   5'd7;
parameter S8    =   5'd8;
parameter S9    =   5'd9;
parameter S10   =   5'd10;
parameter S11   =   5'd11;
parameter S12   =   5'd12;
parameter S13   =   5'd13;
parameter S14   =   5'd14;
parameter S15   =   5'd15;
parameter S16   =   5'd16;
parameter S17   =   5'd17;
parameter S18   =   5'd18;
parameter S19   =   5'd19;
parameter S20   =   5'd20;


//state register
always_ff @ (posedge CLK)
begin
    //reset is active high or posedge reset
    if (!STROBEI & NEWLINE) c_state <= S0;
    else                    c_state <= n_state;
end

//next_state always block
always_comb
begin
    case (c_state)
        S0:
        begin 
            if (statei == 0) n_state = S0;
            else             n_state = S1 ; 
        end

        S1:
        begin 
            n_state = S2;
        end

        S2:
        begin 
            n_state = S3;
        end

        S3:
        begin 
            if (statei[5:4] == yy ) n_state = S3; 
            else                    n_state = S4 ;
        end

        S4:
        begin 
            n_state = S5;
        end

        S5:
        begin 
            n_state = S6 ; 
        end

        S6:
        begin 
            n_state = S7;
        end

        S7:
        begin 
            n_state = S8;            
        end
        S8:
        begin 
            n_state = S9;
        end
        S9:
        begin 
            n_state = S10;    
        end
        S10:
        begin 
            n_state = S11;
        end
        S11:
        begin 
            if((!READYO || FBSTROBE || fbpending)) 
                n_state = S11;
            else
                n_state = S12;
        end
        S12:
        begin 
            n_state = S13;    
        end
        S13:
        begin 
            n_state = S14;    
        end
        S14:
        begin 
            n_state = S15;    
        end
        S15:
        begin
            if(xx[0] && submb != 15) 
                n_state = S2;
            else
                n_state = S16;
        end
        S16:
        begin 
            n_state = S17;
        end
        S17:
        begin 
            n_state = S18;
        end
        S18:
        begin 
            n_state = S19;
        end
        S19:
        begin 
            if((FBSTROBE || fbpending || chreadyi || chreadyii))
                n_state = S19;
            else if(submb != 0)
                n_state = S3;
            else
                n_state = S20;
        end
        S20:
        begin 
            n_state = S0;
        end

        default: 
        begin
            n_state = S0;    
        end
    endcase
end


//Output logic 
always_comb 
begin
    xx           = {submb[2], submb[0]};
    yy           = {submb[3], submb[1]};
    t_yy         = (tvalid || yy != 0); // 0 0
    l_xx         = (lvalid || xx != 0); // 0 1
    sumtl_sel    = {l_xx, t_yy};
    dconly_sel2  = l_xx && t_yy;
    yyfull       = {yy, c_state[1:0]};
    R_P_mode_sel = {(dconly || prevmode == modeoi), (modeoi < prevmode)};
    READYI       = ((statei[5:4] != (yy - 2'b10)) && (statei[5:4] != (yy - 2'b01))) ? 1'b1 : 1'b0;
    XXINC        = 1'b0;
    CHREADY      = chreadyii && READYO;

    case (c_state)
        S0:
        begin 
            XXINC = 1'b0;
            if(!STROBEI & NEWLINE) rst_0 = 1'b1;
            else                   rst_0 = 1'b0;
        end

        S1:
        begin
            rst_0    = 1'b0;
            oldxx_en = 1'b1;
        end

        S2:
        begin 
            fbptr_rst= 1'b0;
            outf1_en = 1'b0;
            submb_en = 1'b0;
            oldxx_en = 1'b0;
            fbpending_en  = 1'b0;
            chreadyi_en = 1'b0;
            xxo_sel  = 1'b1;
            topih_en = 1'b1;
        end

        S3:
        begin 
            XXINC = 1'b0;
            xxo_sel  = 1'b0;
            topih_en = 1'b0;
            topii_en = 1'b1;
        end

        S4:
        begin 
            topii_en = 1'b0;     
        end

        S5:
        begin  
        end

        S6:
        begin 
            totdif_rst  = 1'b1;
            dconly_sel1 = 1'b1;
        end

        S7:
        begin 
            totdif_rst  = 1'b0;
            dconly_sel1 = 1'b0;
            totdif_en   = 1'b1;
        end

        S8:
        begin 
            totdif_en = 1'b1;
        end

        S9:
        begin 
            totdif_en = 1'b1;
        end

        S10:
        begin 
            totdif_en = 1'b1;
        end

        S11:
        begin
            totdif_en = 1'b0;
            modeoi_en = 1'b1;
            if (vtotdif <= htotdif && vtotdif <= dtotdif && !dconly) 
                modeoi_sel = 2'h0;		
            else if (htotdif <= dtotdif && !dconly) 
                modeoi_sel = 2'h1;		
            else
                modeoi_sel = 2'h2;		
        end

        S12:
        begin 
            modeoi_en = 1'b0;
            en_12     = 1'b1;
            outf1_en  = 1'b1;
        end

        S13:
        begin 
            en_12    = 1'b0;
            outf1_en = 1'b1;
        end

        S14:
        begin 
            outf1_en = 1'b1;
        end

        S15:
        begin
            outf1_en = 1'b1;
            submb_en = 1'b1;
            oldxx_en = 1'b1;
            if (!FBSTROBE) 
            begin
                fbptr_rst     = 1'b1;
                fbpending_en  = 1'b1;
            end
            else 
            begin
                fbptr_rst     = 1'b0;
                fbpending_en  = 1'b0;
            end

            if(!xx[0]) chreadyi_en = 1'b1;
            else       chreadyi_en = 1'b0;
        end 
        S16:
        begin 
            submb_en      = 1'b0;
            outf1_en      = 1'b0;
            oldxx_en      = 1'b0;
            chreadyi_en   = 1'b0;
            fbptr_rst     = 1'b0;
            fbpending_en  = 1'b0;

            xxo_sel  = 1'b1;
            topih_en = 1'b1;

        end

        S17:
        begin 
            xxo_sel  = 1'b0;
            topih_en = 1'b0;
        end

        S18:
        begin 
        end

        S19:
        begin 
        end

        S20:
        begin 
            XXINC = 1'b1;
        end

        default: 
        begin
            rst_0       = '0;
            oldxx_en    = '0;
            xxo_sel     = '0;
            topih_en    = '0;
            topii_en    = '0;
            totdif_en   = '0;
            totdif_rst  = '0;
            dconly_sel1 = '0;
            dconly_sel2 = '0;
            modeoi_en   = '0;
            en_12       = '0;
            outf1_en    = '0;
            submb_en    = '0;
            fbptr_rst   = '0;
            XXINC       = '0;
            CHREADY     = '0;
            modeoi_sel  = '0;
            tvalid_sel  = '0;
            lvalid_sel  = '0;
            fbpending_sel = '0;
            chreadyi_sel  = '0;
            chreadyii_sel = '0;
            sumtl_sel     = '0;
            yyfull        = '0;
        end

    endcase

    //sel = {en, rst}
    tvalid_sel    = {NEWLINE , NEWSLICE};
    lvalid_sel    = {((FBSTROBE) && (submb == 14 || submb == 15) && (!NEWLINE)), rst_0};
    fbpending_sel = {fbpending_en, (rst_0 || FBSTROBE)};
    chreadyi_sel  = {chreadyi_en , (!outf && chreadyi && !READYO)};
    chreadyii_sel = {(!outf && chreadyi && !READYO) , (!READYO && readyod && chreadyii)};
end


endmodule
