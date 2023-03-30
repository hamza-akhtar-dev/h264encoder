module comparator
(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] sad, 
    output logic [15:0] min_sad
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
                min_sad <= sad;
            end
            else
            begin
                min_sad <= min_sad;
            end
        end
    end

endmodule