`include "controller/ctrl_fsm.v"
`include "controller/ctrl_ifetch.v"
`include "controller/ctrl_olut.v"
`include "controller/ctrl_pc.v"
`include "controller/ctrl_ramdrv.v"
`include "controller/ctrl_regfdrv.v"

module ctrl_top #(
    parameter VEC_ID_WIDTH = 3,
    parameter REGFILE_ADDR_WIDTH = 3,
    parameter ALLOC_LENGTH_WIDTH = 4,
    parameter DATA_ADDR_WIDTH = 4,
    parameter INSTR_ADDR_WIDTH = $clog2(16)
)(
    input clk, rst, en, prog,
    input [INSTR_WIDTH-1:0]  instr_word,
    output wire fetch,
    output wire [INSTR_ADDR_WIDTH-1:0] pc,
    output wire             en_ram_pa, en_ram_pb,
    output wire              wr_ram_pa, wr_ram_pb,
    output wire  [DATA_ADDR_WIDTH-1:0] data_addr, coef_addr,
    output wire             rw,
    output wire [REGFILE_ADDR_WIDTH-1:0] ar1, ar2, ard
);

    localparam INSTR_WIDTH = 1 + 1 + VEC_ID_WIDTH + 2*REGFILE_ADDR_WIDTH + 3*DATA_ADDR_WIDTH;

    wire en_devs = ~prog && en;
    wire vector_pass, last_stage, last_vector;
    wire [2:0] ostate;

    ctrl_fsm u_ctrl_fsm(
        .clk         ( clk         ),
        .rst         ( rst         ),
        .en          ( en_devs     ),
        .vector_pass ( vector_pass ),
        .last_stage  ( last_stage  ),
        .last_vector ( last_vector ),
        .ostate      ( ostate      )
    );

    wire pc_clr, pc_incr;
    wire clr = rst | pc_clr;

    ctrl_pc#(
        .INSTRADDRW ( INSTR_ADDR_WIDTH )
     )u_ctrl_pc(
        .clk     ( clk     ),
        .clr     ( clr     ),
        .pc_incr ( pc_incr ),
        .pc      ( pc      )
    );

    wire h_init, a_init, cnt,
         res_err, rf_rw, get_reg, new_in, new_out;

    ctrl_olut u_ctrl_olut(
        .fsm_state ( ostate    ),
        .pc_clr    ( pc_clr    ),
        .pc_incr   ( pc_incr   ),
        .fetch     ( fetch     ),
        .h_init    ( h_init    ),
        .a_init    ( a_init    ),
        .cnt       ( cnt       ),
        .res_err   ( res_err   ),
        .rf_rw     ( rf_rw     ),
        .get_reg   ( get_reg   ),
        .new_in    ( new_in    ),
        .new_out   ( new_out   )
    );

    wire [VEC_ID_WIDTH-1:0] vector_id;
    wire [REGFILE_ADDR_WIDTH-1:0] result_reg, error_reg;
    wire [ALLOC_LENGTH_WIDTH-1:0] vector_len;
    wire [DATA_ADDR_WIDTH-1:0] data_uptr, data_lptr, coef_ptr;
    wire                        lstg_f, upse_f;

    ctrl_ifetch#(
        .VIDWIDTH   ( VEC_ID_WIDTH ),
        .RFAWIDTH   ( REGFILE_ADDR_WIDTH ),
        .DAWIDTH    ( DATA_ADDR_WIDTH )
    )u_ctrl_ifetch(
        .clk        ( clk        ),
        .rst        ( rst        ),
        .fetch      ( fetch      ),
        .instr_word ( instr_word ),
        .lstg_f     ( last_stage ),
        .upse_f     ( last_vector),
        .vector_id  ( vector_id  ),
        .result_reg ( result_reg ),
        .error_reg  ( error_reg  ),
        .data_uptr  ( data_uptr  ),
        .data_lptr  ( data_lptr  ),
        .coef_ptr   ( coef_ptr   )
    );



    ctrl_ramdrv#(
        .DATA_ADDRESS_WIDTH ( DATA_ADDR_WIDTH ),
        .DATA_OFFSET_WIDTH  ( ALLOC_LENGTH_WIDTH ),
        .VECTOR_INDEX_WIDTH ( VEC_ID_WIDTH )
    )u_ctrl_ramdrv(
        .clk                ( clk                ),
        .rst                ( rst                ),
        .h_init             ( h_init             ),
        .a_init             ( a_init             ),
        .cnt                ( cnt                ),
        .data_uptr          ( data_uptr          ),
        .data_lptr          ( data_lptr          ),
        .coef_ptr           ( coef_ptr           ),
        .vector_id          ( vector_id          ),
        .conv_pass          ( vector_pass        ),
        .data_addr          ( data_addr          ),
        .coef_addr          ( coef_addr          )
    );



    ctrl_regfdrv#(
        .WIDTH      ( REGFILE_ADDR_WIDTH)
     )u_ctrl_regfdrv(
        .clk        ( clk        ),
        .rst        ( rst        ),
        .en         ( en_devs    ),
        .res_err    ( res_err    ),
        .get_reg    ( get_reg    ),
        .result_reg ( result_reg ),
        .error_reg  ( error_reg  ),
        .rf_rw      ( rf_rw      ),
        .ar1        ( ar1        ),
        .ar2        ( ar2        ),
        .ard        ( ard        )
    );

    
endmodule