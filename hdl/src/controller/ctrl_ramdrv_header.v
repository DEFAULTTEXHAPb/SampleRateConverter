`include "glb_macros.vh"

module ctrl_ramdrv_header #(
    parameter OFFSET_WIDTH = 10,
    parameter INDEX_WIDTH  = 4
) (
    input  wire                    clk,
    input  wire                    clr,
    input  wire                    init,
    input  wire                    head_read,
    input  wire                    head_incr,
    input  wire [ INDEX_WIDTH-1:0] index,
    input  wire [OFFSET_WIDTH-1:0] length,
    output wire [OFFSET_WIDTH-1:0] head_offset
);

  reg [OFFSET_WIDTH-1:0] mas [0:2**INDEX_WIDTH-1];
  reg [OFFSET_WIDTH-1:0] length_reg;

  wire cell_reset;

  assign head_offset = (head_read == 1'b1) ? mas[index] : {OFFSET_WIDTH{1'bz}};
  assign cell_reset  = (mas[index] == length_reg);

  integer i;

  initial begin
    for (i = 0; i < 2 ** INDEX_WIDTH; i = i + 1) begin
      mas[i] = {OFFSET_WIDTH{1'b0}};
    end
    length_reg = {OFFSET_WIDTH{1'b0}};
  end

  always @(posedge clk) begin : register_mod_proc
    if (clr == 1'b1) begin
      for (i = 0; i < 2 ** INDEX_WIDTH; i = i + 1) begin
        mas[i] <= {OFFSET_WIDTH{1'b0}};
      end
      length_reg <= {OFFSET_WIDTH{1'b0}};
    end else if (init == 1'b1) begin
      length_reg <= length;
    end else if (head_incr == 1'b1) begin
      mas[index] <= (cell_reset == 1'b1) ? {OFFSET_WIDTH{1'b0}} : mas[index] + 1'b1;
    end
  end

`ifdef DEBUG

  localparam [2:0] SLEEP = 3'b000;
  localparam [2:0] LOAD_LENGTH = 3'b100;
  localparam [2:0] HEAD_INCREMENT = 3'b010;
  localparam [2:0] READ_HEAD = 3'b001;

  wire [2:0] cmd;
  reg [8*25-1:0] head_cmd_ascii;
  assign cmd = {init, head_incr, head_read};

  initial begin
    head_cmd_ascii = {(8 * 25) {1'b0}};
  end

  always @(cmd) begin : ascii_debug
    case (cmd)
      LOAD_LENGTH:    head_cmd_ascii = "LOAD_LENGTH";
      HEAD_INCREMENT: head_cmd_ascii = "HEAD_INCREMENT";
      READ_HEAD:      head_cmd_ascii = "READ_HEAD";
      SLEEP:          head_cmd_ascii = "SLEEP";
      default: begin
        head_cmd_ascii = "WARNING";
        $display(
            "WARN!!!: Incorrect module driving: init, head_read and head_incr or pair of them are active high in %m (time: %t)",
            $time);
        $display("\tProcessing mess!");
      end
    endcase
  end
`endif

endmodule
