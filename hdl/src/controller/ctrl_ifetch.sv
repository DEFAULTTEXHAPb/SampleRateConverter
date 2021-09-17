//! @title Inrtuction fetch scheme
//! @file ctrl_ifetch.v
//! @author Ivan @DEFAULTTEXHAPb
//! @date 01-09-2021
//! @brief This is Finite State Machine for Controller
//! with 8 states. It allows to manage data flow of 
//! upsampling process

`include "ctrl.svh"

module ctrl_ifetch #(
    parameter VIDWIDTH = ctrl::VECTOR_ID_WIDTH,  //! Vector ID instruction field width
    parameter RFAWIDTH = ctrl::REG_FILE_ADDRESS_WIDTH,  //! logicister address instruction field width
    parameter DAWIDTH = ctrl::DATA_RAM_ADDRESS_WIDTH  //! Data RAM address instruction field width
) (
    input clk,  //! __*Clock*__
    input rst,  //! __*Reset*__
    input fetch,  //! Instruction fetch flag
    input ctrl::allocInstr_s instr_word,  //! Word from instruction memory
    output logic lstg_f,  //! *`Instruction word:`* Last upsampler stage flag
    output logic upse_f,  //! *`Instruction word:`* Last upsampler vector flag
    output logic [VIDWIDTH-1:0] vector_id,  //! *`Instruction word:`* Vector ID
    output logic [RFAWIDTH-1:0] result_logic,  //! *`Instruction word:`* Result logicister address
    output logic [RFAWIDTH-1:0] error_logic,  //! *`Instruction word:`* Error logicister address
    output logic [DAWIDTH-1:0]    data_uptr,  //! *`Instruction word:`* Upper data ring buffer segment pointer
    output logic [DAWIDTH-1:0]    data_lptr,  //! *`Instruction word:`* Lower data ring buffer segment pointer
    output logic [DAWIDTH-1:0] coef_ptr  //! *`Instruction word:`* Coefficient massive pointer
);

  ctrl::allocInstr_s instr_reg;

  initial begin
    instr_reg = '0;
  end

  //! Instruction fetch process
  always @(posedge clk) begin : fetch_process
    if (!rst) begin
      if (fetch) instr_reg <= instr_word;
    end else begin
      instr_reg <= '0;
    end
  end

  //! Instruction split logic
  always_comb begin : split
    lstg_f       = instr_reg.lstg_f;
    upse_f       = instr_reg.upse_f;
    vector_id    = instr_reg.vector_id;
    result_logic = instr_reg.result_logic;
    error_logic  = instr_reg.error_logic;
    data_uptr    = instr_reg.data_uptr;
    data_lptr    = instr_reg.data_lptr;
    coef_ptr     = instr_reg.coef_ptr;
  end

endmodule
