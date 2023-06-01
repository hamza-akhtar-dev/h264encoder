module register
(
    input  logic       rst_n,
    input  logic       clk,
    input  logic       en,
    input  logic [7:0] in,
    output logic [7:0] out
);

    always_ff@(posedge clk or negedge rst_n) 
    begin
        if(~rst_n)
        begin
            out <= 0;
        end
        else
        begin
            if(en)
            begin
                out <= in;
            end
        end
    end
            
endmodule