// Top testbench module
module h264coretransform_tb;

    // Variable/Signals Declaration
    logic CLK;
    logic [35:0] XXIN;
    logic RESET;
    logic ENABLE;
    logic READY;
    logic VALID;
    logic [13:0] YNOUT;


    // Call Module
    h264coretransform DUT(
        .CLK(CLK),
        .XXIN(XXIN),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .READY(READY),
        .VALID(VALID),
        .YNOUT(YNOUT)
    );

    initial
        begin
            CLK = 0;
            forever #20 CLK = ~CLK;
        end

    initial
        begin
            RESET = 0;
            @(posedge CLK);
            RESET = 1;
            ENABLE = 1;
            XXIN[8:0]   = 9'b000001111;            // pixel 1
            XXIN[17:9]  = 9'b111101111;            // pixel 2
            XXIN[26:18] = 9'b111100000;            // pixel 3
            XXIN[35:27] = 9'b010101010;            // pixel 4

            repeat (2) @(posedge CLK);
            ENABLE = 0;
            repeat (30) @(posedge CLK);
            $stop;
            $finish;
        end
endmodule