//TODO: добавить промежуточные регистры для избежания ассерта в хедаре
`include "ctrl.svh"


module ctrl_ramdrv_ringbuf #(
    parameter DATA_ADDRESS_WIDTH = ctrl::DATA_RAM_ADDRESS_WIDTH,
    parameter DATA_OFFSET_WIDTH  = ctrl::DATA_OFFSET_WIDTH
) (
    input  wire logic               clk,
    input  wire logic               clr,
    input  wire logic               cnt,
    input  wire logic               init,
    input  wire ctrl::data_addr_t   data_uptr,
    input  wire ctrl::data_addr_t   data_lptr,
    input  wire ctrl::data_offset_t head_offset,
    output wire logic               finish_f,
    output wire ctrl::data_addr_t   data_addr
);

  typedef enum logic [1:0] {
    INIT_BUFFER = 2'b10,
    PROC_BUFFER = 2'b01,
    SLEEP       = 2'b00
  } cmd_e;

  ctrl::data_addr_t rbuf_data_addr;
  ctrl::data_addr_t data_uptr_reg;
  ctrl::data_addr_t data_lptr_reg;

  ctrl::data_addr_t data_head = data_uptr + {'0, head_offset};
  ctrl::data_addr_t data_tail = (data_head == data_lptr) ? data_uptr : data_head + 1'b1;
  logic flip = (rbuf_data_addr == data_uptr_reg);

  cmd_e cmd = {init, cnt};

  assign finish_f  = (rbuf_data_addr == data_tail);
  assign data_addr = rbuf_data_addr;

  always_ff @(posedge clk) begin
    if (clr) begin
      rbuf_data_addr <= '0;
      data_uptr_reg  <= '0;
      data_lptr_reg  <= '0;
    end else begin
      case (cmd)
        INIT_BUFFER: begin
          rbuf_data_addr <= data_head;
          data_uptr_reg  <= data_uptr;
          data_lptr_reg  <= data_lptr;
        end
        PROC_BUFFER:           rbuf_data_addr <= (flip) ? data_lptr_reg : rbuf_data_addr - 1'b1;
        SLEEP:  /* SLEEP =) */ ;
        default:               ;
      endcase
    end
  end

`ifdef DEBUG

  logic [8*25-1:0] head_cmd_ascii;

  initial begin
    head_cmd_ascii = {(8 * 25) {1'b0}};
  end

  always @(cmd) begin : ascii_debug
    case (cmd)
      INIT_BUFFER: head_cmd_ascii = "INIT_BUFFER";
      PROC_BUFFER: head_cmd_ascii = "PROC_BUFFER";
      SLEEP:       head_cmd_ascii = "SLEEP";
      default: begin
        head_cmd_ascii = "ERROR";
        $display("Err:(Unit: %m; File: %s; line: %d; time: %t\n)", `__FILE__, `__LINE__, $time);
        $finish(2);
      end
    endcase
  end
`endif

endmodule : ctrl_ramdrv_ringbuf
