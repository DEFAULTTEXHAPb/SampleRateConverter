//TODO: добавить промежуточные регистры для избежания ассерта в 
`include "glb_macros.vh"

module ctrl_ramdrv_ringbuf #(
    parameter integer ADDR_WIDTH = 12,
    parameter integer OFST_WIDTH = 10
) (
    input  wire                  clk,
    input  wire                  clr,
    input  wire                  cnt,
    input  wire                  init,
    input  wire [ADDR_WIDTH-1:0] data_uptr,
    input  wire [ADDR_WIDTH-1:0] data_lptr,
    input  wire [OFST_WIDTH-1:0] head_offset,
    output wire                  data_count_fin,
    output wire [ADDR_WIDTH-1:0] rbuf_data_addr
);

  reg  [ADDR_WIDTH-1:0] q_rbuf_data_addr = {ADDR_WIDTH{1'b0}};
  reg  [ADDR_WIDTH-1:0] q_data_uptr      = {ADDR_WIDTH{1'b0}};
  reg  [ADDR_WIDTH-1:0] q_data_lptr      = {ADDR_WIDTH{1'b0}};
  reg  [OFST_WIDTH-1:0] q_head_offset    = {OFST_WIDTH{1'b0}};
  reg  [ADDR_WIDTH-1:0] q_data_head      = {ADDR_WIDTH{1'b0}};

  wire [ADDR_WIDTH-1:0] d_data_head;
  wire [ADDR_WIDTH-1:0] data_tail;
  wire flip;

  assign data_count_fin = (q_rbuf_data_addr == data_tail);
  assign d_data_head = q_data_uptr + `WORD_EXT(OFST_WIDTH, ADDR_WIDTH, q_head_offset);
  assign data_tail = (q_data_head == q_data_lptr)? q_data_uptr : q_data_head + 1'b1;
  assign flip = (q_rbuf_data_addr == q_data_uptr);
  assign rbuf_data_addr = q_rbuf_data_addr;

  always @(posedge clk) begin : trig_proc
    if (clr == 1'b1) begin
      q_head_offset    <= {OFST_WIDTH{1'b0}};
      q_data_uptr      <= {ADDR_WIDTH{1'b0}};
      q_data_lptr      <= {ADDR_WIDTH{1'b0}};
    end else if (init == 1'b1) begin
      q_head_offset    <= head_offset;
      q_data_uptr      <= data_uptr;
      q_data_lptr      <= data_lptr;
    end
  end

  always @(posedge clk) begin : rbuf_count_proc
    if (clr == 1'b1) begin
      q_rbuf_data_addr <= {ADDR_WIDTH{1'b0}};
      q_data_head      <= {ADDR_WIDTH{1'b0}};
    end else if (init == 1'b1) begin
      q_data_head      <= d_data_head;
      q_rbuf_data_addr <= q_data_head;
    end else if (cnt == 1'b1) begin
      q_rbuf_data_addr <= (flip == 1'b0)? q_rbuf_data_addr - 1'b1 : q_data_lptr;
    end
  end

`ifdef DEBUG

  localparam [1:0] INIT_BUFFER = 2'b10;
  localparam [1:0] PROC_BUFFER = 2'b01;
  localparam [1:0] SLEEP = 2'b00;

  wire [1:0] cmd = {init, cnt};
  reg [8*25-1:0] head_cmd_ascii;

  initial begin
    head_cmd_ascii = {(8 * 25) {1'b0}};
  end

  always @(cmd) begin : ascii_debug
    case (cmd)
      INIT_BUFFER: head_cmd_ascii = "INIT_BUFFER";
      PROC_BUFFER: head_cmd_ascii = "PROC_BUFFER";
      SLEEP:       head_cmd_ascii = "SLEEP";
      default:     begin
        head_cmd_ascii = "WARNING";
        $display("WARN!!!: Incorrect module driving: both init and cnt are active high in %m (time: %t)", $time);
        $display("\tRing buffer initialization processing");
      end
    endcase
  end
`endif

endmodule
