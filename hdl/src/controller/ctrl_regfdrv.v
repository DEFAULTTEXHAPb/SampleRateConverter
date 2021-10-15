
module ctrl_regfdrv #(
    parameter WIDTH = 3
  ) (
    input  wire             clk,        //! __Clock__
    input  wire             rst,        //! __Reset__
    input  wire             en_init,    //! Ring buffer initialization flag
    input  wire             en_load,    //! Register file load enable
    input  wire             new_smp,    //! New input sample flag
    input  wire             out_smp,    //! New output sample flag
    //input  wire             load,       //! Coefficient load flag
    input  wire [WIDTH-1:0] result_reg, //! Result register address
    input  wire [WIDTH-1:0] error_reg,  //! Erorr register address
    output wire  [WIDTH-1:0] ares,       //! Result register file address
    output wire  [WIDTH-1:0] aerr       //! Erorr register file address
  );

  reg  [WIDTH-1:0] qares;
  reg  [WIDTH-1:0] qaerr;

  initial begin
    qaerr = {WIDTH{1'b0}};
    qares = {WIDTH{1'b0}};
  end

  reg  open_regf_addr  = 1'b0;
  wire dopen_regf_addr = en_init | en_load;


  // //! Destination erorr register file address value set
  always @(negedge clk) begin
    if (rst == 1'b1) begin
      open_regf_addr <= 1'b0;
    end else if (dopen_regf_addr == 1'b1) begin
      open_regf_addr <= 1'b1;
    end
  end

  //! Result register file address value set
  always @(negedge clk) begin : ares_reg_set
    if (rst == 1'b1) begin
      qares <= {WIDTH{1'b0}};
    end begin
      case ({en_init,en_load})
        2'b10: qares <= (new_smp == 1'b0)? result_reg - 1'b1 : {WIDTH{1'b0}};
        2'b01: qares <= (out_smp == 1'b0)? result_reg : {WIDTH{1'b0}};
        default: /* __ clock disable __ */;
      endcase      
    end
  end

  //! Source erorr register file address value set
  always @(negedge clk) begin : aerr_reg_set
    if (rst == 1'b1) begin
      qaerr <= {WIDTH{1'b0}};
    end if ((en_init == 1'b1)||(en_load == 1'b1)) begin
      qaerr <= error_reg;
    end
  end

  assign ares = (open_regf_addr)? qares : {WIDTH{1'bz}};
  assign aerr = (open_regf_addr)? qaerr : {WIDTH{1'bz}};

endmodule
