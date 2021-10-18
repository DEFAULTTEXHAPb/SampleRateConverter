`include "glb_macros.vh"
`include "controller/ctrl_ramdrv_coefcnt.v"
`include "controller/ctrl_ramdrv_ringbuf.v"

//! @title Dual Port RAM driver
//! @brief This module generates address for
//! vectors convolution

module ctrl_ramdrv #(
    parameter integer ADDR_WIDTH   = 12
) (
    input  wire                   clk,              //! __Clock__
    input  wire                   rst_n,            //! __Reset__
    input  wire                   en_init,          //! Output adreses initialization enable
    input  wire                   en_calc,          //! Address calculation enable
    //input  wire                   ringbuf_addr_clr, //! Ring buffer address registers clear
    input  wire                   ringbuf_init,     //! Ring buffer initialization
    input  wire                   coeff_load,       //! Coefficien load from CPU flag
    input  wire [ ADDR_WIDTH-1:0] data_bptr,        //! Sample segment base pointer
    input  wire [ ADDR_WIDTH-1:0] data_lptr,        //! Sample segment lower pointer
    input  wire [ ADDR_WIDTH-1:0] data_hptr,        //! Ring buffer head address in sample segment
    input  wire [ ADDR_WIDTH-1:0] coef_ptr,         //! Initial coefficient pointer
    output wire                   conv_pass,        //! Convolution finish flag
    output wire [ ADDR_WIDTH-1:0] data_addr,        //! Sample data address
    output wire [ ADDR_WIDTH-1:0] coef_addr         //! Coefficient data address
);

  //wire rst_n = ~rst;

  reg                   open_data_addr = 1'b0;
  reg                   open_coef_addr = 1'b0;

  //! D-trigger output for `data_addr`
  reg [ADDR_WIDTH-1:0] qdata_addr = {ADDR_WIDTH{1'b0}};
  //! Output wire port of `ctrl_ramdrv_ringbuf`
  wire [  ADDR_WIDTH-1 : 0] rbuf_data_addr;
  // //! Ring buffer clear OR-gate
  // wire                      clr;
  //! Initial coefficient load OR-gate
  wire                      load;
  //! Ring buffer initialization handshake
  wire assert_init = (((en_init == 1'b1) && (ringbuf_init == 1'b1)) == 1'b1);

  wire dopen_data_addr = (en_calc | en_init);
  wire dopen_coef_addr = en_calc;

  wire [ADDR_WIDTH-1:0] ibuf_data_addr;
  wire [ADDR_WIDTH-1:0] ibuf_coef_addr;

  wire en = en_init | en_calc;

  wire data_sel = (en_calc | conv_pass);

  assign load = (coeff_load == 1'b1) || (en_init == 1'b1);

  always @(negedge clk) begin
    if (rst_n == 1'b0) begin
      open_coef_addr <= 1'b0;
    end else if (en == 1'b1) begin
      open_coef_addr <= dopen_coef_addr;
    end
  end

  always @(negedge clk) begin
    if (rst_n == 1'b0) begin
      open_data_addr <= 1'b0;
    end else if (en == 1'b1) begin
      open_data_addr <= dopen_data_addr;
    end
  end

  //! Ring buffer
  ctrl_ramdrv_ringbuf#(
      .ADDR_WIDTH        ( ADDR_WIDTH )
  )u_ctrl_ramdrv_ringbuf(
      .clk            ( clk            ),
      .rst_n          ( rst_n          ),
      .cnt            ( en_calc        ),
      .init           ( assert_init    ),
      .data_bptr      ( data_bptr      ),
      .data_lptr      ( data_lptr      ),
      .data_hptr      ( data_hptr      ),
      .data_count_fin ( conv_pass      ),
      .rbuf_data_addr ( rbuf_data_addr )
  );


  //! Coefficient address counter
  ctrl_ramdrv_coefcnt #(
      .ADDR_WIDTH     ( ADDR_WIDTH     )
  ) ctrl_ramdrv_coefcnt_dut (
      .clk            ( clk            ),
      .rst_n          ( rst_n          ),
      .load           ( coeff_load     ),
      .cnt            ( en_calc        ),
      .coef_ptr       ( coef_ptr       ),
      .coef_addr      ( ibuf_coef_addr )
  );

  data_addr_mux#(
      .WIDTH     ( ADDR_WIDTH )
  )u_data_addr_mux(
      .sel       ( data_sel       ),
      .rbuf_addr ( rbuf_data_addr ),
      .head_addr ( data_hptr ),
      .data_addr  ( ibuf_data_addr  )
  );

  assign data_addr = (open_data_addr == 1'b0)? {ADDR_WIDTH{1'bz}} : ibuf_data_addr;
  assign coef_addr = (open_coef_addr == 1'b0)? {ADDR_WIDTH{1'bz}} : ibuf_coef_addr;

endmodule


module data_addr_mux #(
  parameter WIDTH = 16
)(
  input wire             sel,
  input wire [WIDTH-1:0] rbuf_addr,
  input wire [WIDTH-1:0] head_addr,
  output wire [WIDTH-1:0] data_addr
);

  assign data_addr = (sel == 1'b0)? head_addr : rbuf_addr;
  
endmodule