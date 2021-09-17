`include "controller/ctrl_fsm.sv"
`include "controller/ctrl_pc.sv"
`include "controller/ctrl_olut.sv"
`include "controller/ctrl_ifetch.sv"
`include "controller/ctrl_ramdrv.sv"
`include "controller/ctrl_regfdrv.sv"

module ctrl_top #(
    parameter VEC_ID_WIDTH = 3,
    parameter REGFILE_ADDR_WIDTH = 3,
    parameter ALLOC_LENGTH_WIDTH = 4,
    parameter DATA_ADDR_WIDTH = 4,
    parameter INSTR_ADDR_WIDTH = $clog2(16)
) (
    input                                 clk,
    input                                 rst,
    input                                 en,
    input                                 prog,
    input        [       INSTR_WIDTH-1:0] instr_word,
    output logic                          fetch,
    output logic [  INSTR_ADDR_WIDTH-1:0] pc,
    output logic                          en_ram_pa,
    output logic                          en_ram_pb,
    output logic                          wr_ram_pa,
    output logic                          wr_ram_pb,
    output logic [   DATA_ADDR_WIDTH-1:0] data_addr,
    output logic [   DATA_ADDR_WIDTH-1:0] coef_addr,
    output logic                          rw,
    output logic [REGFILE_ADDR_WIDTH-1:0] ar1,
    output logic [REGFILE_ADDR_WIDTH-1:0] ar2,
    output logic [REGFILE_ADDR_WIDTH-1:0] ard
);


  localparam INSTR_WIDTH = 1 + 1 + VEC_ID_WIDTH + 2 * REGFILE_ADDR_WIDTH + 3 * DATA_ADDR_WIDTH;

  logic en_devs = ~prog && en;
  logic vector_pass, last_stage, last_vector;
  logic [2:0] ostate;

  ctrl_fsm u_ctrl_fsm (
      .clk        (clk),
      .rst        (rst),
      .en         (en_devs),
      .vector_pass(vector_pass),
      .last_stage (last_stage),
      .last_vector(last_vector),
      .ostate     (ostate)
  );

  logic pc_clr, pc_incr;
  logic clr = rst | pc_clr;

  ctrl_pc #(
      .INSTRADDRW(INSTR_ADDR_WIDTH)
  ) u_ctrl_pc (
      .clk    (clk),
      .clr    (clr),
      .pc_incr(pc_incr),
      .pc     (pc)
  );

  logic h_init, a_init, cnt, res_err, rf_rw, get_logic, new_in, new_out;

  ctrl_olut u_ctrl_olut (
      .fsm_state(ostate),
      .pc_clr   (pc_clr),
      .pc_incr  (pc_incr),
      .fetch    (fetch),
      .h_init   (h_init),
      .a_init   (a_init),
      .cnt      (cnt),
      .res_err  (res_err),
      .rf_rw    (rf_rw),
      .get_logic(get_logic),
      .new_in   (new_in),
      .new_out  (new_out)
  );

  logic [VEC_ID_WIDTH-1:0] vector_id;
  logic [REGFILE_ADDR_WIDTH-1:0] result_logic, error_logic;
  logic [ALLOC_LENGTH_WIDTH-1:0] vector_len;
  logic [DATA_ADDR_WIDTH-1:0] data_uptr, data_lptr, coef_ptr;
  logic lstg_f, upse_f;

  ctrl_ifetch #(
      .VIDWIDTH(VEC_ID_WIDTH),
      .RFAWIDTH(REGFILE_ADDR_WIDTH),
      .DAWIDTH (DATA_ADDR_WIDTH)
  ) u_ctrl_ifetch (
      .clk         (clk),
      .rst         (rst),
      .fetch       (fetch),
      .instr_word  (instr_word),
      .lstg_f      (last_stage),
      .upse_f      (last_vector),
      .vector_id   (vector_id),
      .result_logic(result_logic),
      .error_logic (error_logic),
      .data_uptr   (data_uptr),
      .data_lptr   (data_lptr),
      .coef_ptr    (coef_ptr)
  );



  ctrl_ramdrv #(
      .DATA_ADDRESS_WIDTH(DATA_ADDR_WIDTH),
      .DATA_OFFSET_WIDTH (ALLOC_LENGTH_WIDTH),
      .VECTOR_INDEX_WIDTH(VEC_ID_WIDTH)
  ) u_ctrl_ramdrv (
      .clk      (clk),
      .rst      (rst),
      .h_init   (h_init),
      .a_init   (a_init),
      .cnt      (cnt),
      .data_uptr(data_uptr),
      .data_lptr(data_lptr),
      .coef_ptr (coef_ptr),
      .vector_id(vector_id),
      .conv_pass(vector_pass),
      .data_addr(data_addr),
      .coef_addr(coef_addr)
  );



  ctrl_regfdrv #(
      .WIDTH(REGFILE_ADDR_WIDTH)
  ) u_ctrl_regfdrv (
      .clk         (clk),
      .rst         (rst),
      .en          (en_devs),
      .res_err     (res_err),
      .get_logic   (get_logic),
      .result_logic(result_logic),
      .error_logic (error_logic),
      .rf_rw       (rf_rw),
      .ar1         (ar1),
      .ar2         (ar2),
      .ard         (ard)
  );


endmodule
