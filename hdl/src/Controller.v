`timescale 1ns / 1ps
`define GND_BUS(w) {w{1'b0}}

module top #(
    parameter VEC_ID_WIDTH = 3,
    parameter REGFILE_ADDR_WIDTH = 3,
    parameter ALLOC_LENGTH_WIDTH = 4,
    parameter DATA_ADDR_WIDTH = 4,
    parameter INSTR_ADDR_WIDTH = $clog2(32)
)(
    input clk, rst, en, prog,
    input [INSTR_WIDTH-1:0]  instr_word,
    output wire fetch,
    output wire [INSTR_ADDR_WIDTH-1:0] pc,
    output wire             en_ram_pa, en_ram_pb,
    output wire              wr_ram_pa, wr_ram_pb,
    output wire  [DATA_ADDR_WIDTH-1:0] data_addr, coef_addr,
    output wire             rw,
    output wire [REGFILE_ADDR_WIDTH-1:0] ar1, ar2, ard
);

    localparam INSTR_WIDTH = 1 + 1 + VEC_ID_WIDTH + 2*REGFILE_ADDR_WIDTH + 3*DATA_ADDR_WIDTH;

    wire en_devs = ~prog && en;
    wire vector_pass, last_stage, last_vector;
    wire [2:0] ostate;

    FSM u_FSM(
        .clk         ( clk         ),
        .rst         ( rst         ),
        .en          ( en_devs     ),
        .vector_pass ( vector_pass ),
        .last_stage  ( last_stage  ),
        .last_vector ( last_vector ),
        .ostate      ( ostate      )
    );

    wire pc_clr, pc_incr;
    wire clr = rst | pc_clr;

    ProgCnt#(
        .INSTRADDRW ( INSTR_ADDR_WIDTH )
     )u_ProgCnt(
        .clk     ( clk     ),
        .clr     ( clr     ),
        .pc_incr ( pc_incr ),
        .pc      ( pc      )
    );

    wire h_init, a_init, cnt,
         res_err, rf_rw, get_reg, new_in, new_out;

    OutLut u_OutLut(
        .fsm_state ( ostate    ),
        .pc_clr    ( pc_clr    ),
        .pc_incr   ( pc_incr   ),
        .fetch     ( fetch     ),
        .h_init    ( h_init    ),
        .a_init    ( a_init    ),
        .cnt       ( cnt       ),
        .res_err   ( res_err   ),
        .rf_rw     ( rf_rw     ),
        .get_reg   ( get_reg   ),
        .new_in    ( new_in    ),
        .new_out   ( new_out   )
    );

    wire [VEC_ID_WIDTH-1:0] vector_id;
    wire [REGFILE_ADDR_WIDTH-1:0] result_reg, error_reg;
    wire [ALLOC_LENGTH_WIDTH-1:0] vector_len;
    wire [DATA_ADDR_WIDTH-1:0] data_uptr, data_lptr, coef_ptr;

    InstrFetch#(
        .VIDWIDTH   ( VEC_ID_WIDTH ),
        .RFAWIDTH   ( REGFILE_ADDR_WIDTH ),
        .DAWIDTH    ( DATA_ADDR_WIDTH )
    )u_InstrFetch(
        .clk        ( clk        ),
        .rst        ( rst        ),
        .fetch      ( fetch      ),
        .instr_word ( instr_word ),
        .lstg_f     ( lstg_f     ),
        .upse_f     ( upse_f     ),
        .vector_id  ( vector_id  ),
        .result_reg ( result_reg ),
        .error_reg  ( error_reg  ),
        .data_uptr  ( data_uptr  ),
        .data_lptr  ( data_lptr  ),
        .coef_ptr   ( coef_ptr   )
    );



    RAMDriver#(
        .DATA_ADDRESS_WIDTH ( DATA_ADDR_WIDTH ),
        .DATA_OFFSET_WIDTH  ( ALLOC_LENGTH_WIDTH ),
        .VECTOR_INDEX_WIDTH ( VEC_ID_WIDTH )
    )u_RAMDriver(
        .clk                ( clk                ),
        .rst                ( rst                ),
        .h_init             ( h_init             ),
        .a_init             ( a_init             ),
        .cnt                ( cnt                ),
        .data_uptr          ( data_uptr          ),
        .data_lptr          ( data_lptr          ),
        .coef_ptr           ( coef_ptr           ),
        .vector_id          ( vector_id          ),
        .conv_pass          ( conv_pass          ),
        .data_addr          ( data_addr          ),
        .coef_addr          ( coef_addr          )
    );



    RegFileDriver#(
        .WIDTH      ( REGFILE_ADDR_WIDTH)
     )u_RegFileDriver(
        .clk        ( clk        ),
        .rst        ( rst        ),
        .en         ( en_devs    ),
        .res_err    ( res_err    ),
        .rf_rw      ( rf_rw      ),
        .get_reg    ( get_reg    ),
        .result_reg ( result_reg ),
        .error_reg  ( error_reg  ),
        .rw         ( rw         ),
        .ar1        ( ar1        ),
        .ar2        ( ar2        ),
        .ard        ( ard        )
    );

    
endmodule

module FSM (
    input  wire        clk, rst, en,
    input  wire        vector_pass, last_stage, last_vector,
    output wire [2:0]  ostate
);

    reg [2:0] cstate, nstate;

    localparam [2:0]
        S1 = 3'b000,  // Memory allocation
        S2 = 3'b001,  // Load sample from regfile to RAM and initialize MAC
        S3 = 3'b010,  // Vector convolution on MAC
        S4 = 3'b011,  // Load result from MAC to register file
        S5 = 3'b100,  // Load error from MAC to register file
        S6 = 3'b101,  // Load system output sample
        S7 = 3'b110,  // Load new sapmle from audio bus
        S8 = 3'b111;   // Allocation list counter increment

    always @(posedge clk) begin : state_switching
        if (!rst) begin
            if (en) begin
                cstate <= nstate;
            end
        end else begin
            cstate <= S1;
        end
    end

    always @(cstate) begin : next_state_switching_predition
        case (cstate)
            S1:
                nstate = S2;
            S2:
                nstate = S3;
            S3:
                nstate = (!vector_pass)? S3 : S4;
            S4:
                nstate = S5;
            S5:
                nstate = (!last_stage)? S8 : S6;
            S6:
                nstate = (!last_vector)? S8 : S7;
            S7:
                nstate = S8;
            S8:
                nstate = S1;
        endcase
    end

    assign ostate = cstate;

`ifdef DEBUG
    reg [8*50-1:0] ostate_ascii;
    always @(ostate) begin : state_ascii
        case (ostate)
            S1 : ostate_ascii = "ALLOC";
            S2 : ostate_ascii = "LOAD_AND_INIT";
            S3 : ostate_ascii = "CONVOLUTION";
            S4 : ostate_ascii = "LOAD_RESULT";
            S5 : ostate_ascii = "LOAD_ERROR";
            S6 : ostate_ascii = "LOAD_OUTPUT";
            S7 : ostate_ascii = "LOAD_INPUT";
            S8 : ostate_ascii = "PC_INCREMENT";
            default: begin
                ostate_ascii = "XSTATE";
            end
        endcase
    end
`endif
    
endmodule

module ProgCnt #(
    parameter INSTRADDRW = 8
) (
    input clk, clr, pc_incr,
    output reg [INSTRADDRW-1:0] pc
);

    always @(posedge clk) begin
        if (!clr) begin
            pc <= (pc_incr)? pc + 1 : pc;
        end else begin
            pc <= `GND_BUS(INSTRADDRW);
        end
    end
    
endmodule

module OutLut (
    input [2:0] fsm_state,
    output reg pc_clr, pc_incr,
    output reg fetch,
    output reg h_init, a_init, cnt, 
    output reg res_err, rf_rw, get_reg,
    output reg new_in, new_out
);

    localparam [2:0]
        S1 = 3'b000,  // Memory allocation
        S2 = 3'b001,  // Load sample from regfile to RAM and initialize MAC
        S3 = 3'b010,  // Vector convolution on MAC
        S4 = 3'b011,  // Load result from MAC to register file
        S5 = 3'b100,  // Load error from MAC to register file
        S6 = 3'b101,  // Load system output sample
        S7 = 3'b110,  // Load new sapmle from audio bus
        S8 = 3'b111;   // Allocation list counter increment

    always @(fsm_state) begin
        pc_clr      = (fsm_state == S7);
        pc_incr     = (fsm_state == S8);
        fetch       = (fsm_state == S1);
        h_init      = (fsm_state == S1);
        a_init      = (fsm_state == S2);
        cnt         = (fsm_state == S3);
        res_err     = (fsm_state == S4);
        rf_rw       = (fsm_state == S4)||(fsm_state == S5)||(fsm_state == S7);
        get_reg     = (fsm_state == S2)||(fsm_state == S7);
        new_in      = (fsm_state == S7);
        new_out     = (fsm_state == S6);
    end
    
endmodule

module InstrFetch #(
    parameter VIDWIDTH = 3,
    parameter RFAWIDTH = 3,
    parameter DAWIDTH  = 4
)(
    input                       clk, rst, fetch,
    input      [INSTRWIDTH-1:0] instr_word,
    output reg                  lstg_f,
    output reg                  upse_f,
    output reg [VIDWIDTH-1:0]   vector_id,
    output reg [RFAWIDTH-1:0]   result_reg,
    output reg [RFAWIDTH-1:0]   error_reg,
    output reg [DAWIDTH-1:0]    data_uptr,
    output reg [DAWIDTH-1:0]    data_lptr,
    output reg [DAWIDTH-1:0]    coef_ptr
);
    localparam INSTRWIDTH = 1 + 1 + VIDWIDTH + 2*RFAWIDTH + 3*DAWIDTH;

    always @(posedge clk) begin
        if (!rst) begin
            if (fetch) {lstg_f, upse_f, vector_id, result_reg, error_reg, data_uptr, data_lptr, coef_ptr} <= instr_word;
        end else begin
            {lstg_f, upse_f, vector_id, result_reg, error_reg, data_uptr, data_lptr, coef_ptr} <= `GND_BUS(INSTRWIDTH);
        end
    end
    
endmodule

//TODO: Add addr counter unit!!!
module RAMDriver #(
    parameter DATA_ADDRESS_WIDTH = 12,
    parameter DATA_OFFSET_WIDTH = 5,
    parameter VECTOR_INDEX_WIDTH = 5
)(
    input  wire                          clk,
    input  wire                          rst,
    input  wire                          h_init,
    input  wire                          a_init,
    input  wire                          cnt,
    input  wire [DATA_ADDRESS_WIDTH-1:0] data_uptr,
    input  wire [DATA_ADDRESS_WIDTH-1:0] data_lptr,
    input  wire [DATA_ADDRESS_WIDTH-1:0] coef_ptr,
    input  wire [VECTOR_INDEX_WIDTH-1:0] vector_id,
    output wire                          conv_pass,
    output wire [DATA_ADDRESS_WIDTH-1:0] data_addr,
    output wire [DATA_ADDRESS_WIDTH-1:0] coef_addr
);

    wire                          data_count_fin;
    wire                          coef_count_fin;
    wire                          pass = data_count_fin & coef_count_fin;

    wire [DATA_OFFSET_WIDTH-1:0]  head_offset;
    wire [DATA_ADDRESS_WIDTH-1:0] rb_data_addr;
    wire [DATA_ADDRESS_WIDTH-1:0] init_data_addr = (cnt == 1'b0)? head_offset + data_uptr : {DATA_ADDRESS_WIDTH{1'bz}};
    wire [DATA_OFFSET_WIDTH-1:0]  length = data_uptr - data_lptr;

    assign data_addr = (cnt == 1'b1)? rb_data_addr : init_data_addr;
    assign conv_pass = pass;

`ifdef DEBUG
    always @(*) begin
        if ((cnt == 1'b1)&((data_count_fin ^ coef_count_fin) == 1'b1)) begin
            $display("Unable word! (Unit: %m; File: Controller.v; line: 117; time: %t)", $time);
            $finish(2);
        end
    end
`endif

    DataRingBuffer#(
        .DATA_ADDRESS_WIDTH ( DATA_ADDRESS_WIDTH ),
        .DATA_OFFSET_WIDTH  ( DATA_OFFSET_WIDTH )
    )u_DataRingBuffer(
        .clk                ( clk                ),
        .clr                ( rst                ),
        .cnt                ( cnt                ),
        .init               ( a_init             ),
        .data_uptr          ( data_uptr          ),
        .data_lptr          ( data_lptr          ),
        .head_offset        ( head_offset        ),
        .data_count_fin     ( data_count_fin     ),
        .data_addr          ( rb_data_addr       )
    );

    HeadRegs#(
        .DATA_OFFSET_WIDTH ( DATA_OFFSET_WIDTH ),
        .VECTOR_INDEX_WIDTH ( VECTOR_INDEX_WIDTH )
    )u_HeadRegs(
        .clk               ( clk               ),
        .rst               ( rst               ),
        .init              ( h_init            ),
        .head_inc          ( pass              ),
        .read_reg          ( a_init            ),
        .index             ( vector_id         ),
        .length            ( length            ),
        .head_offset       ( head_offset       )
    );

    CoefAddrCounter#(
        .DATA_ADDRESS_WIDTH ( DATA_ADDRESS_WIDTH ),
        .DATA_OFFSET_WIDTH  ( DATA_OFFSET_WIDTH )
    )u_CoefAddrCounter(
        .clk                ( clk                ),
        .clr                ( rst                ),
        .load               ( a_init             ),
        .cnt                ( cnt                ),
        .coef_ptr           ( coef_ptr           ),
        .length             ( length             ),
        .coef_count_fin     ( coef_count_fin     ),
        .coef_addr          ( coef_addr          )
    );

endmodule

module DataRingBuffer #(
    parameter DATA_ADDRESS_WIDTH = 12,
    parameter DATA_OFFSET_WIDTH = 10
)(
    input  wire                          clk,
    input  wire                          clr,
    input  wire                          cnt,
    input  wire                          init,
    input  wire [DATA_ADDRESS_WIDTH-1:0] data_uptr,
    input  wire [DATA_ADDRESS_WIDTH-1:0] data_lptr,
    input  wire [DATA_OFFSET_WIDTH-1:0]  head_offset,
    output wire                          data_count_fin,
    output wire [DATA_ADDRESS_WIDTH-1:0] data_addr
);

    localparam [1:0] INIT_BUFFER = 2'b10;
    localparam [1:0] PROC_BUFFER = 2'b01;
    localparam [1:0] SLEEP       = 2'b00;

    reg  [DATA_ADDRESS_WIDTH-1:0] rbuf_data_addr;
    reg  [DATA_ADDRESS_WIDTH-1:0] data_uptr_reg;
    reg  [DATA_ADDRESS_WIDTH-1:0] data_lptr_reg;

    wire [DATA_ADDRESS_WIDTH-1:0] data_head = data_uptr + head_offset;
    wire [DATA_ADDRESS_WIDTH-1:0] data_tail = (data_head == data_lptr)? data_uptr : data_head + 1'b1;
    wire flip = (rbuf_data_addr == data_uptr_reg);

    assign data_count_fin = (rbuf_data_addr == data_tail);

    always @(posedge clk) begin
        if (clr) begin
            rbuf_data_addr  <= {DATA_ADDRESS_WIDTH{1'b0}};
            data_uptr_reg   <= {DATA_ADDRESS_WIDTH{1'b0}};
            data_lptr_reg   <= {DATA_ADDRESS_WIDTH{1'b0}};
        end else begin
            case ({init, cnt})
                INIT_BUFFER : begin
                    rbuf_data_addr  <= data_head;
                    data_uptr_reg   <= data_uptr;
                    data_lptr_reg   <= data_lptr;
                end
                PROC_BUFFER : rbuf_data_addr <= (flip)? data_lptr_reg : rbuf_data_addr - 1'b1;
                SLEEP       : /* SLEEP =) */;
                default     : begin
`ifdef DEBUG
                    $display("Unable word! (Unit: %m; File: Controller.v; line: 117; time: %t)", $time);
                    $finish(2);
`endif
                end
            endcase
        end
    end

`ifdef DEBUG
    wire cmd = {init, cnt};
    reg [8*25-1:0] head_cmd_ascii;
    always @(cmd) begin : ascii_debug
        case (cmd)
            INIT_BUFFER    : head_cmd_ascii = "INIT_BUFFER";
            PROC_BUFFER    : head_cmd_ascii = "PROC_BUFFER";
            SLEEP          : head_cmd_ascii = "SLEEP";
            default        : head_cmd_ascii = "ERROR";
        endcase
    end
`endif

endmodule

module HeadRegs #(
    parameter DATA_OFFSET_WIDTH = 10,
    parameter VECTOR_INDEX_WIDTH = 4
) (
    input  wire                          clk,
    input  wire                          rst,
    input  wire                          init,
    input  wire                          head_inc,
    input  wire                          read_reg,
    input  wire [VECTOR_INDEX_WIDTH-1:0] index,
    input  wire [DATA_OFFSET_WIDTH-1:0]  length,
    output wire [DATA_OFFSET_WIDTH-1:0]  head_offset
);

    localparam [2:0] SLEEP          = 3'b000;
    localparam [2:0] LOAD_LENGTH    = 3'b100;
    localparam [2:0] HEAD_INCREMENT = 3'b010;
    localparam [2:0] READ_HEAD      = 3'b001;

    integer i;

    reg [DATA_OFFSET_WIDTH-1:0] reg_collection [0:2**VECTOR_INDEX_WIDTH-1];
    reg [DATA_OFFSET_WIDTH-1:0] length_reg;

    wire cell_reset;
    
    assign head_offset = (read_reg == 1'b1)? reg_collection[index] : {DATA_OFFSET_WIDTH{1'bz}};
    assign cmd = {init, head_inc, read_reg};
    assign cell_reset = (reg_collection[index] == length_reg);

    always @(posedge clk) begin : head_seq_process
        if (rst) begin
            for (i = 0; i < 2**VECTOR_INDEX_WIDTH; i = i + 1) begin
                reg_collection[i] <= {DATA_OFFSET_WIDTH{1'b0}};
            end
            length_reg <= {DATA_OFFSET_WIDTH{1'b0}};
        end else begin
            case (cmd)
                LOAD_LENGTH    : length_reg <= length;
                HEAD_INCREMENT : reg_collection[index] <= (cell_reset == 1'b1)? {DATA_OFFSET_WIDTH{1'b0}} : reg_collection[index] + 1'b1;
                SLEEP          : /* SLEEP =) */;
                default: begin : error_case
`ifdef DEBUG
                    $display("Unable word! (Unit: %m; File: Controller.v; line: 182; time: %t)", $time);
                    $finish(2);
`endif
                end
            endcase
        end
    end

`ifdef DEBUG
    reg [8*25-1:0] head_cmd_ascii;
    always @(cmd) begin : ascii_debug
        case (cmd)
            LOAD_LENGTH    : head_cmd_ascii = "LOAD_LENGTH";
            HEAD_INCREMENT : head_cmd_ascii = "HEAD_INCREMENT";
            READ_HEAD      : head_cmd_ascii = "READ_HEAD";
            SLEEP          : head_cmd_ascii = "SLEEP";
            default        : head_cmd_ascii = "ERROR";
        endcase
    end
`endif    
    
endmodule

module CoefAddrCounter #(
    parameter DATA_ADDRESS_WIDTH = 12,
    parameter DATA_OFFSET_WIDTH  = 10
) (
    input  wire                          clk,
    input  wire                          clr,
    input  wire                          load,
    input  wire                          cnt,
    input  wire [DATA_ADDRESS_WIDTH-1:0] coef_ptr,
    input  wire [DATA_OFFSET_WIDTH-1:0]  length,
    output wire                          coef_count_fin,
    output wire [DATA_ADDRESS_WIDTH-1:0] coef_addr
);

    localparam [1:0] SLEEP        = 2'b00;
    localparam [1:0] LOAD_COUNTER = 2'b10;
    localparam [1:0] COUNTING     = 2'b01;

    reg [DATA_OFFSET_WIDTH-1:0]  coef_offset_cnt;
    reg [DATA_ADDRESS_WIDTH-1:0] coef_ptr_reg;
    reg [DATA_OFFSET_WIDTH-1:0]  length_reg;

    assign coef_count_fin = (coef_offset_cnt == length_reg);
    assign coef_addr = (cnt == 1'b1)? coef_offset_cnt + coef_ptr_reg : {DATA_ADDRESS_WIDTH{1'bz}};

    always @(posedge clk) begin : coef_offset_counting
        if (clr) begin
            coef_offset_cnt <= {DATA_OFFSET_WIDTH{1'b0}};
            coef_ptr_reg    <= {DATA_ADDRESS_WIDTH{1'b0}};
            length_reg      <= {DATA_OFFSET_WIDTH{1'b0}};
        end else begin
            case ({load, cnt})
                LOAD_COUNTER : begin
                    coef_offset_cnt <= {DATA_OFFSET_WIDTH{1'b0}};
                    coef_ptr_reg    <= coef_ptr;
                    length_reg      <= length;
                end
                COUNTING     : coef_offset_cnt <= coef_offset_cnt + 1'b1;
                SLEEP        : /* SLEEP =) */;
                default      : begin : error_case
`ifdef DEBUG
                    $display("Unable word! (Unit: %m; File: Controller.v; line: 246; time: %t)", $time);
                    $finish(2);
`endif
                end
            endcase
        end
    end

`ifdef DEBUG
    reg [8*25-1:0] head_cmd_ascii;
    wire cmd = {load, cnt};
    always @(cmd) begin : ascii_debug
        case (cmd)
            LOAD_COUNTER : head_cmd_ascii = "LOAD_COUNTER";
            COUNTING     : head_cmd_ascii = "COUNTING";
            SLEEP        : head_cmd_ascii = "SLEEP";
            default      : head_cmd_ascii = "ERROR";
        endcase
    end
`endif

endmodule

module RegFileDriver #(
    parameter WIDTH = 3
) (
    input wire             clk, rst, en,
    input wire             res_err, rf_rw, get_reg,
    input wire [WIDTH-1:0] result_reg, error_reg,
    output reg             rw,
    output reg [WIDTH-1:0] ar1, ar2, ard
);

    always @(posedge clk) begin
        if (!rst) begin
            if (en) begin
                rw <= rf_rw;
                casez ({rf_rw, res_err})
                    2'b1z: begin
                        ar1 <= (get_reg)? result_reg : result_reg - 1'b0;
                        ar2 <= (get_reg)? {WIDTH{1'bz}} : error_reg;
                        ard <= {WIDTH{1'bz}};
                    end
                    2'b01: begin
                        ar1 <= {WIDTH{1'bz}};
                        ar2 <= {WIDTH{1'bz}};
                        ard <= result_reg;
                    end
                    2'b00: begin
                        ar1 <= {WIDTH{1'bz}};
                        ar2 <= {WIDTH{1'bz}};
                        ard <= error_reg;
                    end
                endcase
            end
        end else begin
            {ar1, ar2, ard, rw} <= `GND_BUS(3*WIDTH+1);
        end
    end

endmodule