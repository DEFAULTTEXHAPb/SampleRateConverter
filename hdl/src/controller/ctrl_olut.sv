module ctrl_olut (
    input [2:0] fsm_state,
    output logic pc_clr, pc_incr,
    output logic fetch,
    output logic h_init, a_init, cnt, 
    output logic res_err, rf_rw, get_logic,
    output logic new_in, new_out
);

    initial begin
        { pc_clr, pc_incr, fetch, h_init, a_init, cnt, res_err, rf_rw, get_logic, new_in, new_out } = 11'b00000000000;
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
        get_logic     = (fsm_state == S2)||(fsm_state == S7);
        new_in      = (fsm_state == S7);
        new_out     = (fsm_state == S6);
    end
    
endmodule