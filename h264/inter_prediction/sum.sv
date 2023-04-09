module sum #
(
    parameter MACRO_DIM = 16
) 
(
    input  logic                        rst_n,
    input  logic                        clk,
    input  logic [8*(MACRO_DIM**2)-1:0] ad,
    output logic [15:0]                 sum
);

    genvar i, j, k, m;

    logic [7:0] preg1 [0:255];

    generate
        for (i = 0; i < 256; i = i + 1) 
        begin
            always @(posedge clk or negedge rst_n) 
            begin
                if(~rst_n)
                begin
                    preg1[i] <= 0;
                end
                else
                begin
                    preg1[i] <= ad[(i+1)*8-1:i*8];
                end
            end
        end
    endgenerate

    logic [9:0] preg2 [0:63];

    generate
        for (j = 0; j < 64; j = j + 1) 
        begin
            always @(posedge clk or negedge rst_n) 
            begin
                if(~rst_n)
                begin
                    preg2[j] <= 0;
                end
                else
                begin
                    preg2[j] <= #1 (preg1[j*4]+preg1[j*4+1])+(preg1[j*4+2]+preg1[j*4+3]);
                end
            end
        end
    endgenerate

    logic [11:0] preg3 [0:15];

    generate
        for (k = 0; k < 16; k = k + 1) 
        begin
            always @(posedge clk or negedge rst_n) 
            begin
                if(~rst_n)
                begin
                    preg3[k] <= 0;
                end
                else
                begin
                    preg3[k] <= #1 (preg2[k*4]+preg2[k*4+1])+(preg2[k*4+2]+preg2[k*4+3]);
                end
            end
        end
    endgenerate

    reg [13:0] preg4 [0:3];

    generate
        for (m = 0; m < 4; m = m + 1) 
        begin 
            always @(posedge clk or negedge rst_n) 
            begin
                if(~rst_n)
                begin
                    preg4[m] <= 0;
                end
                else
                begin
                    preg4[m] <= #1 (preg3[m*4]+preg3[m*4+1])+(preg3[m*4+2]+preg3[m*4+3]);
                end
            end
        end
    endgenerate

    always @(posedge clk or negedge rst_n) 
    begin
        if(~rst_n)
        begin
            sum <= 0;
        end
        else
        begin
            sum <= #1 (preg4[0]+preg4[1])+(preg4[2]+preg4[3]);
        end
    end

endmodule