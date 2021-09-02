//! @title Controller FSM
//! @file ctrl_fsm.v
//! @author Ivan @DEFAULTTEXHAPb
//! @date 01-09-2021
//! @brief This is Finite State Machine for Controller
//! with 8 states. It allows to manage data flow of 
//! upsampling process

module FSM (
    input  wire        clk,         //! __*Clock*__
    input  wire        rst,         //! __*Reset*__
    input  wire        en,          //! __*Clock enable*__
    input  wire        vector_pass, //! Vector convolution pass flag
    input  wire        last_stage,  //! Last upsampler stage flag
    input  wire        last_vector, //! Last upsampler vector flag
    output wire [2:0]  ostate       //! FSM state
);

    reg [2:0] cstate; //! Current state register
    reg [2:0] nstate; //! Next state register

    localparam [2:0] S1 = 3'b000;  //! Memory allocation
    localparam [2:0] S2 = 3'b001;  //! Load sample from regfile to RAM and initialize MAC
    localparam [2:0] S3 = 3'b010;  //! Vector convolution on MAC
    localparam [2:0] S4 = 3'b011;  //! Load result from MAC to register file
    localparam [2:0] S5 = 3'b100;  //! Load error from MAC to register file
    localparam [2:0] S6 = 3'b101;  //! Load system output sample
    localparam [2:0] S7 = 3'b110;  //! Load new sapmle from audio bus
    localparam [2:0] S8 = 3'b111;  //! Allocation list counter increment

    //! State switching logic
    always @(posedge clk) begin : state_switching
        if (!rst) begin
            if (en) begin
                cstate <= nstate;
            end
        end else begin
            cstate <= S1;
        end
    end
    
    //! Next state logic
    always @(posedge clk) begin : next_state_switching_predition
        case (nstate)
            S1:
                nstate = S2;
            S2:
                nstate = S3;
            S3:
                nstate = (!vector_pass)? S3 : S4;
            S4:
                nstate = S5;
            S5:
                nstate = (!last_stage)? S8 : S6;
            S6:
                nstate = (!last_vector)? S8 : S7;
            S7:
                nstate = S8;
            S8:
                nstate = S1;
        endcase
    end

    assign ostate = cstate;

`ifdef DEBUG
    reg [8*50-1:0] ostate_ascii; //! `debug:` ASCII state decoding var
    //! `debug:` ASCII state decoding
    always @(ostate) begin : state_ascii
        case (ostate)
            S1 : ostate_ascii = "ALLOC";
            S2 : ostate_ascii = "LOAD_AND_INIT";
            S3 : ostate_ascii = "CONVOLUTION";
            S4 : ostate_ascii = "LOAD_RESULT";
            S5 : ostate_ascii = "LOAD_ERROR";
            S6 : ostate_ascii = "LOAD_OUTPUT";
            S7 : ostate_ascii = "LOAD_INPUT";
            S8 : ostate_ascii = "PC_INCREMENT";
            default: begin
                ostate_ascii = "XSTATE";
            end
        endcase
    end
`endif
    
endmodule