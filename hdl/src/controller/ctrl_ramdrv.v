`include "controller/ctrl_ramdrv_coefcnt.v"
`include "controller/ctrl_ramdrv_header.v"
`include "controller/ctrl_ramdrv_ringbuf.v"

module ctrl_ramdrv #(
    parameter DATA_ADDRESS_WIDTH = 12,
    parameter DATA_OFFSET_WIDTH = 5,
    parameter VECTOR_INDEX_WIDTH = 5
)(
    input  wire                          clk,
    input  wire                          rst,
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

    wire                          data_count_fin;
    wire                          coef_count_fin;
    wire                          pass = data_count_fin & coef_count_fin;

    wire [DATA_OFFSET_WIDTH-1:0]  head_offset;
    wire [DATA_ADDRESS_WIDTH-1:0] rb_data_addr;
    wire [DATA_ADDRESS_WIDTH-1:0] init_data_addr = (cnt == 1'b0)? {{(DATA_ADDRESS_WIDTH-DATA_OFFSET_WIDTH){1'b0}},head_offset} + data_uptr : {DATA_ADDRESS_WIDTH{1'bz}};
    wire [DATA_ADDRESS_WIDTH-1:0] length_sub = data_lptr;
    wire [DATA_OFFSET_WIDTH-1:0]  length = length_sub[DATA_OFFSET_WIDTH-1:0];

    assign data_addr = (cnt == 1'b1)? rb_data_addr : init_data_addr;
    assign conv_pass = pass;

    ctrl_ramdrv_ringbuf #(
        .DATA_ADDRESS_WIDTH ( DATA_ADDRESS_WIDTH ),
        .DATA_OFFSET_WIDTH  ( DATA_OFFSET_WIDTH )
    )u_ctrl_ramdrv_ringbuf(
        .clk                ( clk                ),
        .clr                ( rst                ),
        .cnt                ( cnt                ),
        .init               ( a_init             ),
        .data_uptr          ( data_uptr          ),
        .data_lptr          ( data_lptr          ),
        .head_offset        ( head_offset        ),
        .data_count_fin     ( data_count_fin     ),
        .data_addr          ( rb_data_addr       )
    );

    ctrl_ramdrv_header #(
        .DATA_OFFSET_WIDTH ( DATA_OFFSET_WIDTH ),
        .VECTOR_INDEX_WIDTH ( VECTOR_INDEX_WIDTH )
    )u_ctrl_ramdrv_header(
        .clk               ( clk               ),
        .rst               ( rst               ),
        .init              ( h_init            ),
        .head_inc          ( pass              ),
        .read_reg          ( a_init            ),
        .index             ( vector_id         ),
        .length            ( length            ),
        .head_offset       ( head_offset       )
    );

    ctrl_ramdrv_coefcnt#(
        .DATA_ADDRESS_WIDTH ( DATA_ADDRESS_WIDTH ),
        .DATA_OFFSET_WIDTH  ( DATA_OFFSET_WIDTH )
    )u_ctrl_ramdrv_coefcnt(
        .clk                ( clk                ),
        .clr                ( rst                ),
        .load               ( a_init             ),
        .cnt                ( cnt                ),
        .coef_ptr           ( coef_ptr           ),
        .length             ( length             ),
        .coef_count_fin     ( coef_count_fin     ),
        .coef_addr          ( coef_addr          )
    );

`ifdef DEBUG
    always @(length_sub) begin
        if (length_sub[DATA_ADDRESS_WIDTH-1:DATA_OFFSET_WIDTH] != {(DATA_ADDRESS_WIDTH-DATA_OFFSET_WIDTH){1'b0}}) begin
            $display("Error in vector length calculation: msb bits are not zero! (Unit: %m; File: Controller.v; line: 117; time: %t)", $time);
            $finish(2);
        end
    end
    always @(*) begin
        if ((cnt == 1'b1)&((data_count_fin ^ coef_count_fin) == 1'b1)) begin
            $display("Unable word! (Unit: %m; File: Controller.v; line: 117; time: %t)", $time);
            $finish(2);
        end
    end
`endif



endmodule