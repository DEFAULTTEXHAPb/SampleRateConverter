//TODO: добавить порт - флаг окончания счета в кольцевом буффере
module ctrl_ramdrv_coefcnt #(
    parameter DATA_ADDRESS_WIDTH = 12
) (
    input  wire                          clk,
    input  wire                          clr,
    input  wire                          load,
    input  wire                          cnt,
    input  wire [DATA_ADDRESS_WIDTH-1:0] coef_ptr,
    output wire [DATA_ADDRESS_WIDTH-1:0] coef_addr
);

    localparam [1:0] SLEEP        = 2'b00;
    localparam [1:0] LOAD_COUNTER = 2'b10;
    localparam [1:0] COUNTING     = 2'b01;

    reg [DATA_ADDRESS_WIDTH-1:0] coef_cnt;

    initial begin
        coef_cnt        = {DATA_ADDRESS_WIDTH{1'b0}};        
    end

    assign coef_addr = (cnt == 1'b1)? coef_cnt : {DATA_ADDRESS_WIDTH{1'bz}};

    always @(posedge clk) begin : coef_offset_counting
        if (clr) begin
            coef_cnt     <= {DATA_ADDRESS_WIDTH{1'b0}};
        end else begin
            case ({load, cnt})
                LOAD_COUNTER : begin
                    coef_cnt <= coef_ptr;
                end
                COUNTING     : coef_cnt <= coef_cnt + 1'b1;
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
    wire [1:0] cmd = {load, cnt};

    initial begin
        head_cmd_ascii  = {(8*25){1'b0}};
    end

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