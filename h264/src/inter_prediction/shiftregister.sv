module shift_register (
  input logic clk,         // Clock signal
  input logic reset,       // Reset signal
  input logic shift_en,    // Shift enable signal
  input logic [7:0] in_data,// Input data
  output logic [7:0] out_data // Output data
);

  logic [7:0] temp; // Shift register

  always_ff @(posedge clk) begin
    if (reset) begin
      // Reset the shift register to all zeroes
      temp <= 8'b0;
    end
    else if (shift_en) begin
      // Shift the register to the left
      temp <= {temp[6:0], in_data};
    end
  end

  assign out_data = temp; // Output the shifted data
endmodule
