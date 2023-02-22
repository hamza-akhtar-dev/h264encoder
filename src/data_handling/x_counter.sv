module x_counter 
(
    input logic rst, clk, en_x, incr_x, dcr_x,
    output logic [31:0] x
);

    always_ff @( posedge clk ) 
    begin 
        if (rst)
        begin
            x <= 0;
        end
        else if (en_x)
        begin
            x <= x + 4;
        end
        else if (incr_x)
        begin
            x <= x + 16;
        end
        else if (dcr_x)
        begin
            x <= x - 16;
        end
    end

endmodule