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
    output logic       en_cpr, 
    output logic       en_spr, 
    output logic       valid,
    output logic [1:0] sel
);

    localparam S0 = 3'b000;
    localparam S1 = 3'b001;
    localparam S2 = 3'b010;
    localparam S3 = 3'b011;
    localparam S4 = 3'b100;
    localparam S5 = 3'b101;

    logic       en_load_count, en_row_count, en_col_count;
    logic [4:0] load_count, row_count, col_count;

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
                if(load_count == MACRO_DIM + 4)     // 16 cycles for shifts and 4 cycles for adder tree pipeline i.e., 20 cycles = 16 cycles + 4 cycles
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
                if(row_count == 5'd31)
                begin
                    next_state = S5;
                end 
                else
                begin
                    if(col_count % 2 == 0)
                    begin
                        next_state = S3;
                    end
                    else
                    begin
                        next_state = S4;
                    end
                end               
            end
            S3:
            begin
                next_state = S2;
            end
            S4:
            begin
                next_state = S2;
            end
            S5:
            begin
                if(col_count < 31)
                begin
                    next_state = S2;
                end
                else
                begin
                    next_state = S0;
                end
            end
        endcase
    end

    always_comb 
    begin
        case(state)
            S0:
            begin
                en_load_count = 0;
                en_row_count  = 0;
                en_col_count  = 0;
                en_cpr   = 0;
                en_spr   = 0;
                valid    = 0;
                ready    = 1;
            end
            S1:
            begin
                en_load_count = 1;
                en_row_count  = 0;
                en_col_count  = 0;
                sel      = 0;
                en_cpr   = 1;
                en_spr   = 1;
                valid    = 0;
                ready    = 0;
            end
            S2: 
            begin 
                en_load_count = 0;
                //en_row_count  = 0;
                //en_col_count  = 0;
                //sel      = 0;
                en_cpr   = 0;
                en_spr   = 0;
                valid    = 1;
                ready    = 0;
            end
            S3: 
            begin 
                en_load_count = 0;
                en_row_count  = 1;
                //en_col_count  = 0;
                sel      = 0;
                en_cpr   = 0;
                en_spr   = 1;
                valid    = 0;
                ready    = 0;
            end
            S4: 
            begin 
                en_load_count = 0;
                en_row_count  = 1;
                //en_col_count  = 0;
                sel      = 1;
                en_cpr   = 0;
                en_spr   = 1;
                valid    = 0;
                ready    = 0;
            end
            S5: 
            begin 
                en_load_count = 0;
                //en_row_count  = 1;
                en_col_count  = 1;
                sel      = 2;
                en_cpr   = 0;
                en_spr   = 1;
                valid    = 0;
                ready    = 0;
            end
        endcase
    end

    // Counter

    always_ff@(posedge clk or negedge rst_n)
    begin
        if(~rst_n | ~en_load_count)
        begin
            load_count <= 0;
        end
        else if(en_load_count)
        begin
            load_count <= load_count + 1;
        end
    end

    always_ff@(posedge clk or negedge rst_n)
    begin
        if(~rst_n | ~en_row_count)
        begin
            row_count <= 0;
        end
        else if(en_row_count)
        begin
            row_count <= row_count + 1;
        end
    end

    always_ff@(posedge clk or negedge rst_n)
    begin
        if(~rst_n | ~en_col_count)
        begin
            col_count <= 0;
        end
        else if(en_col_count)
        begin
            col_count <= col_count + 1;
        end
    end

endmodule