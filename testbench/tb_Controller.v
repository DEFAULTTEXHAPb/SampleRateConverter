`include "controller/ctrl_top.v"
`include "clock_gen.v"

module tb_Controller;

    //GET DEFINE PARAMETERS
    localparam VEC_ID_W       = 3;
    localparam REGFILE_ADDR_W = 4;
    localparam ALLOC_LEN_W    = 5;
    localparam DATA_ADDR_W    = 6;
    localparam PROG_SIZE      = 32;
    //#####################
    localparam ALLOC_INSTR_W = 1+1+VEC_ID_W+2*REGFILE_ADDR_W+3*DATA_ADDR_W;

    // runtime vars
    integer tiks = 0;

    //INPUT STIMULS
    reg rst, en, prog, en_clk;
    reg [ALLOC_INSTR_W-1:0] instr_word;

    //OUTPUT REACTION
    wire clk;
    wire fetch, en_ram_pa, en_ram_pb, wr_ram_pa, wr_ram_pb, mac_init, accum, regf_rd, regf_wr, regf_en, new_in, new_out;
    wire [$clog2(PROG_SIZE)-1:0] pc;
    wire [DATA_ADDR_W-1:0] data_addr, coef_addr;
    wire [REGFILE_ADDR_W-1:0] ar1, ar2, ard;
    reg [100-1:0] state;

  clock_gen #(
    .FREQ ( 10000 ),
    .PHASE( 0 ),
    .DUTY ( 50 )
  )  clock_gen_dut (
    .enable (en_clk ),
    .clk    ( clk)
  );


  ctrl_top #(
    .VEC_ID_WIDTH        ( VEC_ID_W           ),
    .REGFILE_ADDR_WIDTH  ( REGFILE_ADDR_W     ),
    .ALLOC_LENGTH_WIDTH  ( ALLOC_LEN_W        ),
    .DATA_ADDR_WIDTH     ( DATA_ADDR_W        ),
    .INSTR_ADDR_WIDTH    ( $clog2(PROG_SIZE)  )
  ) ctrl_top_dut (
    .clk                 ( clk                ),
    .rst                 ( rst                ),
    .en                  ( en                 ),
    .prog                ( prog               ),
    .instr_word          ( instr_word         ),
    .fetch               ( fetch              ),
    .accum               ( accum              ),
    .mac_init            ( mac_init           ),
    .en_ram_pa           ( en_ram_pa          ),
    .en_ram_pb           ( en_ram_pb          ),
    .wr_ram_pa           ( wr_ram_pa          ),
    .wr_ram_pb           ( wr_ram_pb          ),
    .regf_rd             ( regf_rd            ),
    .regf_wr             ( regf_wr            ),
    .regf_en             ( regf_en            ),
    .new_in              ( new_in             ),
    .new_out             ( new_out            ),
    .pc                  ( pc                 ),
    .data_addr           ( data_addr          ),
    .coef_addr           ( coef_addr          ),
    .ar1                 ( ar1                ),
    .ar2                 ( ar2                ),
    .ard                 ( ard                )
  );


    //INDEPTH DUT SIGNAL PROBE
    //instruction struct
        wire                      lstg_f     = ctrl_top_dut.u_ctrl_ifetch.lstg_f;
        wire                      upse_f     = ctrl_top_dut.u_ctrl_ifetch.upse_f;
        wire [VEC_ID_W-1:0]       vector_id  = ctrl_top_dut.u_ctrl_ifetch.vector_id;
        wire [REGFILE_ADDR_W-1:0] result_reg = ctrl_top_dut.u_ctrl_ifetch.result_reg;
        wire [REGFILE_ADDR_W-1:0] error_reg  = ctrl_top_dut.u_ctrl_ifetch.error_reg;
        wire [ALLOC_LEN_W-1:0]    data_uptr  = ctrl_top_dut.u_ctrl_ifetch.data_uptr;
        wire [DATA_ADDR_W-1:0]    data_lptr  = ctrl_top_dut.u_ctrl_ifetch.data_lptr;
        wire [DATA_ADDR_W-1:0]    coef_ptr   = ctrl_top_dut.u_ctrl_ifetch.coef_ptr;
    //fsm state
        wire [2:0] dut_state = ctrl_top_dut.u_ctrl_fsm.ostate;

    // define programm memory
    reg [ALLOC_INSTR_W-1:0] rom [0:PROG_SIZE-1];

    // programm memory initialization
    initial begin
        $readmemb("./simulation/big_prog.txt", rom);
    end

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

    always @(posedge clk) begin
        tiks = tiks + 1;
    end

    // system initialization
    initial begin
        #10 rst <= 1'b0; en <= 1'b0; prog <= 1'b0; en_clk <= 1'b0;
        #10 rst <= 1'b0; en <= 1'b0; prog <= 1'b0; en_clk <= 1'b1;
        #10 rst <= 1'b1; en <= 1'b1; prog <= 1'b0; en_clk <= 1'b1;
        #10 rst <= 1'b0; en <= 1'b1; prog <= 1'b0; en_clk <= 1'b1;
    end

    // program single run detect
    always @(dut_state, pc) begin
        pass <= (dut_state == ctrl_top_dut.u_ctrl_fsm.S7);
    end

    // instruction fetch
    always @(posedge clk) begin
        instr_word <= (fetch)? rom[pc] : instr_word;
    end

    // test finish
    initial begin
        if (pass || (tiks == 10)) $finish();
    end

    always @(dut_state) begin
      case(dut_state)
        ctrl_top_dut.u_ctrl_fsm.S1 : state = "ALLOC";
        ctrl_top_dut.u_ctrl_fsm.S2 : state = "LOAD_RAM_INIT_MAC";
        ctrl_top_dut.u_ctrl_fsm.S3 : state = "CONVOLUTION";
        ctrl_top_dut.u_ctrl_fsm.S4 : state = "LOAD_RESULT";
        ctrl_top_dut.u_ctrl_fsm.S5 : state = "LOAD_ERROR";
        ctrl_top_dut.u_ctrl_fsm.S6 : state = "OUTPUT_SAMPLE";
        ctrl_top_dut.u_ctrl_fsm.S7 : state = "INPUT_SAMPLE";
        ctrl_top_dut.u_ctrl_fsm.S8 : state = "PC_INCREMENT";
      endcase
    end

endmodule