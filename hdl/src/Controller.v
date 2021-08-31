`include "global_define.vh"

`timescale 1ns / 1ps
module top #(
    parameter VEC_ID_WIDTH = `VEC_ID_W,
    parameter REGFILE_ADDR_WIDTH = `REGFILE_ADDR_W,
    parameter ALLOC_LENGTH_WIDTH = `ALLOC_LEN_W,
    parameter DATA_ADDR_WIDTH = `DATA_ADDR_W,
    parameter INSTR_ADDR_WIDTH = $clog2(`PROG_SIZE)
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

    localparam INSTR_WIDTH = 1 + 1 + VEC_ID_WIDTH + 2*REGFILE_ADDR_WIDTH + ALLOC_LENGTH_WIDTH + 2*DATA_ADDR_WIDTH;

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

    wire readh_incrh, read_write,
         res_err, rf_rw, get_reg, new_in, new_out;

    OutLut u_OutLut(
        .fsm_state   ( ostate      ),
        .pc_clr      ( pc_clr      ),
        .pc_incr     ( pc_incr     ),
        .fetch       ( fetch       ),
        .readh_incrh ( readh_incrh ),
        .read_write  ( read_write  ),
        .res_err     ( res_err     ),
        .rf_rw       ( rf_rw       ),
        .get_reg     ( get_reg     ),
        .new_in      ( new_in      ),
        .new_out     ( new_out     )
    );

    wire [VEC_ID_WIDTH-1:0] vector_id;
    wire [REGFILE_ADDR_WIDTH-1:0] result_reg, error_reg;
    wire [ALLOC_LENGTH_WIDTH-1:0] vector_len;
    wire [DATA_ADDR_WIDTH-1:0] data_ptr, coef_ptr;

    InstrFetch#(
        .VIDWIDTH   ( VEC_ID_WIDTH ),
        .RFAWIDTH   ( REGFILE_ADDR_WIDTH ),
        .ALLWIDTH   ( ALLOC_LENGTH_WIDTH ),
        .DAWIDTH    ( DATA_ADDR_WIDTH )
     )u_InstrFetch(
        .clk        ( clk        ),
        .rst        ( rst        ),
        .fetch      ( fetch      ),
        .instr_word ( instr_word ),
        .lstg_f     ( last_stage ),
        .upse_f     ( last_vector),
        .vector_id  ( vector_id  ),
        .result_reg ( result_reg ),
        .error_reg  ( error_reg  ),
        .vector_len ( vector_len ),
        .data_ptr   ( data_ptr   ),
        .coef_ptr   ( coef_ptr   )
    );


    RAMDriver#(
        .DADDRESS_WIDTH ( DATA_ADDR_WIDTH ),
        .ALLENGTH_WIDTH ( ALLOC_LENGTH_WIDTH ),
        .VECINDEX_WIDTH ( VEC_ID_WIDTH )
     )u_RAMDriver(
        .clk            ( clk            ),
        .rst            ( rst            ),
        .en             ( en_devs        ),
        .readh_incrh    ( readh_incrh    ),
        .prog           ( prog           ),
        .read_write     ( read_write     ),
        .index          ( vector_id      ),
        .data_ptr       ( data_ptr       ),
        .coef_ptr       ( coef_ptr       ),
        .vector_len     ( vector_len     ),
        .en_ram_pa      ( en_ram_pa      ),
        .en_ram_pb      ( en_ram_pb      ),
        .vector_pass    ( vector_pass    ),
        .wr_ram_pa      ( wr_ram_pa      ),
        .wr_ram_pb      ( wr_ram_pb      ),
        .data_addr      ( data_addr      ),
        .coef_addr      ( coef_addr      )
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
    output reg readh_incrh, read_write,
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
        readh_incrh = (fsm_state == S4)||(fsm_state == S2);
        read_write  = (fsm_state == S3);
        res_err     = (fsm_state == S4);
        rf_rw       = (fsm_state == S4)||(fsm_state == S5)||(fsm_state == S7);
        get_reg     = (fsm_state == S2)||(fsm_state == S7);
        new_in      = (fsm_state == S7);
        new_out     = (fsm_state == S6);
    end
    
endmodule

module InstrFetch #(
    parameter VIDWIDTH = `VEC_ID_W,
    parameter RFAWIDTH = `REGFILE_ADDR_W,
    parameter ALLWIDTH = `ALLOC_LEN_W,
    parameter DAWIDTH  = `DATA_ADDR_W
)(
    input                       clk, rst, fetch,
    input      [INSTRWIDTH-1:0] instr_word,
    output reg                  lstg_f,
    output reg                  upse_f,
    output reg [VIDWIDTH-1:0]   vector_id,
    output reg [RFAWIDTH-1:0]   result_reg,
    output reg [RFAWIDTH-1:0]   error_reg,
    output reg [ALLWIDTH-1:0]   vector_len,
    output reg [DAWIDTH-1:0]    data_ptr,
    output reg [DAWIDTH-1:0]    coef_ptr
);
    localparam INSTRWIDTH = 1 + 1 + VIDWIDTH + 2*RFAWIDTH + ALLWIDTH + 2*DAWIDTH;

    always @(posedge clk) begin
        if (!rst) begin
            if (fetch) {lstg_f, upse_f, vector_id, result_reg, error_reg, vector_len, data_ptr, coef_ptr} <= instr_word;
        end else begin
            {lstg_f, upse_f, vector_id, result_reg, error_reg, vector_len, data_ptr, coef_ptr} <= `GND_BUS(`ALLOC_INSTR_W);
        end
    end
    
endmodule

//TODO: Add addr counter unit!!!
module RAMDriver #(
    parameter DADDRESS_WIDTH = `DATA_ADDR_W,
    parameter ALLENGTH_WIDTH = `ALLOC_LEN_W,
    parameter VECINDEX_WIDTH = `VEC_ID_W
)(
    input  wire                       clk, rst, en, readh_incrh,
    input  wire                       read_write,
    input  wire                       prog,
    input  wire [VECINDEX_WIDTH-1:0]  index,
    input  wire [DADDRESS_WIDTH-1:0]  data_ptr, coef_ptr,
    input  wire [ALLENGTH_WIDTH-1:0]  vector_len,
    output wire                       en_ram_pa, en_ram_pb,
    output wire                       vector_pass,
    output reg                        wr_ram_pa, wr_ram_pb,
    output wire  [DADDRESS_WIDTH-1:0] data_addr, coef_addr
);

    localparam READ  = 1'b0;
    localparam WRITE = 1'b1;
    
    wire [ALLENGTH_WIDTH-1:0] head_offset;

    Headers#(
        .AWIDTH      ( ALLENGTH_WIDTH ),
        .IWIDTH      ( VECINDEX_WIDTH )
    )u_Headers(
        .clk         ( clk         ),
        .rst         ( rst         ),
        .cmd         ( readh_incrh ),
        .index       ( index       ),
        .length      ( vector_len  ),
        .head_offset ( head_offset )
    );
    
    // Data head address
    wire [DADDRESS_WIDTH-1:0] data_head_addr = data_ptr + head_offset /*- 1'b1*/;
    wire [DADDRESS_WIDTH-1:0] rbuf_coef_addr, rbuf_data_addr;
    wire conv_pass;

    RingBuffer#(
        .DWIDTH         ( `DATA_ADDR_W ),
        .AWIDTH         ( `ALLOC_LEN_W )
    )u_RingBuffer(
        .clk            ( clk            ),
        .clr            ( rst            ),
        .cnt            ( read_write     ),
        .init           ( ~read_write    ),
        .coef_ptr       ( coef_ptr       ),
        .data_ptr       ( data_ptr       ),
        .length         ( vector_len     ),
        .data_head_addr ( data_head_addr ),
        .conv_pass      ( conv_pass      ),
        .rbuf_coef_addr ( rbuf_coef_addr ),
        .rbuf_data_addr ( rbuf_data_addr )
    );

    /*
        task init_check(input init, rw_flag);
            begin
                if ((init ^ ~rw_flag) === 1'b0) begin
                    $display("Init data address bus is zero before reading at %m in time %t failed!", $time);
                    $finish(2);
                end
            end
        endtask
    */
    assign vector_pass = ((conv_pass == 1'b1) && (read_write == 1'b1));
    assign data_addr = (read_write == 1'b1)? rbuf_data_addr : data_head_addr;
    assign coef_addr = (prog == 1'b1)? coef_ptr : rbuf_coef_addr;
    assign en_ram_pa = (read_write == READ) || ((read_write == WRITE) && (~prog));
    assign en_ram_pb = (read_write == READ) || ((read_write == WRITE) && ( prog));

endmodule

// TODO: make RingBuffer & Writer
module RingBuffer #(
    parameter DWIDTH = `DATA_ADDR_W,
    parameter AWIDTH = `ALLOC_LEN_W
) (
    input  wire              clk, clr, cnt, init,
    input  wire [DWIDTH-1:0] coef_ptr, data_ptr, data_head_addr,
    input  wire [AWIDTH-1:0] length,
    output wire              conv_pass,
    output reg  [DWIDTH-1:0] rbuf_coef_addr, rbuf_data_addr
);

    task assert(input tail_f, cend_f);
        begin
            if (~(tail_f ^ cend_f) === 1'b0) begin
                $display("Assertion at %m in time %t failed!", $time);
                $finish(2);
            end
        end
    endtask

    // Data massive end addres
    wire [DWIDTH-1:0] data_end_ptr = data_ptr + length - 1'b1;   
    // Coefficient massive end addres
    wire [DWIDTH-1:0] coef_end_ptr = coef_ptr + length - 1'b1;
    // Data tail addres flag
    wire tail_f = (rbuf_data_addr == (data_head_addr + 1));    
    // Coefficient massive end addres flag
    wire cend_f = (rbuf_coef_addr == coef_end_ptr);
    // Buffer data counter flip
    wire flip = (rbuf_data_addr == data_ptr);

    always @(posedge clk) begin : ring_buf_cnt
        if ((init == 1'b0) && (cnt == 1'b1)) begin
            rbuf_data_addr <= (flip)? data_end_ptr : rbuf_data_addr - 1'b1;
            rbuf_coef_addr <= rbuf_coef_addr + 1'b1;
            assert(tail_f, cend_f);
        end
        // else begin
        //     $display("Error! : Unable command (init and cnt are active high) in %m, line: %d", 402);
        //     $finish(2);
        // end
    end

    always @(posedge clk) begin : ring_buf_init
        if ((init == 1'b1) && (cnt == 1'b0)) begin
            rbuf_data_addr <= data_head_addr;
            rbuf_coef_addr <= coef_ptr;
        end
        // else begin
        //     $display("Error! : Unable command (init and cnt are active high) in %m, line: %d", 412);
        //     $finish(2);
        // end
    end

    always @(posedge clk) begin : ring_buf_clr
        if (clr == 1'b1) begin
            {rbuf_data_addr, rbuf_coef_addr} <= `GND_BUS(2*DWIDTH);
        end
    end

    assign conv_pass = tail_f;

endmodule

module Headers #(
    parameter AWIDTH = `ALLOC_LEN_W,
    parameter IWIDTH = `VEC_ID_W
) (
    input  wire              clk, rst, cmd,
    input  wire [IWIDTH-1:0] index,
    input  wire [AWIDTH-1:0] length,
    output wire [AWIDTH-1:0] head_offset
);
    integer i;
    reg [AWIDTH-1:0] mas [0:2**IWIDTH-1];
    wire cell_reset = (mas[index] == length);

    initial begin
        for (i = 0; i < 2**IWIDTH; i = i + 1) begin
            mas[index] <= `GND_BUS(AWIDTH);
        end
    end

    localparam [0:0] READ_HEAD  = 1'b1;
    localparam [0:0] WRITE_HEAD = 1'b0;

    always @(posedge clk) begin
        if (!rst) begin
            if (cmd == WRITE_HEAD) begin
                mas[index] <= (cell_reset)? {AWIDTH{1'b0}} : mas[index] + 1'b1;
            end
            // case (cmd)
            //     READ_HEAD  : head_offset <= mas[index];
            //     WRITE_HEAD : 
            // endcase
        end else begin
            for (i = 0; i < 2**IWIDTH; i = i + 1) begin
                mas[index] <= `GND_BUS(AWIDTH);
            end
        end
    end

    assign head_offset = (cmd == READ_HEAD)? mas[index] : `GND_BUS(AWIDTH);

`ifdef DEBUG
    reg [80-1:0] header_cmd_ascii;
    always @(cmd) begin
        case (cmd)
            READ_HEAD  : header_cmd_ascii = "READ_HEAD";
            WRITE_HEAD : header_cmd_ascii = "WRITE_HEAD";
        endcase
    end
`endif

endmodule

module RegFileDriver #(
    parameter WIDTH = `REGFILE_ADDR_W
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
/*
module CPUProgInterface #(
    parameter BUS_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    // ! May be use axi-stream

);
    
endmodule
*/