module register #
(
    WIDTH = 8
) 
(
    input clk, rst,
    input logic [WIDTH-1:0] D,
    output logic [WIDTH-1:0] Q
);

always_ff @(posedge clk)
begin
    if(rst)
    begin
        Q <= 0;
    end
    else
    begin
        Q <= D;
    end
end
    
endmodule