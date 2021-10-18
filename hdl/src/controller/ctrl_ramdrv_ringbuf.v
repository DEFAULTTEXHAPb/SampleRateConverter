//! @title Ring buffer address counter
//! @brief This module switches sample data address
//! in ring buffer order


`include "glb_macros.vh"

module ctrl_ramdrv_ringbuf #(
    parameter integer ADDR_WIDTH = 12
) (
    input  wire                  clk,            //! __Clock__
    input  wire                  rst_n,          //! __Reset__
    input  wire                  cnt,            //! Ring buffer address count flag
    input  wire                  init,           //! Ring buffer initialization flag
    input  wire [ADDR_WIDTH-1:0] data_bptr,      //! Sample segment base pointer
    input  wire [ADDR_WIDTH-1:0] data_lptr,      //! Sample segment lower pointer
    input  wire [ADDR_WIDTH-1:0] data_hptr,      //! Ring buffer head address in sample segment
    output wire                  data_count_fin, //! Ring buffer address count finish flag
    output wire [ADDR_WIDTH-1:0] rbuf_data_addr  //! Ring buffer counter address
);

  //! D-Trigger output of `rbuf_data_addr` port
  reg  [ADDR_WIDTH-1:0] q_rbuf_data_addr = {ADDR_WIDTH{1'b0}};
  //! D-Trigger output of `data_bptr` port
  reg  [ADDR_WIDTH-1:0] q_data_bptr      = {ADDR_WIDTH{1'b0}};
  //! D-Trigger output of `data_lptr` port
  reg  [ADDR_WIDTH-1:0] q_data_lptr      = {ADDR_WIDTH{1'b0}};
  //! D-Trigger output of `data_hptr` port
  reg  [ADDR_WIDTH-1:0] q_data_hptr      = {ADDR_WIDTH{1'b0}};
  //! First cell address flag register
  reg                   first_register = 1'b1;


  //! Ring buffer tail pointer
  wire [ADDR_WIDTH-1:0] data_tail;
  //! Ring buffer counter flip flag
  wire flip;

  assign data_count_fin = (q_rbuf_data_addr == data_tail);
  assign data_tail = (q_data_hptr == q_data_lptr)? q_data_bptr : q_data_hptr + 1'b1;
  assign flip = (q_rbuf_data_addr == q_data_bptr);
  assign rbuf_data_addr = q_rbuf_data_addr;

  //! Input addreses initial value set
  always @(negedge clk) begin : trig_proc
    if (rst_n == 1'b0) begin
      q_data_hptr      <= {ADDR_WIDTH{1'b0}};
      q_data_bptr      <= {ADDR_WIDTH{1'b0}};
      q_data_lptr      <= {ADDR_WIDTH{1'b0}};
    end else if ({init, cnt} == 2'b10) begin
      q_data_hptr      <= data_hptr;
      q_data_bptr      <= data_bptr;
      q_data_lptr      <= data_lptr;
    end
  end

  //! Ring buffer counting process
  always @(negedge clk) begin : rbuf_count_proc
    if (rst_n == 1'b0) begin
      q_rbuf_data_addr <= {ADDR_WIDTH{1'b0}};
      first_register   <= 1'b1;
    end else if ({init, cnt} == 2'b10) begin
      q_rbuf_data_addr <= data_hptr;
      first_register   <= 1'b1;
    end else if ({init, cnt} == 2'b01) begin
      if (first_register == 1'b1) begin
        q_rbuf_data_addr <= data_hptr;
        first_register   <= 1'b0;
      end else begin
        q_rbuf_data_addr <= (flip == 1'b0)? q_rbuf_data_addr - 1'b1 : q_data_lptr;
      end      
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
    $timeformat(-9, 2, "ms", 10);
  end

  always @(cmd) begin : ascii_debug
    case (cmd)
      INIT_BUFFER: head_cmd_ascii = "INIT_BUFFER";
      PROC_BUFFER: head_cmd_ascii = "PROC_BUFFER";
      SLEEP:       head_cmd_ascii = "SLEEP";
      default:     begin
        head_cmd_ascii = "WARNING";
        $display("WARN!!!: Incorrect module driving: both init and cnt are active high in %m (time: %t)", $realtime);
        $display("\tRing buffer initialization processing");
      end
    endcase
  end
`endif

endmodule
