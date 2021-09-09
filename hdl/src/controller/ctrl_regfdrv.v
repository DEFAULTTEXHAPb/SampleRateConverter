module RegFileDriver #(
    parameter WIDTH = 3
) (
    input wire             clk, rst, en,
    input wire             res_err, rf_rw, get_reg,
    input wire [WIDTH-1:0] result_reg, error_reg,
    output reg [WIDTH-1:0] ar1, ar2, ard
);

    localparam ULOAD_SAMPLE = 4'b1000;
    localparam CALC_INIT    = 4'b0101;
    localparam LOAD_ERROR   = 4'b0010;
    localparam LOAD_RESULT  = 4'b0001;

    always @(posedge clk) begin
        if (!rst) begin
            if (en) begin
                casez ({rf_rw, res_err})
                    2'b1z: begin
                        ar1 <= (get_reg)? result_reg : result_reg - 1'b1;
                        ar2 <= (get_reg)? {WIDTH{1'bz}} : error_reg;
                        ard <= {WIDTH{1'bz}};
                    end
                    2'b01: begin
                        ar1 <= {WIDTH{1'bz}};
                        ar2 <= {WIDTH{1'bz}};
                        ard <= result_reg;
                    end
                    2'b00: begin
                        ar1 <= {WIDTH{1'bz}};
                        ar2 <= {WIDTH{1'bz}};
                        ard <= error_reg;
                    end
                endcase
            end
        end else begin
            {ar1, ar2, ard} <= {(3*WIDTH-1){1'b0}};
        end
    end

endmodule