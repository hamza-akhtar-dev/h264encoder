module y_counter
(
    input logic reset, clk, en_y, dcr_y, 
	output logic [31:0] y
);

    always_ff @( posedge clk ) 
    begin 
        if (reset) 
        begin
            y <= 0;
        end
        else if (en_y) 
        begin
            y <= y + 1;
        end
        else if (dcr_y) 
        begin
            y <= y - 16;
        end
    end

endmodule