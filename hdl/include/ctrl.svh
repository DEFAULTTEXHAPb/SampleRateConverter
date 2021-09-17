`ifndef __CTRL_SVH__
`define __CTRL_SVH__

package ctrl;

  localparam VECTOR_ID_WIDTH = 4;
  localparam REG_FILE_ADDRESS_WIDTH = 5;
  localparam DATA_RAM_ADDRESS_WIDTH = 12;
  localparam DATA_OFFSET_WIDTH = 10;
  localparam INSTRUCTION_MEMORY_SIZE = 32;

  typedef enum logic [2 : 0] {
    S1 = 3'b000,  //! Memory allocation
    S2 = 3'b001,  //! Load sample from logicfile to RAM and initialize MAC
    S3 = 3'b010,  //! Vector convolution on MAC
    S4 = 3'b011,  //! Load result from MAC to logicister file
    S5 = 3'b100,  //! Load error from MAC to logicister file
    S6 = 3'b101,  //! Load system output sample
    S7 = 3'b110,  //! Load new sapmle from audio bus
    S8 = 3'b111   //! Allocation list counter increment
  } fsmState_e;

  typedef struct packed {
    logic lstg_f;  //! *`Instruction word:`* Last upsampler stage flag
    logic upse_f;  //! *`Instruction word:`* Last upsampler vector flag
    logic [VECTOR_ID_WIDTH-1:0] vector_id;  //! *`Instruction word:`* Vector ID
    logic [REG_FILE_ADDRESS_WIDTH-1:0] result_logic;//! *`Instruction:`* Result logicister address
    logic [REG_FILE_ADDRESS_WIDTH-1:0] error_logic; //! *`Instruction:`* Error logicister address
    logic [DATA_RAM_ADDRESS_WIDTH-1:0] data_uptr;   //! *`Instruction:`* Upper data ring buffer segment pointer
    logic [DATA_RAM_ADDRESS_WIDTH-1:0] data_lptr;   //! *`Instruction:`* Lower data ring buffer segment pointer
    logic [DATA_RAM_ADDRESS_WIDTH-1:0] coef_ptr;    //! *`Instruction:`* Coefficient massive pointer
  } allocInstr_s;

  typedef logic [DATA_RAM_ADDRESS_WIDTH-1:0] data_addr_t;
  typedef logic [DATA_OFFSET_WIDTH-1:0] data_offset_t;
  typedef logic [REG_FILE_ADDRESS_WIDTH-1:0] reg_file_addr_t;
  typedef logic [VECTOR_ID_WIDTH-1:0] vector_id_t;
  typedef logic [$clog2(INSTRUCTION_MEMORY_SIZE)-1:0] instr_pointer_t;

endpackage

`endif
