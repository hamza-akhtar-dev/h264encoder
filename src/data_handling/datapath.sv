module datapath #
    (
        parameter MACRODIM = 16,
        parameter IMGWIDTH = 48,
        parameter IMGHEIGHT = 48
    )
    (
        input logic rst, clk,
        input logic hold,
        output logic stop,
        output logic [31:0] x, y
    );

	logic [31:0] xbase, xcount;
	logic [31:0] ybase, ycount;

	always_ff @( posedge clk ) 
    begin 
        if(rst | hold)
        begin
            xbase <= 0;
            xcount <= 0;
        end
        else if((ycount == MACRODIM - 1) && (x == IMGWIDTH - 4))
        begin
            xcount <= 0;
            xbase <= 0;
        end
        else if((ycount == MACRODIM - 1) && (xcount == MACRODIM - 4))
        begin
            xcount <= 0;
            xbase <= xbase + 16;
        end
        else if(xcount == MACRODIM - 4)
        begin
            xcount <= 0;
        end
        else
        begin
            xcount <= xcount + 4;
        end
    end

    assign x = xbase + xcount;

	always_ff @( posedge clk ) 
    begin 
        if (rst | hold) 
        begin
            ycount <= 0;
            ybase <= 0;
        end
        else if((ycount == MACRODIM - 1) && (x == IMGWIDTH - 4))
        begin
            ycount <= 0;
            ybase <= ybase + 16;
        end
        else if((ycount == MACRODIM - 1) && (xcount == MACRODIM - 4))
        begin
            ycount <= 0;
        end
        else if(xcount == MACRODIM - 4)
        begin
            ycount <= ycount + 1;
        end
    end

    assign y = ybase + ycount;

    assign stop = (x == 44) && (y == 47);

endmodule