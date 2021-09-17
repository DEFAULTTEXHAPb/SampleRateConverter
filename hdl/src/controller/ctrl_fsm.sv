//! @title Controller FSM
//! @file ctrl_fsm.v
//! @author Ivan @DEFAULTTEXHAPb
//! @date 01-09-2021
//! @brief This is Finite State Machine for Controller
//! with 8 states. It allows to manage data flow of 
//! upsampling process

`include "ctrl.svh"

module ctrl_fsm (
    input  logic        clk,          //! __*Clock*__
    input  logic        rst,          //! __*Reset*__
    input  logic        en,           //! __*Clock enable*__
    input  logic        vector_pass,  //! Vector convolution pass flag
    input  logic        last_stage,   //! Last upsampler stage flag
    input  logic        last_vector,  //! Last upsampler vector flag
    output ctrl::fsmState_e ostate        //! FSM state
);

  ctrl::fsmState_e cstate;  //! Current state logicister
  ctrl::fsmState_e nstate;  //! Next state logicister

  initial begin
    cstate = ctrl::S1;
    nstate = ctrl::S1;
  end

  //! State switching logic
  always @(posedge clk) begin : state_switching
    if (!rst) begin
      if (en) begin
        cstate <= nstate;
      end
    end else begin
      cstate <= ctrl::S1;
    end
  end

  //! Next state logic
  always_comb begin : next_state_switching_predition
    case (nstate)
      ctrl::S1: nstate = ctrl::S2;
      ctrl::S2: nstate = ctrl::S3;
      ctrl::S3: nstate = (!vector_pass) ? ctrl::S3 : ctrl::S4;
      ctrl::S4: nstate = ctrl::S5;
      ctrl::S5: nstate = (!last_stage) ? ctrl::S8 : ctrl::S6;
      ctrl::S6: nstate = (!last_vector) ? ctrl::S8 : ctrl::S7;
      ctrl::S7: nstate = ctrl::S8;
      ctrl::S8: nstate = ctrl::S1;
    endcase
  end

  assign ostate = cstate;


  logic [8*50-1:0] ostate_ascii;
  always @(ostate) begin : state_ascii
    case (ostate)
      ctrl::S1: ostate_ascii = "ALLOC";
      ctrl::S2: ostate_ascii = "LOAD_AND_INIT";
      ctrl::S3: ostate_ascii = "CONVOLUTION";
      ctrl::S4: ostate_ascii = "LOAD_RESULT";
      ctrl::S5: ostate_ascii = "LOAD_ERROR";
      ctrl::S6: ostate_ascii = "LOAD_OUTPUT";
      ctrl::S7: ostate_ascii = "LOAD_INPUT";
      ctrl::S8: ostate_ascii = "PC_INCREMENT";
      default: begin
        ostate_ascii = "XSTATE";
      end
    endcase
  end


endmodule
