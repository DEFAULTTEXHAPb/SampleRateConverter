`timescale 1ns/1ps
module clock_gen #(
  parameter FREQ = 100000, // In kHz
  parameter PHASE = 0,     // In degrees
  parameter DUTY = 50      // In percentage
) (
  input    wire   enable,
  output   reg    clk
);

  localparam real clk_pd    = 1.0/(FREQ * 1e3) * 1e9;
  localparam real clk_on    = DUTY/100.0 * clk_pd;
  localparam real clk_off   = (100.0 - DUTY)/100.0 * clk_pd;
  localparam real quarter   = clk_pd/4;
  localparam real start_dly = quarter*PHASE/90;

  reg start_clk;

  initial begin
    $display("FREQ      =%0d kHz",FREQ);
    $display("PHASE     =%0d deg",PHASE);
    $display("DUTY      =%0d %%",DUTY);

    $display("PERIOD    =%0.3f ns", clk_pd);
    $display("CLK_ON    =%0.3f ns", clk_on);
    $display("CLK_OFF   =%0.3f ns", clk_off);
    $display("QUARTER   =%0.3f ns", quarter);
    $display("START_DLY =%0.3f ns", start_dly);
  end

  initial begin
    clk       <= 0;
    start_clk <= 0;
  end

  always @(posedge enable or negedge enable) begin
    if (enable == 1'b1) begin
      #(start_dly) start_clk = 1'b1;
    end else begin
      #(start_dly) start_clk = 1'b0;
    end
  end

  always @(posedge start_clk) begin
    if (start_clk == 1'b1) begin
      clk = 1'b1;
      while (start_clk == 1'b1) begin
        #(clk_on) clk = 1'b0;
        #(clk_off) clk = 1'b1;
      end
      clk = 1'b0;
    end
  end

endmodule