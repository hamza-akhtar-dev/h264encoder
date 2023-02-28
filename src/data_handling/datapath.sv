module datapath #
    (
        parameter IMGWIDTH = 64,
        parameter IMGHEIGHT = 64
    )
    (
        input logic rst, clk,
        output logic stop,
        output logic [31:0] x, y
    );

	logic [31:0] xbase, xcount;
	logic [31:0] ybase, ycount;

	always_ff @( posedge clk ) 
    begin 
        if(rst)
        begin
            xbase <= 0;
            xcount <= 0;
        end
        else if(ycount == 15 && x == 44)
        begin
            xcount <= 0;
            xbase <= 0;
        end
        else if(ycount == 15 && xcount == 12)
        begin
            xcount <= 0;
            xbase <= xbase + 16;
        end
        else if(xcount == 12)
        begin
            xcount <= 0;
        end
        else
        begin
            xcount <= xcount + 4;
        end
    end
    assign x = xbase + xcount;

	assign x_width = (x == IMGWIDTH);

	always_ff @( posedge clk ) 
    begin 
        if (rst) 
        begin
            ybase <= 0;
            ycount <= 0;
        end
        else if(x == 44 && ycount == 15)
        begin
            ycount <= 0;
            ybase <= ybase + 16;
        end
        else if(xcount == 12 && ycount == 15)
        begin
            ycount <= 0;
        end
        else if(xcount == 12)
        begin
            ycount <= ycount + 1;
        end
    end

    assign y = ybase + ycount;

    assign stop = (x == 44) && (y == 47);

endmodule