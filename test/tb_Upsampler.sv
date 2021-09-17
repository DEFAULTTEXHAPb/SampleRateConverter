`include "./hdl/src/ControllerUnit.sv"
`include "./hdl/include/CtrlUnit.svh"
`timescale 1ns/10ps
module tb_Upsampler();

    logic                 clk, rst, en;
    CtrlUnit::TAllocInstr allocs_word;
    logic             en_ram_pa;
    logic             en_ram_pb;
    logic             en_mac;
    logic             rw_logicf;
    logic             rw_ramp1;
    logic             rw_ramp2;
    logic             r_alocinstr;
    logic             mac_init;
    logic             load;
    logic             res_err;
    logic             new_in;
    logic             new_out;
    CtrlUnit::TAddrBus    addr_bus_1;
    CtrlUnit::TAddrBus    addr_bus_2;
    CtrlUnit::fsmState_e      ostate;

    logic [CtrlUnit::PS_ADDR_W-1:0] pc;
    CtrlUnit::fsmState_e      past_state;

    ControllerUnit dut (.*);

    logic [3:0] test_timer = '0;

    CtrlUnit::TAllocInstr prog [0:15];
    initial $readmemb("./simulation/prog.txt", prog);

    initial begin
        clk         = '0;
        en          = '0;
        allocs_word = '0;
        pc          = '0;
    end

    initial begin : system_reset_proc
        #8 rst = '0;
        #16 rst = '1;
        #8 rst = '0;
    end : system_reset_proc

    always #5 clk = ~clk;
    
    always_ff @(posedge clk && ostate) begin
        pc          <= (ostate == CtrlUnit::S1)? addr_bus_1.dram_addr : pc;
        test_timer  <= test_timer + 1;
        if (test_timer == 4'b1111) begin
            $finish();
        end
    end

    always @(r_alocinstr) begin
        allocs_word <= prog[pc];
    end

    initial begin : main_test_start
        #20 en = 1;
        // if ((pc == 15)) begin
        //     $finish();
        // end
    end : main_test_start

    logic fetch_f = ~(en_ram_pa && en_ram_pb && en_mac && rw_logicf && rw_ramp1 && rw_ramp2 && ~r_alocinstr && mac_init && load && res_err && new_in && new_out);
    logic load_f = ~(~en_ram_pa && en_ram_pb && ~en_mac && ~rw_logicf && rw_ramp1 && rw_ramp2 && r_alocinstr && ~mac_init && load && res_err && new_in && new_out);
    logic calc_f = ~(~en_ram_pa && ~en_ram_pb && ~en_mac && rw_logicf && rw_ramp1 && rw_ramp2 && r_alocinstr && mac_init && load && res_err && new_in && new_out);
    logic res_f = ~(en_ram_pa && en_ram_pb && ~en_mac && rw_logicf && rw_ramp1 && rw_ramp2 && r_alocinstr && mac_init && ~load && ~res_err && new_in && new_out);
    logic err_f = ~(en_ram_pa && en_ram_pb && ~en_mac && rw_logicf && rw_ramp1 && rw_ramp2 && r_alocinstr && mac_init && ~load && res_err && new_in && new_out);
    logic out_f = ~(en_ram_pa && en_ram_pb && en_mac && ~rw_logicf && rw_ramp1 && rw_ramp2 && r_alocinstr && mac_init && load && res_err && new_in && ~new_out);
    logic new_f = ~(en_ram_pa && en_ram_pb && en_mac && rw_logicf && rw_ramp1 && rw_ramp2 && r_alocinstr && mac_init && load && res_err && ~new_in && new_out);
    logic incr_f = ~(en_ram_pa && en_ram_pb && en_mac && rw_logicf && rw_ramp1 && rw_ramp2 && r_alocinstr && mac_init && load && res_err && new_in && new_out);
    logic [7:0] check_word = {fetch_f, load_f, calc_f, res_f, err_f, out_f, new_f, incr_f};

    
    
    always @(check_word) begin
        case (check_word)
            8'b1000_0000: $display("State 1 flags output check pass!\n");
            8'b0100_0000: $display("State 2 flags output check pass!\n");
            8'b0010_0000: $display("State 3 flags output check pass!\n");
            8'b0001_0000: $display("State 4 flags output check pass!\n");
            8'b0000_1000: $display("State 5 flags output check pass!\n");
            8'b0000_0100: $display("State 6 flags output check pass!\n");
            8'b0000_0010: $display("State 7 flags output check pass!\n");
            8'b0000_0001: $display("State 8 flags output check pass!\n");
            default:      $error("Flags output\n");
        endcase
    end

endmodule