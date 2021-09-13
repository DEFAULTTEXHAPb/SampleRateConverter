module ctrl_pc #(
    parameter INSTRADDRW = 8
) (
    input clk, clr, pc_incr,
    output reg [INSTRADDRW-1:0] pc
);

    initial begin
        pc = {INSTRADDRW{1'b0}};
    end

    always @(posedge clk) begin
        if (!clr) begin
            pc <= (pc_incr)? pc + 1 : pc;
        end else begin
            pc <= {INSTRADDRW{1'b0}};
        end
    end
    
endmodule