//TODO: добавить промежуточные регистры для избежания ассерта в 
`include "glb_macros.vh"


module ctrl_ramdrv_ringbuf #(
    parameter DATA_ADDRESS_WIDTH = 12,
    parameter DATA_OFFSET_WIDTH  = 10
) (
    input  wire                          clk,
    input  wire                          clr,
    input  wire                          cnt,
    input  wire                          init,
    input  wire [DATA_ADDRESS_WIDTH-1:0] data_uptr,
    input  wire [DATA_ADDRESS_WIDTH-1:0] data_lptr,
    input  wire [ DATA_OFFSET_WIDTH-1:0] head_offset,
    output wire                          data_count_fin,
    output wire [DATA_ADDRESS_WIDTH-1:0] data_addr
);

  localparam [1:0] INIT_BUFFER = 2'b10;
  localparam [1:0] PROC_BUFFER = 2'b01;
  localparam [1:0] SLEEP = 2'b00;

  reg  [DATA_ADDRESS_WIDTH-1:0] rbuf_data_addr;
  reg  [DATA_ADDRESS_WIDTH-1:0] data_uptr_reg;
  reg  [DATA_ADDRESS_WIDTH-1:0] data_lptr_reg;

  wire [DATA_ADDRESS_WIDTH-1:0] data_head;
  assign data_head = data_uptr + `WORD_EXT(DATA_OFFSET_WIDTH, DATA_ADDRESS_WIDTH, head_offset);

  wire [DATA_ADDRESS_WIDTH-1:0] data_tail = (data_head == data_lptr)? data_uptr : data_head + 1'b1;
  wire flip = (rbuf_data_addr == data_uptr_reg);

  assign data_count_fin = (rbuf_data_addr == data_tail);

  always @(posedge clk) begin
    if (clr) begin
      rbuf_data_addr <= {DATA_ADDRESS_WIDTH{1'b0}};
      data_uptr_reg  <= {DATA_ADDRESS_WIDTH{1'b0}};
      data_lptr_reg  <= {DATA_ADDRESS_WIDTH{1'b0}};
    end else begin
      case ({
        init, cnt
      })
        INIT_BUFFER: begin
          rbuf_data_addr <= data_head;
          data_uptr_reg  <= data_uptr;
          data_lptr_reg  <= data_lptr;
        end
        PROC_BUFFER:           rbuf_data_addr <= (flip) ? data_lptr_reg : rbuf_data_addr - 1'b1;
        SLEEP:  /* SLEEP =) */ ;
        default: begin
`ifdef DEBUG
          $display("Unable word! (Unit: %m; File: Controller.v; line: 117; time: %t)", $time);
          $finish(2);
`endif
        end
      endcase
    end
  end

`ifdef DEBUG
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
      default:     head_cmd_ascii = "ERROR";
    endcase
  end
`endif

endmodule
