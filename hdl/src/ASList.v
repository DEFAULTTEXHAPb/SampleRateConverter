`define ALLOCSET_W STAGE_W + VEC_ID_W + 2*REGFILE_ADDR_W + ALLOC_LEN_W + 2*DATA_ADDR_W
`define GND_BUS(width) {width{1'b0}}
module ASList #(
    parameter VEC_ID_W = 4,
    parameter STAGE_W = 3,
    parameter DATA_ADDR_W = 12,
    parameter ALLOC_LEN_W = 10,
    parameter PS_ADDR_W = 7,
    parameter REGFILE_ADDR_W = 5
) (
    input wire                    clk, rst, en,
    input wire                    prog,
    input wire  [PS_ADDR_W-1:0]   psaddr,
    input  wire [`ALLOCSET_W-1:0] prog_as,
    output reg [`ALLOCSET_W-1:0] as_word
);

    reg [`ALLOCSET_W-1:0] list [0:2**PS_ADDR_W-1];

    integer i;
    initial begin
        as_word = `GND_BUS(`ALLOCSET_W);
        for (i = 0; i < 2**PS_ADDR_W; i = i + 1) begin
            list[psaddr] = `GND_BUS(`ALLOCSET_W);
        end
    end

    always @(posedge clk)
    begin
        if (!rst)
            if (prog)
                list[psaddr] <= prog_as;
            else
                as_word <= list[psaddr];
        else
            as_word <= `GND_BUS(`ALLOCSET_W);
    end
endmodule

module PC #(
    parameter PS_ADDR_W = 7
) (
    input clk, rst, pc_inc,
    output reg [PS_ADDR_W-1:0] pc
);
    always @(posedge clk)
    begin
        if (!rst)
            if (pc_inc) pc <= pc + 1;
        else
            pc <= `GND_BUS(PS_ADDR_W);
    end
endmodule