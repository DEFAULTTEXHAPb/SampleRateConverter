module OutLut (
    input [2:0] fsm_state,
    output reg pc_clr, pc_incr,
    output reg fetch,
    output reg readh_incrh, read_write,
    output reg res_err, rf_rw, get_reg,
    output reg new_in, new_out
);

    localparam [2:0] S1 = 3'b000;  //! Memory allocation
    localparam [2:0] S2 = 3'b001;  //! Load sample from regfile to RAM and initialize MAC
    localparam [2:0] S3 = 3'b010;  //! Vector convolution on MAC
    localparam [2:0] S4 = 3'b011;  //! Load result from MAC to register file
    localparam [2:0] S5 = 3'b100;  //! Load error from MAC to register file
    localparam [2:0] S6 = 3'b101;  //! Load system output sample
    localparam [2:0] S7 = 3'b110;  //! Load new sapmle from audio bus
    localparam [2:0] S8 = 3'b111;  //! Allocation list counter increment

    always @(fsm_state) begin
        pc_clr      = (fsm_state == S7);
        pc_incr     = (fsm_state == S8);
        fetch       = (fsm_state == S1);
        readh_incrh = (fsm_state == S4)||(fsm_state == S2);
        read_write  = (fsm_state == S3);
        res_err     = (fsm_state == S4);
        rf_rw       = (fsm_state == S4)||(fsm_state == S5)||(fsm_state == S7);
        get_reg     = (fsm_state == S2)||(fsm_state == S7);
        new_in      = (fsm_state == S7);
        new_out     = (fsm_state == S6);
    end
    
endmodule