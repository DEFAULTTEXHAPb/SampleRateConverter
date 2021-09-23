module ctrl_regfdrv #(
    parameter WIDTH = 3
  ) (
    input  wire             clk,
    input  wire             rst,
    input  wire             mac_init,
    input  wire             w_r,
    input  wire             new_smp,
    input  wire             res_err,
    input  wire [WIDTH-1:0] result_reg,
    input  wire [WIDTH-1:0] error_reg,
    output reg  [WIDTH-1:0] ard,
    output reg  [WIDTH-1:0] ar1,
    output reg  [WIDTH-1:0] ar2
  );

  localparam ULOAD_SAMPLE = 4'b1000;
  localparam CALC_INIT    = 4'b0101;
  localparam LOAD_ERROR   = 4'b0010;
  localparam LOAD_RESULT  = 4'b0001;

  wire write_reg = w_r;
  wire read_reg = ~w_r;

  always @(posedge clk) begin : dest_reg_addr
    if (rst == 1'b1) begin
      ard <= {WIDTH{1'b0}};
    end if (write_reg == 1'b1) begin
      if (new_smp == 1'b0) begin
        ard <= (res_err == 1'b1)? result_reg : error_reg;
      end else begin
        ard <= {WIDTH{1'b0}};
      end
    end
  end

  always @(posedge clk) begin : op1_reg_addr
    if (rst == 1'b1) begin
      ar1 <= {WIDTH{1'b0}};
    end if (mac_init == 1'b1) begin
      ar1 <= result_reg - 1'b1;
    end
  end

  always @(posedge clk) begin : op2_reg_addr
    if (rst == 1'b1) begin
      ar1 <= {WIDTH{1'b0}};
    end if (mac_init == 1'b1) begin
      ar2 <= error_reg;
    end
  end

endmodule
