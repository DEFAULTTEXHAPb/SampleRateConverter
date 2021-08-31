`include "global_define.svh"
package CtrlUnit;

    typedef enum reg [2:0] { 
        S1 = 3'b000,  // Memory allocation
        S2 = 3'b001,  // Load sample from regfile to RAM and initialize MAC
        S3 = 3'b010,  // Vector convolution on MAC
        S4 = 3'b011,  // Load result from MAC to register file
        S5 = 3'b100,  // Load error from MAC to register file
        S6 = 3'b101,  // Load system output sample
        S7 = 3'b110,  // Load new sapmle from audio bus
        S8 = 3'b111   // Allocation list counter increment
    } TState;
    
    /*
    typedef enum reg [2:0] { 
        as_count_inc = 3'b000, // ASC increment
        load_sample  = 3'b001, // Loading from register file into RAM and MAC
        calc_sample  = 3'b010, // Vector convolution caclulation
        get_sample   = 3'b011, // Loading result into register file from MAC
        get_error    = 3'b100, // Loading error into register file from MAC
        alloc        = 3'b101  // Memory allocation do i need this
    } TAddrCalcMode;
    
    
    typedef enum reg [1:0] { 
        read_reg   = 2'b00, // Read registers (for calculation preset/system output/instruction fetch)
        write_reg  = 2'b01, // Writing register (system in/write result/write error)
        calc_exec  = 2'b10, // Vector convolution caclulation
        pc_incr    = 2'b11  // Program counter increment
    } TAddrCalcMode;
    */

    localparam VEC_ID_W       = `VEC_ID_W;
    localparam STAGE_W        = `STAGE_W;
    localparam DATA_ADDR_W    = `DATA_ADDR_W;
    localparam ALLOC_LEN_W    = `ALLOC_LEN_W;
    localparam REGFILE_ADDR_W = `REGFILE_ADDR_W;
    localparam PS_ADDR_W      = `PS_ADDR_W;

    //localparam ALLOCSET_W     = STAGE_W + VEC_ID_W + 2*REGFILE_ADDR_W + ALLOC_LEN_W + 2*DATA_ADDR_W;

    typedef struct packed {
        reg                      lstg_f;
        reg                      upse_f;
        reg [VEC_ID_W-1:0]       vector_id;
        reg [REGFILE_ADDR_W-1:0] result_reg;
        reg [REGFILE_ADDR_W-1:0] error_reg;
        reg [ALLOC_LEN_W-1:0]    vector_len;
        reg [DATA_ADDR_W-1:0]    data_ptr;
        reg [DATA_ADDR_W-1:0]    coef_ptr;
    } TAllocInstr;

    typedef struct packed {
        reg [REGFILE_ADDR_W-1:0] regf_addr;
        reg [DATA_ADDR_W-1:0]    dram_addr;
    } TAddrBus;

endpackage : CtrlUnit
