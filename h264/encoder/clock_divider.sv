module clock_divider
(
    input logic clk,
    output logic clk_a,
    output logic clk_b
);

    logic [18:0] counter = 0;
    
    always_ff @ (posedge clk)
    begin
        counter <= counter + 1;
        clk_a   <= counter[17];
        clk_b   <= counter[18];
    end

endmodule