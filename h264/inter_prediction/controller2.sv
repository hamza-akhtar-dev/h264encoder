module controller2
#
(
    parameter MACRO_DIM  = 16,
    parameter SEARCH_DIM = 48
) 
(
    input  logic       rst_n, 
    input  logic       clk, 
    input  logic       start,
    output logic       ready,
    output logic       valid,
    output logic       en_cpr, 
    output logic       en_spr,
    output logic [5:0] addr,
    output logic [5:0] amt,
    output logic [1:0] sel,
    output logic       done
);

    localparam S0 = 3'b000;
    localparam S1 = 3'b001;
    localparam S2 = 3'b010;
    localparam S3 = 3'b011;
    localparam S4 = 3'b100;
    localparam S5 = 3'b101;
    localparam S6 = 3'b110;

    logic rst_count, en_count, dec_count, en_MACROcount, dec_MACROcount;
    logic [5:0] count;

    logic [2:0] state;
    logic [2:0] next_state;   
    
    always_ff@(posedge clk or negedge rst_n) 
    begin
        if(~rst_n)
        begin
            state <= S0;
        end
        else
        begin
            state <= next_state;
        end
    end
    
    always_comb 
    begin
        next_state = S0;
        case(state)
            S0: 
            begin
                if(start)
                begin
                    next_state = S1;
                end
                else
                begin
                    next_state = S0;
                end
            end
            S1: // load cpr
            begin
                if(count == MACRO_DIM-1)
                begin
                    next_state = S2;
                end
                else
                begin
                    next_state = S1;
                end
            end
            S2: 
            begin
                next_state = S3;
            end
            S3: // spr load using down-shifting
            begin
                if(count == SEARCH_DIM-1)
                begin
                    next_state = S4;
                end
                else
                begin
                    next_state = S3;
                end
            end
            S4: // left shifting
            begin
                next_state = S5;
            end
            S5: // checking state
            begin
                if (amt == 47)
                begin
                    next_state = S0;
                    done = 1;
                end
                else if (count == MACRO_DIM - 1)
                begin
                    next_state = S3;
                end
                else if (count == SEARCH_DIM - MACRO_DIM - 1)
                begin
                    next_state = S6;
                end
            end
            S6: 
            begin
                if (count == 0)
                begin
                    next_state = S4;
                end
                else
                begin
                    next_state = S6;
                end
            end
        endcase
    end

    always_comb 
    begin
        case(state)
            S0:
            begin
                ready    = 1;
                valid    = 0;
                amt      = 0;
                en_cpr   = 0;
                en_spr   = 0;
                en_count = 0;
                dec_count = 0;
                rst_count = 1;
                en_MACROcount = 0;
                dec_MACROcount = 0;
            end
            S1:
            begin
                ready    = 0;
                valid    = 0;
                sel      = 1;
                en_cpr   = 1;
                en_spr   = 0;
                en_count = 1;
                dec_count = 0;
                rst_count = 0;
                en_MACROcount = 0;
            end
            S2: 
            begin 
                ready    = 0;
                valid    = 0;
              //sel      = 0;
                en_cpr   = 0;
                en_spr   = 0;
                en_count = 0;
                dec_count = 0;
                rst_count = 1;
                en_MACROcount = 0;
            end
            S3: 
            begin
                ready    = 0;
                valid    = 1;
                //amt      = 0;
                sel      = 1;
                en_cpr   = 0;
                en_spr   = 1;
                en_count = 1;
                dec_count = 0;
                rst_count = 0;
                en_MACROcount = 0;
                dec_MACROcount = 0;
            end
            S4: 
            begin
                ready    = 0;
                valid    = 1;
                amt      = amt + 1;
                sel      = 2;
                en_cpr   = 0;
                en_spr   = 1;
                en_count = 0;
                dec_count = 0;
                rst_count = 0;
                if (amt%2 == 0)
                begin
                    en_MACROcount = 1;
                end
                else
                begin
                    dec_MACROcount = 1;
                end
            end
            S5:         // Check
            begin
                ready    = 0;
                valid    = 0;
                en_cpr   = 0;
                en_spr   = 0;
                en_count = 0;
                dec_count = 0;
                rst_count = 0;
                en_MACROcount = 0;
                dec_MACROcount = 0;
            end
            S6:         // upshifting
            begin
                ready    = 0;
                valid    = 0;
                sel      = 0;
                en_cpr   = 0;
                en_spr   = 1;
                en_count = 0;
                dec_count = 1;
                rst_count = 0;
                en_MACROcount = 0;
            end
        endcase
    end

    always_ff@(posedge clk or negedge rst_n)
    begin
        if(~rst_n | rst_count)
        begin
            count <= 0;
        end
        else if(en_count)
        begin
            count <= count + 1;
        end
        else if(dec_count)
        begin
            count <= count - 1;
        end
        else if(en_MACROcount)
        begin
            count <= count + MACRO_DIM;
        end
        else if(dec_MACROcount)
        begin
            count <= count - MACRO_DIM;
        end
        else
        begin
            count <= count;
        end
    end

    assign addr = count;
endmodule