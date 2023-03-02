module motion_estimation #
(
    parameter MACROBLOCK_SIZE = 16;
    parameter SEARCH_WINDOW = 64;
) 
(
    input logic clk;
    input logic [MACROBLOCK_SIZE*MACROBLOCK_SIZE-1] current_macroblock;
    input logic [(MACROBLOCK_SIZE+SEARCH_WINDOW)*(MACROBLOCK_SIZE+SEARCH_WINDOW)] search_pixel_window;
);

    logic [7:0] reference_block [0:15][0:15] = '{'{default: 8'h00}};

    logic x_count = 0;
    logic y_count = 0;

    logic x_flag = 1;
    logic y_flag = -1;

    logic sad = 0;

    always_ff @(posedge clk) 
    begin
        if(rst)
        begin
            count <= 0;
        end
        else
        begin
            count ++;
        end
    end

    always_comb 
    begin
        sad = 0;
        if(!flag)
        begin
            if(x_flag < 0)
            begin
                x0 += x_count;
            end
            else
            begin
                x0 -= x_count;
            end
            flag = 1;
            x_count ++;
            x_flag *= -1;
        end
        else if(flag)
        begin
            if(y_flag < 0)
            begin
                y0 += y_count;
            end
            else
            begin
                y0 -= y_count;
            end
            flag = 0;
            y_count ++;
            y_flag *= -1;
        end
    end
    






endmodule