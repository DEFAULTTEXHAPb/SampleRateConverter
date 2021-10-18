`include "controller/ctrl_fsm.v"
`include "controller/ctrl_ifetch.v"
`include "controller/ctrl_ramdrv.v"
`include "controller/ctrl_regfdrv.v"

`define INSTR_WIDTH (1 + 1 + 2*REGFILE_ADDR_WIDTH + 4*DATA_ADDR_WIDTH)
module ctrl_top #(
    parameter integer REGFILE_ADDR_WIDTH = 3,
    parameter integer DATA_ADDR_WIDTH = 4
) (
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          en,
    input  wire                          prog,
    input  wire                          iw_valid,
    input  wire [   DATA_ADDR_WIDTH-1:0] load_coef_addr,
    input  wire [      `INSTR_WIDTH-1:0] instr_word,
    output wire                          ptr_req,
    output wire                          ptr_req_compl,
    output wire                          en_calc,
    output wire                          mac_init,
    output wire                          en_ram_pa,
    output wire                          en_ram_pb,
    output wire                          wr_ram_pa,
    output wire                          wr_ram_pb,
    output wire                          regf_rd,
    output wire                          regf_wr,
    output wire                          regf_en,
    output wire                          new_in,
    output wire                          new_out,
    output wire [   DATA_ADDR_WIDTH-1:0] data_addr,
    output wire [   DATA_ADDR_WIDTH-1:0] coef_addr,
    output wire [REGFILE_ADDR_WIDTH-1:0] ares,
    // output wire [REGFILE_ADDR_WIDTH-1:0] ars2,
    output wire [REGFILE_ADDR_WIDTH-1:0] aerr
    // output wire [REGFILE_ADDR_WIDTH-1:0] ard2
);

  //wire rst_n = ~rst;

  wire clr_rbuf;

  reg  req_complete = 1'b0;
  reg  idle = 1'b0;

  wire launch_valid;
  wire complete_valid;

  // wire en_devs;
  wire vector_pass, last_stage, last_vector;
  wire [2:0] ostate;

  wire count_passed;

  wire en_fetch;
  wire en_init;
  wire en_load;
  wire ptrs_req;
  wire ringbuf_addr_clr;
  wire ringbuf_init;
  wire count;

  //wire ramdrv_rst_n = ~ringbuf_addr_clr | rst_n;

  wire [REGFILE_ADDR_WIDTH-1:0] result_reg, error_reg;
  wire [DATA_ADDR_WIDTH-1:0] data_bptr, data_lptr, data_hptr, filt_coef_ptr, coef_ptr;
  wire ramdrv_rst_n = ~((en_load == 1'b1) | (rst_n == 1'b0) | (ringbuf_addr_clr == 1'b1));
  wire regfdrv_rst_n = ~((en_fetch == 1'b1) | (rst_n == 1'b0) | (en_calc == 1'b1));

  assign coef_ptr = (prog == 1'b0)? filt_coef_ptr : load_coef_addr;
  assign ptr_req_compl = req_complete;

  ctrl_fsm u_ctrl_fsm(
      .clk              ( clk              ),
      .rst_n            ( rst_n            ),
      .en               ( en               ),
      .iw_valid         ( iw_valid         ),
      .req_complete     ( req_complete     ),
      .count_passed     ( count_passed     ),
      .prog             ( prog             ),
      //.new_out          ( new_out          ),
      //.new_in           ( new_in           ),
      .en_fetch         ( en_fetch         ),
      .ptrs_req         ( ptrs_req         ),
      .ringbuf_addr_clr ( ringbuf_addr_clr ),
      .en_init          ( en_init          ),
      .mac_init         ( mac_init         ),
      .ringbuf_init     ( ringbuf_init     ),
      .regf_rd          ( regf_rd          ),
      .regf_en          ( regf_en          ),
      .ena              ( en_ram_pa        ),
      .wea              ( wr_ram_pa        ),
      .enb              ( en_ram_pb        ),
      .en_calc          ( en_calc          ),
      .count            ( count            ),
      .en_load          ( en_load          ),
      .regf_wr          ( regf_wr          ),
      .web              ( wr_ram_pb        )
  );


  ctrl_ifetch#(
      .RFAWIDTH   ( REGFILE_ADDR_WIDTH ),
      .DAWIDTH    ( DATA_ADDR_WIDTH )
  )u_ctrl_ifetch(
      .clk           ( clk           ),
      .rst_n         ( rst_n         ),
      .en_fetch      ( en_fetch      ),
      .iw_valid      ( iw_valid      ),
      .instr_word    ( instr_word    ),
      .lstg_f        ( new_out       ),
      .startups_f    ( new_in        ),
      .result_reg    ( result_reg    ),
      .error_reg     ( error_reg     ),
      .data_bptr     ( data_bptr     ),
      .data_lptr     ( data_lptr     ),
      .data_hptr     ( data_hptr     ),
      .filt_coef_ptr ( filt_coef_ptr )
  );

  ctrl_ramdrv#(
      .ADDR_WIDTH       ( DATA_ADDR_WIDTH )
  )u_ctrl_ramdrv(
      .clk              ( clk              ),
      .rst_n            ( ramdrv_rst_n     ),
      .en_calc          ( en_calc          ),
      .en_init          ( en_init          ),
      //.ringbuf_addr_clr ( ringbuf_addr_clr ),
      .ringbuf_init     ( ringbuf_init     ),
      .coeff_load       ( prog             ),
      .data_bptr        ( data_bptr        ),
      .data_lptr        ( data_lptr        ),
      .data_hptr        ( data_hptr        ),
      .coef_ptr         ( coef_ptr         ),
      .conv_pass        ( count_passed     ),
      .data_addr        ( data_addr        ),
      .coef_addr        ( coef_addr        )
  );

  ctrl_regfdrv #(
      .WIDTH      ( REGFILE_ADDR_WIDTH )
  )u_ctrl_regfdrv(
      .clk        ( clk        ),
      .rst_n      ( regfdrv_rst_n),
      .en_init    ( en_init    ),
      .en_load    ( en_load    ),
      .new_smp    ( new_in     ),
      .out_smp    ( new_out    ),
      .result_reg ( result_reg ),
      .error_reg  ( error_reg  ),
      .ares       ( ares       ),
      .aerr       ( aerr       )
  );

  always @(posedge clk) begin : valid_latch
    if ((rst_n == 1'b0) || (en_load == 1'b1)) begin
      req_complete <= 1'b0;
    end else if (iw_valid == 1'b1) begin
      req_complete <= 1'b1;
    end
  end

endmodule

`undef INSTR_WIDTH
