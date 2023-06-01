module controller_me
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
    output logic       en_ram,
    output logic       done,
    output logic [5:0] addr, //output logic [5:0] addr [MACRO_DIM:0] Try
    output logic [5:0] amt,
    output logic [1:0] sel
);

    localparam S0 = 3'b000;
    localparam S1 = 3'b001;
    localparam S2 = 3'b010;
    localparam S3 = 3'b011;
    localparam S4 = 3'b100;
    localparam S5 = 3'b101;
    localparam S6 = 3'b110;
    localparam S7 = 3'b111;

    logic [5:0] count;
    logic       en_count_inc;
    logic       en_count_dec;
    logic       set_to_16;
    logic       set_to_31;
    logic       rst_count;

    logic [2:0] state;
    logic [2:0] next_state;

    //State Machine

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
                done = 0;
                if(start)
                begin
                    next_state = S1;
                end
                else
                begin
                    next_state = S0;
                end
            end
            S1: 
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
            S3:
            begin
                if(count == MACRO_DIM-1)
                begin
                    next_state = S4;
                end
                else
                begin
                    next_state = S3;
                end
            end
            S4:
            begin
                if(count == SEARCH_DIM-1)
                begin
                    next_state = S5;
                end
                else
                begin
                    next_state = S4;
                end
            end
            S5:
            begin
                if(amt > 32)
                begin
                    next_state = S0;
                    done = 1;
                end
                else
                begin
                    next_state = S6;
                end
            end
            S6:
            begin
                if(count == 0)
                begin
                    next_state = S7;
                end
                else
                begin
                    next_state = S6;
                end
            end
            S7:
            begin
                if(amt > 32)
                begin
                    next_state = S0;
                    done = 1;
                end
                else
                begin
                    next_state = S4;
                end
            end
        endcase
    end

    always_comb 
    begin
        case(state)
            S0: // Reset State
            begin
                ready     = 1;
                valid     = 0;
                en_cpr    = 0;
                en_spr    = 0;
                rst_count = 1;
                amt       = 0;
                en_ram    = 0;
            end
            S1: // CPR Load State
            begin
                ready        = 0;
                valid        = 0;
                en_cpr       = 1;
                en_spr       = 0;
                rst_count    = 0;
                en_count_inc = 1;
                en_count_dec = 0;
                sel          = 1;
                en_ram       = 1;
            end
            S2: // Counter Reset State
            begin 
                ready     = 0;
                valid     = 0;
                en_cpr    = 0;
                en_spr    = 0;
                rst_count = 1;
                en_ram    = 0;
            end
            S3: // SPR Load State
            begin 
                ready        = 0;
                valid        = 0;
                en_cpr       = 0;
                en_spr       = 1;
                rst_count    = 0;
                en_count_inc = 1;
                en_count_dec = 0;
                sel          = 1;
                en_ram       = 1;
            end
            S4: // Upshift State
            begin 
                ready        = 0;
                valid        = 1;
                en_cpr       = 0;
                en_spr       = 1;
                rst_count    = 0;
                en_count_inc = 1;
                en_count_dec = 0;
                sel          = 1;
                en_ram       = 1;
            end
            S5: // Leftshift after Up State 
            begin
                ready        = 0;
                valid        = 1;
                en_cpr       = 0;
                en_spr       = 1;
                rst_count    = 0;
                en_count_inc = 0;
                en_count_dec = 0;
                set_to_16    = 0;
                set_to_31    = 1;
                sel          = 2;
                amt          = amt + 1;
                en_ram       = 0;
            end
            S6: // Downshift State
            begin
                ready        = 0;
                valid        = 1;
                en_cpr       = 0;
                en_spr       = 1;
                rst_count    = 0;
                en_count_inc = 0;
                en_count_dec = 1;
                sel          = 0;
                en_ram       = 1;
            end
            S7: // Leftshift after Down State
            begin
                ready        = 0;
                valid        = 1;
                en_cpr       = 0;
                en_spr       = 1;
                rst_count    = 0;
                en_count_inc = 0;
                en_count_dec = 0;
                set_to_16    = 1;
                set_to_31    = 0;
                sel          = 2;
                amt          = amt + 1;
                en_ram       = 0;
            end
        endcase
    end

    always_ff@(posedge clk or negedge rst_n)
    begin
        if(~rst_n | rst_count)
        begin
            count <= 0;
        end
        else if(en_count_inc)
        begin
            count <= count + 1;
        end
        else if(en_count_dec)
        begin
            count <= count - 1;
        end
        else if(set_to_16)
        begin
            count <= 16;
        end
        else if(set_to_31)
        begin
            count <= 31;
        end
    end

    assign addr = count;

endmodule