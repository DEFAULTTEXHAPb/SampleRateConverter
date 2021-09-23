//TODO: добавить порт - флаг окончания счета в кольцевом буффере
`include "glb_macros.vh"

module ctrl_ramdrv_coefcnt #(
    parameter integer ADDR_WIDTH = 12
) (
    input  wire                  clk,
    input  wire                  clr,
    input  wire                  load,
    input  wire                  cnt,
    input  wire [ADDR_WIDTH-1:0] coef_ptr,
    output wire [ADDR_WIDTH-1:0] coef_addr
);

    reg [ADDR_WIDTH-1:0] coef_cnt = {ADDR_WIDTH{1'b0}};

    assign coef_addr = coef_cnt;

    always @(posedge clk) begin : coef_offset_counting
      if (clr == 1'b1) begin
        coef_cnt <= {ADDR_WIDTH{1'b0}};
      end else if (load == 1'b1) begin
        coef_cnt <= coef_ptr;
      end if (cnt == 1'b1) begin
        coef_cnt <= coef_cnt + 1'b1;
      end
    end

`ifdef DEBUG
    reg [8*25-1:0] head_cmd_ascii;
    wire [1:0] cmd = {load, cnt};

    localparam [1:0] SLEEP        = 2'b00;
    localparam [1:0] LOAD_COUNTER = 2'b10;
    localparam [1:0] COUNTING     = 2'b01;

    initial begin
        head_cmd_ascii  = {(8*25){1'b0}};
    end

    always @(cmd) begin : ascii_debug
        case (cmd)
            LOAD_COUNTER : head_cmd_ascii = "LOAD_COUNTER";
            COUNTING     : head_cmd_ascii = "COUNTING";
            SLEEP        : head_cmd_ascii = "SLEEP";
            default      : begin
              head_cmd_ascii = "WARNING";
              $display("WARN!!!: Incorrect module driving: both load and cnt are active high in %m (time: %t)", $time);
              $display("\tCoefficient address counter loading processing");
            end
        endcase
    end
`endif

endmodule