`include "glb_macros.vh"
`include "controller/ctrl_ramdrv_coefcnt.v"
`include "controller/ctrl_ramdrv_header.v"
`include "controller/ctrl_ramdrv_ringbuf.v"

module ctrl_ramdrv #(
    parameter integer ADDR_WIDTH   = 12,
    parameter integer OFFSET_WIDTH = 10,
    parameter integer INDEX_WIDTH  = 5
) (
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   addr_clr,
    input  wire                   header_init,
    input  wire                   ringbuf_init,
    input  wire                   coeff_load,
    input  wire                   cnt,
    input  wire                   head_read,
    input  wire                   head_incr,
    input  wire [ ADDR_WIDTH-1:0] data_uptr,
    input  wire [ ADDR_WIDTH-1:0] data_lptr,
    input  wire [ ADDR_WIDTH-1:0] coef_ptr,
    input  wire [INDEX_WIDTH-1:0] vector_id,
    output wire                   conv_pass,
    output wire [ ADDR_WIDTH-1:0] data_addr,
    output wire [ ADDR_WIDTH-1:0] coef_addr
);

  wire [OFFSET_WIDTH-1 : 0] head_offset;
  wire [  ADDR_WIDTH-1 : 0] rbuf_data_addr;
  wire [  ADDR_WIDTH-1 : 0] rbuf_head_addr;
  wire [  ADDR_WIDTH-1 : 0] dlength;
  wire [OFFSET_WIDTH-1 : 0] length;
  wire                      clr;

  reg [ADDR_WIDTH-1:0] qlength = {ADDR_WIDTH{1'b0}};


  assign dlength = data_uptr - data_lptr;
  assign rbuf_head_addr = `WORD_EXT(OFFSET_WIDTH, ADDR_WIDTH, head_offset) + data_uptr;
  assign clr = addr_clr | rst;
  assign data_addr = (cnt == 1'b0)? rbuf_head_addr : rbuf_data_addr;
  assign length = qlength[OFFSET_WIDTH-1:0];

  //! Ring buffer
  ctrl_ramdrv_ringbuf #(
      .ADDR_WIDTH     ( ADDR_WIDTH     ),
      .OFST_WIDTH     ( OFFSET_WIDTH   )
  ) ctrl_ramdrv_ringbuf_dut (
      .clk            ( clk            ),
      .clr            ( clr            ),
      .cnt            ( cnt            ),
      .init           ( ringbuf_init   ),
      .data_uptr      ( data_uptr      ),
      .data_lptr      ( data_lptr      ),
      .head_offset    ( head_offset    ),
      .data_count_fin ( conv_pass      ),
      .rbuf_data_addr ( rbuf_data_addr )
  );

  //! Header
  ctrl_ramdrv_header #(
      .OFFSET_WIDTH   ( OFFSET_WIDTH   ),
      .INDEX_WIDTH    ( INDEX_WIDTH    )
  ) ctrl_ramdrv_header_dut (
      .clk            ( clk            ),
      .clr            ( rst            ),
      .init           ( header_init    ),
      .head_read      ( head_read      ),
      .head_incr      ( head_incr      ),
      .index          ( vector_id      ),
      .length         ( length         ),
      .head_offset    ( head_offset    )
  );

  //! Coefficient address counter
  ctrl_ramdrv_coefcnt #(
      .ADDR_WIDTH     ( ADDR_WIDTH     )
  ) ctrl_ramdrv_coefcnt_dut (
      .clk            ( clk            ),
      .clr            ( clr            ),
      .load           ( coeff_load     ),
      .cnt            ( cnt            ),
      .coef_ptr       ( coef_ptr       ),
      .coef_addr      ( coef_addr      )
  );

  always @(posedge clk) begin : len_calc
    if (rst == 1'b0) begin
      qlength <= {ADDR_WIDTH{1'b0}};
    end else begin
      qlength <= dlength;
    end
  end


`ifdef DEBUG
  localparam DBG_DIFF = ADDR_WIDTH-OFFSET_WIDTH;
  wire [DBG_DIFF-1:0] dbg_dl = dlength[ADDR_WIDTH-1:OFFSET_WIDTH];
  wire [DBG_DIFF-1:0] dbg_ql = qlength[ADDR_WIDTH-1:OFFSET_WIDTH];
  always@(dlength) begin
    if ((dbg_dl != {DBG_DIFF{1'b0}})||(dbg_dl != {DBG_DIFF{1'b0}})) begin
      $finish(2);
    end
  end
`endif

endmodule