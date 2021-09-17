`include "ctrl.svh"

module ctrl_pc #(
    parameter INSTRADDRW = $clog2(ctrl::INSTRUCTION_MEMORY_SIZE)
) (
    input  logic                  clk,
    input  logic                  clr,
    input  logic                  pc_incr,
    output logic [INSTRADDRW-1:0] pc
);

    initial begin
        pc = '0;
    end

    always @(posedge clk) begin
        if (!clr) begin
            pc <= (pc_incr)? pc + 1 : pc;
        end else begin
            pc <= '0;
        end
    end
    
endmodule