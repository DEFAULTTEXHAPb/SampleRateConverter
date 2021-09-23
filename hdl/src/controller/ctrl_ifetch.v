//! @title Inrtuction fetch scheme
//! @file ctrl_ifetch.v
//! @author Ivan @DEFAULTTEXHAPb
//! @date 01-09-2021
//! @brief This is Finite State Machine for Controller
//! with 8 states. It allows to manage data flow of 
//! upsampling process

module ctrl_ifetch #(
    parameter VIDWIDTH = 5,       //! Vector ID instruction field width
    parameter RFAWIDTH = 5, //! Register address instruction field width
    parameter DAWIDTH  = 12     //! Data RAM address instruction field width
)(
    input                       clk,        //! __*Clock*__
    input                       rst,        //! __*Reset*__
    input                       fetch,      //! Instruction fetch flag
    input      [INSTRWIDTH-1:0] instr_word, //! Word from instruction memory
    output reg                  lstg_f,     //! *`Instruction word:`* Last upsampler stage flag
    output reg                  upse_f,     //! *`Instruction word:`* Last upsampler vector flag
    output reg [VIDWIDTH-1:0]   vector_id,  //! *`Instruction word:`* Vector ID
    output reg [RFAWIDTH-1:0]   result_reg, //! *`Instruction word:`* Result register address
    output reg [RFAWIDTH-1:0]   error_reg,  //! *`Instruction word:`* Error register address
    output reg [DAWIDTH-1:0]    data_uptr,  //! *`Instruction word:`* Upper data ring buffer segment pointer
    output reg [DAWIDTH-1:0]    data_lptr,  //! *`Instruction word:`* Lower data ring buffer segment pointer
    output reg [DAWIDTH-1:0]    coef_ptr    //! *`Instruction word:`* Coefficient massive pointer
);
    //! Allocation instruction width
    localparam INSTRWIDTH = 1 + 1 + VIDWIDTH + 2*RFAWIDTH + 3*DAWIDTH;

    initial begin
        {lstg_f, upse_f, vector_id, result_reg, error_reg, data_uptr, data_lptr, coef_ptr} = {INSTRWIDTH{1'b0}};
    end

    //! Instruction fetch process
    always @(posedge clk) begin : fetch_process
        if (rst == 1'b1) begin
            if (fetch) {lstg_f, upse_f, vector_id, result_reg, error_reg, data_uptr, data_lptr, coef_ptr} <= {INSTRWIDTH{1'b0}};
        end else begin
            {lstg_f, upse_f, vector_id, result_reg, error_reg, data_uptr, data_lptr, coef_ptr} <= instr_word;
        end
    end
    
endmodule