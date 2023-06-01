module comparator
(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        valid,
    input  logic [5:0]  addr,
    input  logic [5:0]  amt,
    input  logic [15:0] sad, 
    output logic [15:0] min_sad,
    output logic [5:0]  mv_x,
    output logic [5:0]  mv_y
);
    always_ff @(posedge clk)
    begin
        if (!rst_n)
        begin
            min_sad <= 16'hffff;
        end
        else
        begin
            if (sad < min_sad) 
            begin
                if(valid)
                begin
                    min_sad <= sad;
                    mv_x    <= addr;
                    mv_y    <= amt;
                end
                else
                begin
                    min_sad <= min_sad;
                    mv_x    <= mv_x;
                    mv_y    <= mv_y;
                end
            end
            else
            begin
                min_sad <= min_sad;
                mv_x    <= mv_x;
                mv_y    <= mv_y;
            end
        end
    end

endmodule