//TODO: добавить порт - флаг окончания счета в кольцевом буффере
module ctrl_ramdrv_coefcnt #(
    parameter DATA_ADDRESS_WIDTH = 12
) (
    input  logic                          clk,
    input  logic                          clr,
    input  logic                          load,
    input  logic                          cnt,
    input  logic [DATA_ADDRESS_WIDTH-1:0] coef_ptr,
    output logic [DATA_ADDRESS_WIDTH-1:0] coef_addr
);

  localparam [1:0] SLEEP = 2'b00;
  localparam [1:0] LOAD_COUNTER = 2'b10;
  localparam [1:0] COUNTING = 2'b01;

  logic [DATA_ADDRESS_WIDTH-1:0] coef_cnt;

  initial begin
    coef_cnt = {DATA_ADDRESS_WIDTH{1'b0}};
  end

  assign coef_addr = (cnt == 1'b1) ? coef_cnt : {DATA_ADDRESS_WIDTH{1'bz}};

  always @(posedge clk) begin : coef_offset_counting
    if (clr) begin
      coef_cnt <= {DATA_ADDRESS_WIDTH{1'b0}};
    end else begin
      case ({
        load, cnt
      })
        LOAD_COUNTER: begin
          coef_cnt <= coef_ptr;
        end
        COUNTING:              coef_cnt <= coef_cnt + 1'b1;
        SLEEP:  /* SLEEP =) */ ;
        default: begin : error_case
`ifdef DEBUG
          $display("Err:(Unit: %m; File: %s; line: %d; time: %t\n)", `__FILE__, `__LINE__, $time);
          $finish(2);
`endif
        end
      endcase
    end
  end

`ifdef DEBUG
  logic [8*25-1:0] head_cmd_ascii;
  logic [1:0] cmd = {load, cnt};

  initial begin
    head_cmd_ascii = {(8 * 25) {1'b0}};
  end

  always @(cmd) begin : ascii_debug
    case (cmd)
      LOAD_COUNTER: head_cmd_ascii = "LOAD_COUNTER";
      COUNTING:     head_cmd_ascii = "COUNTING";
      SLEEP:        head_cmd_ascii = "SLEEP";
      default:      head_cmd_ascii = "ERROR";
    endcase
  end
`endif

endmodule
