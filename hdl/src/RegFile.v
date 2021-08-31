

/*

 1 2 3 4 5 6 ...

    1 4
    2 5 
    3 6

         / ---------------- -> a \                        / ---------------- -> a \
 || ---- - ---------------- -> b - a b c     ||      ---- - ---------------- -> b - a b c 
         \ ---------------- -> c /                        \ ---------------- -> c /


*/




`define GND_BUS(width) {width{1'b0}}
module RegFile #(
    parameter DATA_WIDTH = 32,
    parameter REGFILE_ADDR_W = 5
) (
    input clk, rst, en,
    input rw,
    input [REGFILE_ADDR_W-1:0] a_ra, a_rb, a_rd,
    input [DATA_WIDTH-1:0] rd,
    output reg [DATA_WIDTH-1:0] ra, rb
);

    reg [DATA_WIDTH-1:0] rfile [0:2**REGFILE_ADDR_W-1];

    integer i;
    initial begin
        ra = `GND_BUS(DATA_WIDTH);
        rb = `GND_BUS(DATA_WIDTH);
        for (i = 0; i < 2**REGFILE_ADDR_W; i = i + 1) begin
            rfile[i] = `GND_BUS(DATA_WIDTH);
        end
    end

    always @(posedge clk)
    begin
        if (!rst)
            if (en)
            begin
                if (!rw)
                    rfile[a_rd] <= rd;
                else
                begin
                    ra <= rfile[a_ra];
                    rb <= rfile[a_rb];
                end
            end
        else
        begin
            ra <= `GND_BUS(DATA_WIDTH);
            rb <= `GND_BUS(DATA_WIDTH);
        end
    end
    
endmodule