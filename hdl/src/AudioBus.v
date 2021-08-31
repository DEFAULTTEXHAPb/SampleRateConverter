module AudioBus #(
    parameter DATA_WIDTH = 32
)(
    input                   i_clk, i_rst, newin,
    input  [DATA_WIDTH-1:0] din,
    output                  rinc, o_clk, o_rst,
    output [DATA_WIDTH-1:0] dout
);
    wire rst = i_rst;
    assign o_rst = rst;
    wire clk = i_clk;
    assign o_clk = clk;
    reg [DATA_WIDTH-1:0] new_data;
    always @(posedge clk) begin
        if (!rst) begin
            if (newin) new_data <= din;
        end else begin
            new_data <= {DATA_WIDTH{1'b0}};
        end
    end
    assign dout = new_data;
    assign rinc = newin;

endmodule