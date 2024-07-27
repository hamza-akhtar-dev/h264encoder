module h264coretransform_controller(
    input logic CLK,                    // Clock Signal
    input logic RESET,                  // Reset Signal to reset state machine
    input logic ENABLE,                 // Enable signal for state machine
    input logic input_1,                // Input signal for FSM-1 // Pipeline 2-5
    output logic en_pipeline2,en_pipeline3,en_pipeline4,en_pipeline5
);


// For FSM-1 - Moore Machine with 8 states; S0,S1,S2,S3,S4,S5,S6,S7
// FSM-1 - To control Pipeline 2-5
logic [2:0] c_state1, n_state1;
//logic input_1;
parameter S0 = 3'b000, S1=3'b001, S2=3'b010, S3=3'b011, S4=3'b100, S5=3'b101, S6= 3'b110, S7 = 3'b111;

//FSM-1 State Logic
always_comb
begin
    // Next State Logic
    //input_1 = (ixx != 0); // Input signal to progress states
    case (c_state1)
        S0: begin 
                if (ENABLE) 
                    n_state1 = S1;
            end
        S1: n_state1 = S2;
        S2: n_state1 = S3;
        S3: n_state1 = S4;
        S4: n_state1 = S5;
        S5: n_state1 = S6;
        S6: n_state1 = S7;
        S7: n_state1 = S0;
        default: n_state1 = S0;
    endcase

    // Current State Logic
    case (c_state1)
    S0: begin // Clear all signals
            en_pipeline2 = 1'b0;
            en_pipeline3 = 1'b0;
            en_pipeline4 = 1'b0;
            en_pipeline5 = 1'b0;
        end
    S1: begin // Set en_pipeline2
            en_pipeline2 = 1'b1;
            en_pipeline3 = 1'b0;
            en_pipeline4 = 1'b0;
            en_pipeline5 = 1'b0;
        end
    S2: begin // Set en_pipeline2, en_pipeline3
            en_pipeline2 = 1'b1;
            en_pipeline3 = 1'b1;
            en_pipeline4 = 1'b0;
            en_pipeline5 = 1'b0;
        end
    S3: begin // Set en_pipeline2, en_pipeline4
            en_pipeline2 = 1'b1;
            en_pipeline3 = 1'b0;
            en_pipeline4 = 1'b1;
            en_pipeline5 = 1'b0;
        end
    S4: begin // Set en_pipeline2, en)en_pipeline5
            en_pipeline2 = 1'b1;
            en_pipeline3 = 1'b0;
            en_pipeline4 = 1'b0;
            en_pipeline5 = 1'b1;
        end
    S5: begin // Clear all signals
            en_pipeline2 = 1'b0;
            en_pipeline3 = 1'b0;
            en_pipeline4 = 1'b0;
            en_pipeline5 = 1'b0;
        end
    S6: begin // Clear all signals
            en_pipeline2 = 1'b0;
            en_pipeline3 = 1'b0;
            en_pipeline4 = 1'b0;
            en_pipeline5 = 1'b0;
        end
    S7: begin // Clear all signals
            en_pipeline2 = 1'b0;
            en_pipeline3 = 1'b0;
            en_pipeline4 = 1'b0;
            en_pipeline5 = 1'b0;
        end
    default: begin // Clear all signals
            en_pipeline2 = 1'b0;
            en_pipeline3 = 1'b0;
            en_pipeline4 = 1'b0;
            en_pipeline5 = 1'b0;
        end
    endcase // End of FSM-1
end

// FSM-1 State Transition
always_ff @(posedge CLK)
begin
    // FSM-1 : Moore Machine with 8 States; S0,S1,S2,S3,S4,S5,S6,S7

    //reset is active low
    if (!RESET)
        c_state1 <= S0;        // IDLE State
    else
        c_state1 <= n_state1;   // Next State
    // Rest of the FSM-1 is in always_comb block
end

endmodule