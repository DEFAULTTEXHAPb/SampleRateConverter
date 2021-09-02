module RAMDriver #(
    parameter DATA_ADDRESS_WIDTH = 12,
    parameter DATA_OFFSET_WIDTH = 10,
    parameter VECTOR_INDEX_WIDTH = 5
)(
    input  wire                          clk,
    input  wire                          rst,
    input  wire                          rbuf_on,
    input  wire                          h_init,
    input  wire                          a_init,
    input  wire                          cnt,
    input  wire [DATA_ADDRESS_WIDTH-1:0] data_uptr,
    input  wire [DATA_ADDRESS_WIDTH-1:0] data_lptr,
    input  wire [DATA_ADDRESS_WIDTH-1:0] coef_ptr,
    input  wire [VECTOR_INDEX_WIDTH-1:0] vector_id,
    output wire                          conv_pass,
    output wire [DATA_ADDRESS_WIDTH-1:0] data_addr,
    output wire [DATA_ADDRESS_WIDTH-1:0] coef_addr
);

    DataRingBuffer#(
        .DATA_ADDRESS_WIDTH ( DATA_ADDRESS_WIDTH ),
        .DATA_OFFSET_WIDTH  ( DATA_OFFSET_WIDTH )
    )u_DataRingBuffer(
        .clk                ( clk                ),
        .clr                ( rst                ),
        .cnt                ( cnt                ),
        .init               ( a_init             ),
        .data_uptr          ( data_uptr          ),
        .data_lptr          ( data_lptr          ),
        .head_offset        ( head_offset        ),
        .data_count_fin     ( data_count_fin     ),
        .data_addr          ( data_addr          )
    );

    HeadRegs#(
        .DATA_OFFSET_WIDTH ( DATA_OFFSET_WIDTH ),
        .VECTOR_INDEX_WIDTH ( VECTOR_INDEX_WIDTH )
    )u_HeadRegs(
        .clk               ( clk               ),
        .rst               ( rst               ),
        .init              ( h_init            ),
        .head_inc          ( head_inc          ),
        .read_reg          ( read_reg          ),
        .index             ( index             ),
        .length            ( length            ),
        .head_offset       ( head_offset       )
    );

    CoefAddrCounter#(
        .DATA_ADDRESS_WIDTH ( DATA_ADDRESS_WIDTH ),
        .DATA_OFFSET_WIDTH  ( DATA_OFFSET_WIDTH )
    )u_CoefAddrCounter(
        .clk                ( clk                ),
        .clr                ( rst                ),
        .load               ( a_init             ),
        .cnt                ( cnt                ),
        .coef_ptr           ( coef_ptr           ),
        .length             ( length             ),
        .coef_count_fin     ( coef_count_fin     ),
        .coef_addr          ( coef_addr          )
    );

endmodule

module DataRingBuffer #(
    parameter DATA_ADDRESS_WIDTH = 12,
    parameter DATA_OFFSET_WIDTH = 10
)(
    input  wire                          clk,
    input  wire                          clr,
    input  wire                          cnt,
    input  wire                          init,
    input  wire [DATA_ADDRESS_WIDTH-1:0] data_uptr,
    input  wire [DATA_ADDRESS_WIDTH-1:0] data_lptr,
    input  wire [DATA_OFFSET_WIDTH-1:0]  head_offset,
    output wire                          data_count_fin,
    output wire [DATA_ADDRESS_WIDTH-1:0] data_addr
);

    localparam [1:0] INIT_BUFFER = 2'b10;
    localparam [1:0] PROC_BUFFER = 2'b01;
    localparam [1:0] SLEEP       = 2'b00;

    reg  [DATA_ADDRESS_WIDTH-1:0] rbuf_data_addr;
    reg  [DATA_ADDRESS_WIDTH-1:0] data_uptr_reg;
    reg  [DATA_ADDRESS_WIDTH-1:0] data_lptr_reg;

    wire [DATA_ADDRESS_WIDTH-1:0] data_head = data_uptr + head_offset;
    wire [DATA_ADDRESS_WIDTH-1:0] data_tail = (data_head == data_lptr)? data_uptr : data_head + 1'b1;
    wire flip = (rbuf_data_addr == data_uptr_reg);

    assign data_count_fin = (rbuf_data_addr == data_tail);

    always @(posedge clk) begin
        if (clr) begin
            rbuf_data_addr  <= {DATA_ADDRESS_WIDTH{1'b0}};
            data_uptr_reg   <= {DATA_ADDRESS_WIDTH{1'b0}};
            data_lptr_reg   <= {DATA_ADDRESS_WIDTH{1'b0}};
        end else begin
            case ({init, cnt})
                INIT_BUFFER : begin
                    rbuf_data_addr  <= data_head;
                    data_uptr_reg   <= data_uptr;
                    data_lptr_reg   <= data_lptr;
                end
                PROC_BUFFER : rbuf_data_addr <= (flip)? data_lptr_reg : rbuf_data_addr - 1'b1;
                SLEEP       : /* SLEEP =) */;
                default     : begin
`ifdef DEBUG
                    $display("Unable word! (Unit: %m; File: Controller.v; line: 117; time: %t)", $time);
                    $finish(2);
`endif
                end
            endcase
        end
    end

`ifdef DEBUG
    reg [8*25-1:0] head_cmd_ascii;
    always @(cmd) begin : ascii_debug
        case (cmd)
            INIT_BUFFER    : head_cmd_ascii = "INIT_BUFFER";
            PROC_BUFFER    : head_cmd_ascii = "PROC_BUFFER";
            SLEEP          : head_cmd_ascii = "SLEEP";
            default        : head_cmd_ascii = "ERROR";
        endcase
    end
`endif

endmodule

module HeadRegs #(
    parameter DATA_OFFSET_WIDTH = 10,
    parameter VECTOR_INDEX_WIDTH = 4
) (
    input  wire                          clk,
    input  wire                          rst,
    input  wire                          init,
    input  wire                          head_inc,
    input  wire                          read_reg,
    input  wire [VECTOR_INDEX_WIDTH-1:0] index,
    input  wire [VECTOR_INDEX_WIDTH-1:0] length,
    output wire [DATA_OFFSET_WIDTH-1:0]  head_offset
);

    localparam [2:0] SLEEP          = 3'b000;
    localparam [2:0] LOAD_LENGTH    = 3'b100;
    localparam [2:0] HEAD_INCREMENT = 3'b010;
    localparam [2:0] READ_HEAD      = 3'b001;

    integer i;

    reg [DATA_OFFSET_WIDTH-1:0] reg_collection [0:2**VECTOR_INDEX_WIDTH-1];
    reg [DATA_OFFSET_WIDTH-1:0] length_reg;

    wire cell_reset;
    
    assign head_offset = (read_reg == 1'b1)? reg_collection[index] : {DATA_OFFSET_WIDTH{1'bz}};
    assign cmd = {init, head_inc, read_reg};
    assign cell_reset = (mas[index] == length_reg);

    always @(posedge clk) begin : head_seq_process
        if (rst) begin
            for (i = 0; i < 2**VECTOR_INDEX_WIDTH; i = i + 1) begin
                reg_collection[i] <= {DATA_OFFSET_WIDTH{1'b0}};
            end
            length_reg <= {DATA_OFFSET_WIDTH{1'b0}};
        end else begin
            case (cmd)
                LOAD_LENGTH    : length_reg <= length;
                HEAD_INCREMENT : mas[index] <= (cell_reset)? {AWIDTH{1'b0}} : mas[index] + 1'b1;
                SLEEP          : /* SLEEP =) */;
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
    reg [8*25-1:0] head_cmd_ascii;
    always @(cmd) begin : ascii_debug
        case (cmd)
            LOAD_LENGTH    : head_cmd_ascii = "LOAD_LENGTH";
            HEAD_INCREMENT : head_cmd_ascii = "HEAD_INCREMENT";
            READ_HEAD      : head_cmd_ascii = "READ_HEAD";
            SLEEP          : head_cmd_ascii = "SLEEP";
            default        : head_cmd_ascii = "ERROR";
        endcase
    end
`endif    
    
endmodule

module CoefAddrCounter #(
    parameter DATA_ADDRESS_WIDTH = 12,
    parameter DATA_OFFSET_WIDTH  = 10
) (
    input  wire                          clk,
    input  wire                          clr,
    input  wire                          load,
    input  wire                          cnt,
    input  wire [DATA_ADDRESS_WIDTH-1:0] coef_ptr,
    input  wire [DATA_OFFSET_WIDTH-1:0]  length,
    output wire                          coef_count_fin,
    output wire [DATA_ADDRESS_WIDTH-1:0] coef_addr
);

    localparam [1:0] SLEEP        = 2'b00;
    localparam [1:0] LOAD_COUNTER = 2'b10;
    localparam [1:0] COUNTING     = 2'b01;

    reg [DATA_OFFSET_WIDTH-1:0]  coef_offset_cnt;
    reg [DATA_ADDRESS_WIDTH-1:0] coef_ptr_reg;
    reg [DATA_OFFSET_WIDTH-1:0]  length_reg;

    assign coef_count_fin = (coef_offset_cnt == length_reg);
    assign coef_addr = (cnt == 1'b1) coef_offset_cnt + coef_ptr_reg : {DATA_ADDRESS_WIDTH{1'bz}};

    always @(posedge clk) begin : coef_offset_counting
        if (clr) begin
            coef_offset_cnt <= {DATA_OFFSET_WIDTH{1'b0}};
            coef_ptr_reg    <= {DATA_ADDRESS_WIDTH{1'b0}};
            length_reg      <= {DATA_OFFSET_WIDTH{1'b0}};
        end else begin
            case ({load, cnt})
                LOAD_COUNTER : begin
                    coef_offset_cnt <= {DATA_OFFSET_WIDTH{1'b0}};
                    coef_ptr_reg    <= coef_ptr;
                    length_reg      <= length;
                end
                COUNTING     : coef_offset_cnt <= coef_offset_cnt + 1'b1;
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
    wire cmd = {load, cnt};
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