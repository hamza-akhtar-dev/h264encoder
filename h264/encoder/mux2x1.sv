module mux2x1
(
	input  logic       sel,
	input  logic [7:0] in1, 
	input  logic [7:0] in2, 
	output logic [7:0] out
);

    always_comb
    begin
        case(sel)
            1'b0: out = in1;
            1'b1: out = in2;
        endcase
    end

endmodule