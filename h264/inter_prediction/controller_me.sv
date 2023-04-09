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
    output logic [5:0] addr,
    output logic [5:0] amt,
    output logic [1:0] sel
);

    localparam S0 = 3'b000;
    localparam S1 = 3'b001;
    localparam S2 = 3'b010;
    localparam S3 = 3'b011;
    localparam S4 = 3'b100;
    localparam S5 = 3'b101;

    logic       en_count;
    logic [5:0] count;

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
                if(count == SEARCH_DIM-1)
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
                next_state = S5;
            end
            S5:
            begin
                if(count == SEARCH_DIM-1)
                begin
                    next_state = S4;
                end
                else
                begin
                    next_state = S5;
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
                en_cpr   = 0;
                en_spr   = 0;
                en_count = 0;
                amt      = 0;
            end
            S1:
            begin
                ready    = 0;
                valid    = 0;
                en_cpr   = 1;
                en_spr   = 0;
                en_count = 1;
                sel      = 1;
                amt      = 0;
            end
            S2: 
            begin 
                ready    = 0;
                valid    = 0;
                en_cpr   = 0;
                en_spr   = 0;
                en_count = 0;
                amt      = 0;
            end
            S3: 
            begin 
                ready    = 0;
                valid    = 1;
                en_cpr   = 0;
                en_spr   = 1;
                en_count = 1;
                sel      = 1;
                amt      = 0;
            end
            S4: 
            begin
                ready    = 0;
                valid    = 1;
                en_cpr   = 0;
                en_spr   = 1;
                en_count = 0;
                sel      = 2;
                amt      = amt + 1;
            end
            S5:         // Horizontal Shifter
            begin
                ready    = 0;
                valid    = 1;
                en_cpr   = 0;
                en_spr   = 1;
                en_count = 1;
                sel      = 0;
            end
        endcase
    end

    // Counter

    always_ff@(posedge clk or negedge rst_n)
    begin
        if(~rst_n | ~en_count)
        begin
            count <= 0;
        end
        else if(en_count)
        begin
            count <= count + 1;
        end
    end

    assign addr = count;


endmodule