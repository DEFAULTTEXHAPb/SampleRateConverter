//`include "/home/chort/projects/UPSAMPLER/hdl/include/global_define.svh"
//`include "global_define.svh"

`ifndef CTRLUNIT
`define CTRLUNIT

    `define ADDR_BUS `PS_ADDR_W+2*`REGFILE_ADDR_W+2*`DATA_ADDR_W
    `define ALLOC_INSTR_W 1+1+`VEC_ID_W+`REGFILE_ADDR_W+`REGFILE_ADDR_W+`ALLOC_LEN_W+`DATA_ADDR_W+`DATA_ADDR_W
    `define GND_BUS(width) {width{1'b0}}

    /* ---------- Addres bus structure ---------- */
    generate
        begin : address_bus
            // Allocation instruction programm counter
            reg [`PS_ADDR_W-1:0] pc;
            // Error Register file addres
            reg [`REGFILE_ADDR_W-1:0] err_regf_addr;
            // Result Register file addres
            reg [`REGFILE_ADDR_W-1:0] res_regf_addr;
            // Samples data ram addres
            reg [`DATA_ADDR_W-1:0] smp_dram_addr;
            // Coefficient data ram addres
            reg [`DATA_ADDR_W-1:0] coe_dram_addr;
        end : address_bus
    endgenerate
    /* ------------------------------------------ */

    /* ------- Allocation instruction word ------ */
    generate
        begin : alloc_instr
            // vector of last stage pass flag
            reg                       lstg_f;
            // upsample pass flag
            reg                       upse_f;
            // Vector id number
            reg [`VEC_ID_W-1:0]       vector_id;
            // Result register addres
            reg [`REGFILE_ADDR_W-1:0] result_reg;
            // Error register addres
            reg [`REGFILE_ADDR_W-1:0] error_reg;
            // Allocation length
            reg [`ALLOC_LEN_W-1:0]    vector_len;
            // Data array pointer
            reg [`DATA_ADDR_W-1:0]    data_ptr;
            // Coefficient array pointer
            reg [`DATA_ADDR_W-1:0]    coef_ptr;
        end : alloc_instr                        
    endgenerate
    /* ------------------------------------------ */

    /* ------- FSM_states -------- */
    `define USE_STATES_ENUM                                                         \
    generate                                                                        \
        begin : states                                                              \
            localparam [2:0]                                                        \
                S1 = 3'b000,  // Memory allocation                                  \
                S2 = 3'b001,  // Load sample from regfile to RAM and initialize MAC \
                S3 = 3'b010,  // Vector convolution on MAC                          \
                S4 = 3'b011,  // Load result from MAC to register file              \
                S5 = 3'b100,  // Load error from MAC to register file               \
                S6 = 3'b101,  // Load system output sample                          \
                S7 = 3'b110,  // Load new sapmle from audio bus                     \
                S8 = 3'b111;   // Allocation list counter increment                 \
        end : states                                                                \
    endgenerate
    /* --------------------------- */

`endif