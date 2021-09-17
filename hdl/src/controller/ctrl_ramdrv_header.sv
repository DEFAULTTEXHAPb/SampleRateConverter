module ctrl_ramdrv_header #(
    parameter DATA_OFFSET_WIDTH  = 10,
    parameter VECTOR_INDEX_WIDTH = 4
) (
    input  logic                          clk,
    input  logic                          rst,
    input  logic                          init,
    input  logic                          head_inc,
    input  logic                          read_logic,
    input  logic [VECTOR_INDEX_WIDTH-1:0] index,
    input  logic [ DATA_OFFSET_WIDTH-1:0] length,
    output logic [ DATA_OFFSET_WIDTH-1:0] head_offset
);

  localparam [2:0] SLEEP = 3'b000;
  localparam [2:0] LOAD_LENGTH = 3'b100;
  localparam [2:0] HEAD_INCREMENT = 3'b010;
  localparam [2:0] READ_HEAD = 3'b001;

  integer i;

  logic [DATA_OFFSET_WIDTH-1:0] mreg[0:2**VECTOR_INDEX_WIDTH-1];
  logic [DATA_OFFSET_WIDTH-1:0] qlength;

  logic cell_reset;
  logic [2:0] cmd;

  assign head_offset = (read_logic == 1'b1) ? mreg[index] : {DATA_OFFSET_WIDTH{1'bz}};
  assign cmd = {init, head_inc, read_logic};
  assign cell_reset = (mreg[index] == qlength);

  initial begin
    for (i = 0; i < 2 ** VECTOR_INDEX_WIDTH; i = i + 1) begin
      mreg[i] = {DATA_OFFSET_WIDTH{1'b0}};
    end
    qlength = {DATA_OFFSET_WIDTH{1'b0}};
  end

  always @(posedge clk) begin : head_seq_process
    if (rst) begin
      for (i = 0; i < 2 ** VECTOR_INDEX_WIDTH; i = i + 1) begin
        mreg[i] <= {DATA_OFFSET_WIDTH{1'b0}};
      end
      qlength <= {DATA_OFFSET_WIDTH{1'b0}};
    end else begin
      case (cmd)
        LOAD_LENGTH: qlength <= length;
        HEAD_INCREMENT:
        mreg[index] <= (cell_reset == 1'b1)? {DATA_OFFSET_WIDTH{1'b0}} : mreg[index] + 1'b1;
        SLEEP:  /* SLEEP =) */;
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
  logic [8*25-1:0] head_cmd_ascii;

  initial begin
    head_cmd_ascii = {(8 * 25) {1'b0}};
  end

  always @(cmd) begin : ascii_debug
    case (cmd)
      LOAD_LENGTH:    head_cmd_ascii = "LOAD_LENGTH";
      HEAD_INCREMENT: head_cmd_ascii = "HEAD_INCREMENT";
      READ_HEAD:      head_cmd_ascii = "READ_HEAD";
      SLEEP:          head_cmd_ascii = "SLEEP";
      default:        head_cmd_ascii = "ERROR";
    endcase
  end
`endif

endmodule
