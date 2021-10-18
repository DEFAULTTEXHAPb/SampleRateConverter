
`include "controller/ctrl_top.v"

module tb_Controller;

  //GET DEFINE PARAMETERS
  localparam REGFILE_ADDR_W = 2;
  localparam DATA_ADDR_W = 4;
  localparam PROG_SIZE = 32;
  //#####################
  localparam ALLOC_INSTR_W = 1 + 1 + 2 * REGFILE_ADDR_W + 4 * DATA_ADDR_W;

  // runtime vars
  integer tiks = 0;

  // Pointer Struct
  reg i_lstg_f                             = 1'b0;
  reg i_startups_f                         = 1'b0;
  reg [REGFILE_ADDR_W-1:0] i_result_reg    = 2'b10;
  reg [REGFILE_ADDR_W-1:0] i_error_reg     = 2'b11;
  reg [DATA_ADDR_W-1:0]    i_data_bptr     = 4'b0000;
  reg [DATA_ADDR_W-1:0]    i_data_lptr     = 4'b1111;
  reg [DATA_ADDR_W-1:0]    i_data_hptr     = 4'b1000;
  reg [DATA_ADDR_W-1:0]    i_filt_coef_ptr = 4'b0000;

  //INPUT STIMULS
  reg rst = 1'b0;
  reg clk = 1'b0;
  reg en = 1'b0;
  reg prog = 1'b0;
  wire [ALLOC_INSTR_W-1:0] instr_word = {i_lstg_f, i_startups_f, i_result_reg, i_error_reg, i_data_bptr, i_data_lptr, i_data_hptr, i_filt_coef_ptr};
  reg iw_valid = 1'b1;
  reg [DATA_ADDR_W-1:0] load_coef_addr = {DATA_ADDR_W{1'b0}};

  //OUTPUT REACTION
  
  wire ptr_req, en_ram_pa, en_ram_pb, wr_ram_pa, wr_ram_pb, mac_init, en_calc, regf_rd, regf_wr, regf_en, new_in, new_out;

  wire [DATA_ADDR_W-1:0] data_addr, coef_addr;
  wire [REGFILE_ADDR_W-1:0] ares, aerr;
  reg [500-1:0] state;

  always #100 clk <= !clk;

  wire rst_n = ~rst;


  ctrl_top#(
      .REGFILE_ADDR_WIDTH ( REGFILE_ADDR_W ),
      .DATA_ADDR_WIDTH    ( DATA_ADDR_W )
  )u_ctrl_top(
      .clk                ( clk                ),
      .rst_n              ( rst_n              ),
      .en                 ( en                 ),
      .prog               ( prog               ),
      .iw_valid           ( iw_valid           ),
      .load_coef_addr     ( load_coef_addr     ),
      .instr_word         ( instr_word         ),
      .ptr_req            ( ptr_req            ),
      .en_calc            ( en_calc            ),
      .mac_init           ( mac_init           ),
      .en_ram_pa          ( en_ram_pa          ),
      .en_ram_pb          ( en_ram_pb          ),
      .wr_ram_pa          ( wr_ram_pa          ),
      .wr_ram_pb          ( wr_ram_pb          ),
      .regf_rd            ( regf_rd            ),
      .regf_wr            ( regf_wr            ),
      .regf_en            ( regf_en            ),
      .new_in             ( new_in             ),
      .new_out            ( new_out            ),
      .data_addr          ( data_addr          ),
      .coef_addr          ( coef_addr          ),
      .ares               ( ares               ),
      .aerr               ( aerr               )
  );




  //INDEPTH DUT SIGNAL PROBE
  //instruction struct
  wire lstg_f                          = u_ctrl_top.u_ctrl_ifetch.lstg_f;
  wire upse_f                          = u_ctrl_top.u_ctrl_ifetch.startups_f;
  wire [REGFILE_ADDR_W-1:0] result_reg = u_ctrl_top.u_ctrl_ifetch.result_reg;
  wire [REGFILE_ADDR_W-1:0] error_reg  = u_ctrl_top.u_ctrl_ifetch.error_reg;
  wire [DATA_ADDR_W-1:0] data_bptr     = u_ctrl_top.u_ctrl_ifetch.data_bptr;
  wire [DATA_ADDR_W-1:0] data_lptr     = u_ctrl_top.u_ctrl_ifetch.data_lptr;
  wire [DATA_ADDR_W-1:0] data_hptr     = u_ctrl_top.u_ctrl_ifetch.data_hptr;
  wire [DATA_ADDR_W-1:0] filt_coef_ptr = u_ctrl_top.u_ctrl_ifetch.filt_coef_ptr;
  //fsm state
  wire [2:0] dut_state = u_ctrl_top.u_ctrl_fsm.state;

  // programm pass flag
  reg pass;

  //clock start
  // localparam CLK_PERIOD = 10;
  // always #(CLK_PERIOD/2) clk=~clk;

`ifdef SIMPLE_REPORT
  initial begin
    $dumpfile("./simulation/tb_Controller.vcd");
    $dumpvars(0, tb_Controller);
  end
`else
  initial begin
    $dumpfile("./simulation/tb_Controller.vcd");
    $dumpvars();
  end
`endif

  // system reset
  initial begin
    rst <= 1'b0;
    #130 rst <= 1'b1;
    #1136 rst <= 1'b0;
  end

  // system clock enable
  initial begin
    en <= 1'b0;
    #320 en <= 1'b1;
  end

  // // program single run detect
  // always @(dut_state, pc) begin
  //   pass <= (dut_state == ctrl_top_dut.u_ctrl_fsm.S7);
  // end

  // instruction fetch
  // always @(posedge clk) begin
  //   instr_word <= (fetch) ? rom[pc] : instr_word;
  // end

  always @(dut_state) begin
    case (dut_state)
      u_ctrl_top.u_ctrl_fsm.PTR_REQ:   state = "Pointer Request";
      u_ctrl_top.u_ctrl_fsm.CALC_INIT: state = "Calculation Initial";
      u_ctrl_top.u_ctrl_fsm.CALC:      state = "CONVOLUTION";
      u_ctrl_top.u_ctrl_fsm.LOAD:      state = "LOAD_RESULT";
      default:                         state = "ERORR";
    endcase
  end

  initial begin : trap_exit
    #10_000_000;  // Wait a long time in simulation units (adjust as needed).
    $display("Caught by trap!!!!");
    $finish(2);
  end

endmodule
