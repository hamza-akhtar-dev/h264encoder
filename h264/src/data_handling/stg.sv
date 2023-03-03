module stg #
(
    WIDTH = 16;
    SIZE = 16;
    SRR = 15;
    SRD = 17;
)
(
    input logic clk, reset,start
    input logic [3:0] count_cpr, count_spr, count_srr; //search range right of SPR
    input logic [4:0] count_srd; // search range down of SPR
    input logic [WIDTH-1:0] cpr, spr,
    output logic load_cpr = 1'd0,
    output logic load_spr = 1'd0,
    output logic sr_spr = 1'd0,
    output logic sd_spr = 1'd0;
);

localparam s0 = 3'b000 ;
localparam s1 = 3'b001;
localparam s2 = 3'b010;
localparam s3 = 3'b011;
localparam s4 = 3'b101;
logic [1:0] cs,ns;

always_ff @( posedge clk ) begin

    if (reset) begin
        cs <= s0;
    end
    else begin
        cs <= ns;
    end
end

always_comb begin
    case(cs) 
    s0: begin
        if(start) begin
            ns = s1;
        end
        else begin
            ns = s0;
        end
    end
    s1: begin
        if(count_cpr < SIZE) begin
            ns = s1;
        end
        else begin
            ns = s2;
        end
    end
    s2: begin
        if(count_spr < SIZE) begin
            ns = s2;
    end
    else begin
        ns = s3;
    end
    end
    s3: begin
        if(count_srr < SRR) begin
            ns = s3;
        end
        else begin
            ns = s4;
        end
    end
    s4: begin
        if (count_srd < SRD) begin
            ns = s4;
        end
        else begin
            ns = s0;
        end
    end

    endcase
end

always_comb begin
    if (cs == s1) begin
        load_cpr = 1'b1;
    end
    else if (cs == s2) begin
        load_spr = 1'b1;
    end
    else if (cs == s3) begin
        sr_spr = 1'b1;
    end
    else if (cs == s4) begin
        sd_spr = 1'b1;
    end

end

endmodule
