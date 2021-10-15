//! @title Inrtuction fetch scheme
//! @file ctrl_ifetch.v
//! @author Ivan @DEFAULTTEXHAPb
//! @date 01-09-2021
//! @brief This is Finite State Machine for Controller
//! with 8 states. It allows to manage data flow of 
//! upsampling process

module ctrl_ifetch #(
    parameter RFAWIDTH = 5, //! Register address instruction field width
    parameter DAWIDTH  = 12     //! Data RAM address instruction field width
)(
    input  wire                  clk,        //! __*Clock*__
    input  wire                  rst,        //! __*Reset*__
    input  wire                  en_fetch,   //! Instruction fetch flag
    input  wire                  iw_valid,   //! Pointer struct content valid
    input       [INSTRWIDTH-1:0] instr_word, //! Word from instruction memory
    output reg                   lstg_f,     //! *`Instruction word:`* Last upsampler stage flag
    output reg                   startups_f, //! *`Instruction word:`* First upsampler vector flag
    output reg  [RFAWIDTH-1:0]   result_reg, //! *`Instruction word:`* Result register address
    output reg  [RFAWIDTH-1:0]   error_reg,  //! *`Instruction word:`* Error register address
    output reg  [DAWIDTH-1:0]    data_bptr,  //! *`Instruction word:`* Base data ring buffer segment pointer
    output reg  [DAWIDTH-1:0]    data_lptr,  //! *`Instruction word:`* Lower data ring buffer segment pointer
    output reg  [DAWIDTH-1:0]    data_hptr,  //! *`Instruction word:`* Head data ring buffer segment pointer
    output reg  [DAWIDTH-1:0]    filt_coef_ptr    //! *`Instruction word:`* Coefficient massive pointer
);
    //! Allocation instruction width
    localparam INSTRWIDTH = 1 + 1 + 2*RFAWIDTH + 4*DAWIDTH;
    
    //! Prefetch handshake
    wire assert_fetch = ((iw_valid == 1'b1)&(en_fetch == 1'b1)) == 1'b1;

    initial begin
        {lstg_f, startups_f, result_reg, error_reg, data_bptr, data_lptr, data_hptr, filt_coef_ptr} = {INSTRWIDTH{1'b0}};
    end

    //! Instruction fetch process
    always @(negedge clk) begin : fetch_process
        if (rst == 1'b1) begin
              {lstg_f, startups_f, result_reg, error_reg, data_bptr, data_lptr, data_hptr, filt_coef_ptr} <= {INSTRWIDTH{1'b0}};
        end else begin
            if (assert_fetch == 1'b1)
              {lstg_f, startups_f, result_reg, error_reg, data_bptr, data_lptr, data_hptr, filt_coef_ptr} <= instr_word;
        end
    end
    
endmodule