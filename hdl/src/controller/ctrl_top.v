`include "controller/ctrl_fsm.v"
`include "controller/ctrl_ifetch.v"
`include "controller/ctrl_olut.v"
`include "controller/ctrl_pc.v"
`include "controller/ctrl_ramdrv.v"
`include "controller/ctrl_regfdrv.v"

module ctrl_top #(
    parameter VEC_ID_WIDTH = 3,
    parameter REGFILE_ADDR_WIDTH = 3,
    parameter ALLOC_LENGTH_WIDTH = 4,
    parameter DATA_ADDR_WIDTH = 4,
    parameter INSTR_ADDR_WIDTH = $clog2(16)
    `define INSTR_WIDTH 1 + 1 + VEC_ID_WIDTH + 2*REGFILE_ADDR_WIDTH + 3*DATA_ADDR_WIDTH
  )(
    input  wire                          clk,
    input  wire                          rst,
    input  wire                          en,
    input  wire                          prog,
    input  wire [`INSTR_WIDTH-1:0]       instr_word,
    output wire                          fetch,
    output wire                          accum,
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
    output wire [INSTR_ADDR_WIDTH-1:0]   pc,
    output wire [DATA_ADDR_WIDTH-1:0]    data_addr,
    output wire [DATA_ADDR_WIDTH-1:0]    coef_addr,
    output wire [REGFILE_ADDR_WIDTH-1:0] ar1,
    output wire [REGFILE_ADDR_WIDTH-1:0] ar2,
    output wire [REGFILE_ADDR_WIDTH-1:0] ard
  );

  wire en_devs = ~prog && en;
  wire vector_pass, last_stage, last_vector;
  wire [2:0] ostate;

  wire pc_clr, pc_incr;
  wire clr = rst | pc_clr;

  wire [VEC_ID_WIDTH-1:0] vector_id;
  wire [REGFILE_ADDR_WIDTH-1:0] result_reg, error_reg;
  wire [ALLOC_LENGTH_WIDTH-1:0] vector_len;
  wire [DATA_ADDR_WIDTH-1:0] data_uptr, data_lptr, coef_ptr;
  wire                        lstg_f, upse_f;
  wire                        cnt;

  ctrl_fsm u_ctrl_fsm(
             .clk         ( clk         ),
             .rst         ( rst         ),
             .en          ( en_devs     ),
             .vector_pass ( vector_pass ),
             .last_stage  ( last_stage  ),
             .last_vector ( last_vector ),
             .ostate      ( ostate      )
           );

  ctrl_pc#(
           .INSTRADDRW ( INSTR_ADDR_WIDTH )
         )u_ctrl_pc(
           .clk     ( clk     ),
           .clr     ( clr     ),
           .pc_incr ( pc_incr ),
           .pc      ( pc      )
         );

  ctrl_olut ctrl_olut_dut (
              .fsm_state    ( ostate       ),
              .prog         ( prog         ),
              .pc_clr       ( pc_clr       ),
              .pc_incr      ( pc_incr      ),
              .fetch        ( fetch        ),
              .accum        ( accum        ),
              .mac_init     ( mac_init     ),
              .res_err      ( res_err      ),
              .wea          ( wr_ram_pa    ),
              .web          ( wr_ram_pb    ),
              .ena          ( en_ram_pa    ),
              .enb          ( en_ram_pb    ),
              .regf_rd      ( regf_rd      ),
              .regf_wr      ( regf_wr      ),
              .regf_en      ( regf_en      ),
              .new_in       ( new_in       ),
              .new_out      ( new_out      ),
              .addr_clr     ( addr_clr     ),
              .header_init  ( header_init  ),
              .ringbuf_init ( ringbuf_init ),
              .coeff_load   ( coeff_load   ),
              .cnt          ( cnt          ),
              .head_read    ( head_read    ),
              .head_incr    ( head_incr    )
            );

  ctrl_ifetch#(
               .VIDWIDTH   ( VEC_ID_WIDTH ),
               .RFAWIDTH   ( REGFILE_ADDR_WIDTH ),
               .DAWIDTH    ( DATA_ADDR_WIDTH )
             )u_ctrl_ifetch(
               .clk        ( clk        ),
               .rst        ( rst        ),
               .fetch      ( fetch      ),
               .instr_word ( instr_word ),
               .lstg_f     ( last_stage ),
               .upse_f     ( last_vector),
               .vector_id  ( vector_id  ),
               .result_reg ( result_reg ),
               .error_reg  ( error_reg  ),
               .data_uptr  ( data_uptr  ),
               .data_lptr  ( data_lptr  ),
               .coef_ptr   ( coef_ptr   )
             );

  ctrl_ramdrv #(
                .ADDR_WIDTH   ( DATA_ADDR_WIDTH   ),
                .OFFSET_WIDTH ( ALLOC_LENGTH_WIDTH ),
                .INDEX_WIDTH  ( VEC_ID_WIDTH  )
              ) ctrl_ramdrv_dut (
                .clk          ( clk          ),
                .rst          ( rst          ),
                .addr_clr     ( addr_clr     ),
                .header_init  ( header_init  ),
                .ringbuf_init ( ringbuf_init ),
                .coeff_load   ( coeff_load   ),
                .cnt          ( cnt          ),
                .head_read    ( head_read    ),
                .head_incr    ( head_incr    ),
                .data_uptr    ( data_uptr    ),
                .data_lptr    ( data_lptr    ),
                .coef_ptr     ( coef_ptr     ),
                .vector_id    ( vector_id    ),
                .conv_pass    ( conv_pass    ),
                .data_addr    ( data_addr    ),
                .coef_addr    ( coef_addr    )
              );

  ctrl_regfdrv  #(
                  .WIDTH ( REGFILE_ADDR_WIDTH )
                ) ctrl_regfdrv_dut (
                  .clk        ( clk        ),
                  .rst        ( rst        ),
                  .mac_init   ( mac_init   ),
                  .w_r        ( w_r        ),
                  .new_smp    ( new_smp    ),
                  .res_err    ( res_err    ),
                  .result_reg ( result_reg ),
                  .error_reg  ( error_reg  ),
                  .ard        ( ard        ),
                  .ar1        ( ar1        ),
                  .ar2        ( ar2        )
                );

endmodule

`undef INSTR_WIDTH
