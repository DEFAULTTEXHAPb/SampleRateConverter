`include "Controller.v"

module tb_Controller;

    //GET DEFINE PARAMETERS
    localparam VEC_ID_W = `VEC_ID_W;
    localparam REGFILE_ADDR_W = `REGFILE_ADDR_W;
    localparam ALLOC_LEN_W = `ALLOC_LEN_W;
    localparam DATA_ADDR_W = `DATA_ADDR_W;
    localparam PROG_SIZE = `PROG_SIZE;
    //#####################
    localparam ALLOC_INSTR_W = 1+1+VEC_ID_W+2*REGFILE_ADDR_W+ALLOC_LEN_W+2*DATA_ADDR_W;

    // runtime vars
    integer tiks = 0;

    //INPUT STIMULS
    reg clk, rst, en, prog;
    reg [ALLOC_INSTR_W-1:0] instr_word;

    //OUTPUT REACTION
    wire fetch, en_ram_pa, en_ram_pb, wr_ram_pa, wr_ram_pb, rw;
    wire [$clog2(`PROG_SIZE)-1:0] pc;
    wire [DATA_ADDR_W-1:0] data_addr, coef_addr;
    wire [REGFILE_ADDR_W-1:0] ar1, ar2, ard;

    top#(
        .VEC_ID_WIDTH       ( VEC_ID_W ),
        .REGFILE_ADDR_WIDTH ( REGFILE_ADDR_W ),
        .ALLOC_LENGTH_WIDTH ( ALLOC_LEN_W ),
        .DATA_ADDR_WIDTH    ( DATA_ADDR_W ),
        .INSTR_ADDR_WIDTH   ( $clog2(PROG_SIZE) )
    )u_top(
        //INPUT
        .clk                ( clk                ),
        .rst                ( rst                ),
        .en                 ( en                 ),
        .prog               ( prog               ),
        .instr_word         ( instr_word         ),
        //OUTPUT
        .fetch              ( fetch              ),
        .pc                 ( pc                 ),
        .en_ram_pa          ( en_ram_pa          ),
        .en_ram_pb          ( en_ram_pb          ),
        .wr_ram_pa          ( wr_ram_pa          ),
        .wr_ram_pb          ( wr_ram_pb          ),
        .data_addr          ( data_addr          ),
        .coef_addr          ( coef_addr          ),
        .rw                 ( rw                 ),
        .ar1                ( ar1                ),
        .ar2                ( ar2                ),
        .ard                ( ard                )
    );

    //INDEPTH DUT SIGNALS
    //instruction struct
        wire                       lstg_f     = u_top.u_InstrFetch.lstg_f;
        wire                       upse_f     = u_top.u_InstrFetch.upse_f;
        wire [VEC_ID_W-1:0]       vector_id  = u_top.u_InstrFetch.vector_id;
        wire [REGFILE_ADDR_W-1:0] result_reg = u_top.u_InstrFetch.result_reg;
        wire [REGFILE_ADDR_W-1:0] error_reg  = u_top.u_InstrFetch.error_reg;
        wire [ALLOC_LEN_W-1:0]    vector_len = u_top.u_InstrFetch.vector_len;
        wire [DATA_ADDR_W-1:0]    data_ptr   = u_top.u_InstrFetch.data_ptr;
        wire [DATA_ADDR_W-1:0]    coef_ptr   = u_top.u_InstrFetch.coef_ptr;
    //fsm state
        wire [2:0] dut_state = u_top.u_FSM.ostate;

    // define programm memory
    reg [ALLOC_INSTR_W-1:0] rom [0:PROG_SIZE-1];

    // programm memory initialization
    initial begin
        $readmemb("./simulation/big_prog.txt", rom);
    end

    // programm pass flag
    reg pass;

    //clock start
    localparam CLK_PERIOD = 10;
    always #(CLK_PERIOD/2) clk=~clk;

`ifdef SIMPLE_REPORT
    initial begin
        $dumpfile("tb_Controller.vcd");
        $dumpvars(0, tb_Controller);
    end
`else
    initial begin
        $dumpfile("tb_Controller.vcd");
        $dumpvars();
    end
`endif

    always @(posedge clk) begin
        tiks = tiks + 1;
    end

    // system initialization
    initial begin
        #1 rst <= 1'bx; clk <= 1'bx; en <= 1'bx; prog <= 1'bx;
        #2 rst <= 1'b0; clk <= 1'b0; en <= 1'b0; prog <= 1'b0;
        #(CLK_PERIOD*3) rst <= 1'b1; en <= 1'b0; prog <= 1'b0;
        #(CLK_PERIOD*2+2) rst <= 1'b0; en <= 1'b1; prog <= 1'b0;
    end

    // program single run detect
    always @(dut_state, pc) begin
        pass <= (dut_state == u_top.u_FSM.S7);
    end

    // instruction fetch
    always @(posedge clk) begin
        instr_word <= (fetch)? rom[pc] : instr_word;
    end

    // test finish
    initial begin
        if (pass || (tiks == 10)) $finish();
    end

endmodule