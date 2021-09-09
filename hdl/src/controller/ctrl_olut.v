module OutLut (
    input [2:0] fsm_state,
    output reg pc_clr, pc_incr,
    output reg fetch,
    output reg h_init, a_init, cnt, 
    output reg res_err, rf_rw, get_reg,
    output reg new_in, new_out
);

    localparam [2:0]
        S1 = 3'b000,  // Memory allocation
        S2 = 3'b001,  // Load sample from regfile to RAM and initialize MAC
        S3 = 3'b010,  // Vector convolution on MAC
        S4 = 3'b011,  // Load result from MAC to register file
        S5 = 3'b100,  // Load error from MAC to register file
        S6 = 3'b101,  // Load system output sample
        S7 = 3'b110,  // Load new sapmle from audio bus
        S8 = 3'b111;   // Allocation list counter increment

    initial begin
        { pc_clr, pc_incr, fetch, h_init, a_init, cnt, res_err, rf_rw, get_reg, new_in, new_out } = 11'b00000000000;
    end

    always @(fsm_state) begin
        pc_clr      = (fsm_state == S7);
        pc_incr     = (fsm_state == S8);
        fetch       = (fsm_state == S1);
        h_init      = (fsm_state == S1);
        a_init      = (fsm_state == S2);
        cnt         = (fsm_state == S3);
        res_err     = (fsm_state == S4);
        rf_rw       = (fsm_state == S4)||(fsm_state == S5)||(fsm_state == S7);
        get_reg     = (fsm_state == S2)||(fsm_state == S7);
        new_in      = (fsm_state == S7);
        new_out     = (fsm_state == S6);
    end
    
endmodule