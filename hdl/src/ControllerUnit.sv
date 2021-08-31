`include "CtrlUnit.svh"
`default_nettype none

module ControllerUnit (
    input  wire                        clk, rst, en,
    input  wire CtrlUnit::TAllocInstr  allocs_word,
    output reg                         en_ram_pa,
    output reg                         en_ram_pb,
    output reg                         en_mac,
    output reg                         rw_regf,
    output reg                         rw_ramp1,
    output reg                         rw_ramp2,
    output reg                         r_alocinstr,
    output reg                         mac_init, 
    output reg                         load,
    output reg                         res_err,
    output reg                         new_in,
    output reg                         new_out,
    output wire CtrlUnit::TAddrBus     addr_bus_1,
    output wire CtrlUnit::TAddrBus     addr_bus_2,
    output wire CtrlUnit::TState       ostate
);

    CtrlUnit::TState nstate, cstate;

    /* --------- Flags --------- */
    reg vecp_f; // vector convolution pass flag
    reg lstg_f; // vector of last stage pass flag
    reg upse_f; // upsample pass flag
    /* ------------------------- */

    AddrCalc calculator (.*);

    always_ff @(posedge clk) begin : state_switching
        if (!rst) begin
            if (en) begin
                cstate <= nstate;
            end
        end else begin
            cstate <= CtrlUnit::S1;
        end
    end : state_switching

    always_comb begin : next_state_switching_predition
        case (cstate)
            CtrlUnit::S1:
                nstate = CtrlUnit::S2;
            CtrlUnit::S2:
                nstate = CtrlUnit::S3;
            CtrlUnit::S3:
                nstate = (!vecp_f)? CtrlUnit::S3 : CtrlUnit::S4;
            CtrlUnit::S4:
                nstate = CtrlUnit::S5;
            CtrlUnit::S5:
                nstate = (!lstg_f)? CtrlUnit::S8 : CtrlUnit::S6;
            CtrlUnit::S6:
                nstate = (!upse_f)? CtrlUnit::S8 : CtrlUnit::S7;
            CtrlUnit::S7:
                nstate = CtrlUnit::S8;
            CtrlUnit::S8:
                nstate = CtrlUnit::S1;
        endcase
    end : next_state_switching_predition

    always_ff @(negedge clk) begin : current_state_signal_set
        if (!rst) begin
            if (en) begin
                // NOTE: uncomented lines mean "no need"
                case (cstate)
                    CtrlUnit::S1:
                    begin
                        en_ram_pa     <= 1'b0;
                        en_ram_pb     <= 1'b0;
                        en_mac        <= 1'b0;
                        rw_regf       <= 1'b0;
                        rw_ramp1      <= 1'b0;
                        rw_ramp2      <= 1'b0;
                        r_alocinstr   <= 1'b1;   // read instruction
                        mac_init      <= 1'b0;
                        load          <= 1'b0;
                        res_err       <= 1'b0;
                        new_in        <= 1'b0;
                        new_out       <= 1'b0;
                    end
                    CtrlUnit::S2:
                    begin
                        en_ram_pa     <= 1'b1;   // enable port a
                        en_ram_pb     <= 1'b0;
                        en_mac        <= 1'b1;   // enable mac for initialization
                        rw_regf       <= 1'b1;   // read error and sample from register file
                        rw_ramp1      <= 1'b0;   // write to head of sample vector in RAM
                        rw_ramp2      <= 1'b0;
                        r_alocinstr   <= 1'b0;
                        mac_init      <= 1'b1;   // mac initialization
                        load          <= 1'b0;
                        res_err       <= 1'b0;
                        new_in        <= 1'b0;
                        new_out       <= 1'b0;
                    end
                    CtrlUnit::S3:
                    begin
                        en_ram_pa     <= 1'b1;   // enable port a
                        en_ram_pb     <= 1'b1;   // enable port b
                        en_mac        <= 1'b1;   // enable mac
                        rw_regf       <= 1'b0;
                        rw_ramp1      <= 1'b0;
                        rw_ramp2      <= 1'b0;
                        r_alocinstr   <= 1'b0;
                        mac_init      <= 1'b0;
                        load          <= 1'b0;
                        res_err       <= 1'b0;
                        new_in        <= 1'b0;
                        new_out       <= 1'b0;
                    end
                    CtrlUnit::S4:
                    begin
                        en_ram_pa     <= 1'b0;
                        en_ram_pb     <= 1'b0;
                        en_mac        <= 1'b1;   // enable mac
                        rw_regf       <= 1'b0;
                        rw_ramp1      <= 1'b0;
                        rw_ramp2      <= 1'b0;
                        r_alocinstr   <= 1'b0;
                        mac_init      <= 1'b0;
                        load          <= 1'b1;   // mac load flag
                        res_err       <= 1'b1;   // load result flag
                        new_in        <= 1'b0;
                        new_out       <= 1'b0;
                    end
                    CtrlUnit::S5:
                    begin
                        en_ram_pa     <= 1'b0;
                        en_ram_pb     <= 1'b0;
                        en_mac        <= 1'b1;   // enable mac
                        rw_regf       <= 1'b0;
                        rw_ramp1      <= 1'b0;
                        rw_ramp2      <= 1'b0;
                        r_alocinstr   <= 1'b0;
                        mac_init      <= 1'b0;
                        load          <= 1'b1;   // mac load flag
                        res_err       <= 1'b0;   // load error flag
                        new_in        <= 1'b0;
                        new_out       <= 1'b0;
                    end
                    CtrlUnit::S6:
                    begin
                        en_ram_pa     <= 1'b0;
                        en_ram_pb     <= 1'b0;
                        en_mac        <= 1'b0;
                        rw_regf       <= 1'b1;   // read output sample from register file
                        rw_ramp1      <= 1'b0;
                        rw_ramp2      <= 1'b0;
                        r_alocinstr   <= 1'b0;
                        mac_init      <= 1'b0;
                        load          <= 1'b0;
                        res_err       <= 1'b0;
                        new_in        <= 1'b0;
                        new_out       <= 1'b1;   // system out flag
                    end
                    CtrlUnit::S7:
                    begin
                        en_ram_pa     <= 1'b0;
                        en_ram_pb     <= 1'b0;
                        en_mac        <= 1'b0;
                        rw_regf       <= 1'b0;   // write to register file
                        rw_ramp1      <= 1'b0;
                        rw_ramp2      <= 1'b0;
                        r_alocinstr   <= 1'b0;
                        mac_init      <= 1'b0;
                        load          <= 1'b0;
                        res_err       <= 1'b0;
                        new_in        <= 1'b1;   // request new sample
                        new_out       <= 1'b0;
                    end
                    CtrlUnit::S8:
                    begin
                        en_ram_pa     <= 1'b0;
                        en_ram_pb     <= 1'b0;
                        en_mac        <= 1'b0;
                        rw_regf       <= 1'b0;
                        rw_ramp1      <= 1'b0;
                        rw_ramp2      <= 1'b0;
                        r_alocinstr   <= 1'b0;
                        mac_init      <= 1'b0;
                        load          <= 1'b0;
                        res_err       <= 1'b0;
                        new_in        <= 1'b0;
                        new_out       <= 1'b0;
                    end
                endcase
            end
        end else begin
            {en_ram_pa, en_ram_pb, en_mac, rw_regf, rw_ramp1, rw_ramp2, r_alocinstr, mac_init, load, res_err, new_in, new_out} <= '0;
        end
    end : current_state_signal_set

    assign ostate = cstate;

endmodule : ControllerUnit





// -------------------------------------------------------
// -- AddrCalc.v
// -------------------------------------------------------
// Module for memory address calculation based on memory
// allocation inctruction
// -------------------------------------------------------

/* verilator lint_off DECLFILENAME */ 
module AddrCalc (
    input  wire                         clk, rst, en,
    input  wire CtrlUnit::TState        cstate,
    input  wire CtrlUnit::TAllocInstr   allocs_word,
    output      CtrlUnit::TAddrBus      addr_bus_1,
    output      CtrlUnit::TAddrBus      addr_bus_2,
    output reg                          vecp_f,   // vector convolution pass flag
    output reg                          lstg_f,   // vector of last stage pass flag
    output reg                          upse_f    // upsample pass flag
);
    
    // Allocation programm counter
    reg [CtrlUnit::PS_ADDR_W-1:0] pc;

    // Register set of head addres for each massive
    reg [15:0][CtrlUnit::DATA_ADDR_W-1:0] head;

    /*
    // Vectors counter
    reg [CtrlUnit::ALLOC_LEN_W-1:0] vecnt;
    
    // Stage counter
    reg [CtrlUnit::STAGE_W-1:0] scnt;
    */

    // Allocation instruction register
    CtrlUnit::TAllocInstr allocs_reg;

    // Data massive end addres
    wire [CtrlUnit::DATA_ADDR_W-1:0] data_end_ptr;
    assign data_end_ptr = allocs_reg.data_ptr + allocs_reg.vector_len - 1'b1;
    
    // Coefficient massive end addres
    wire [CtrlUnit::DATA_ADDR_W-1:0] coef_end_ptr;
    assign coef_end_ptr = allocs_reg.coef_ptr + allocs_reg.vector_len - 1'b1;
    
    // Data tail addres flag
    wire dtail_f;
    assign dtail_f = (addr_bus_1.dram_addr == (head[allocs_reg.vector_id] + 1));
    
    // Coefficient massive end addres flag
    wire cend_f;
    assign cend_f = (addr_bus_2.dram_addr == coef_end_ptr);

    always @(posedge clk) begin : addres_calculation
        if (!rst)
            if (en) begin
                case (cstate)
                    CtrlUnit::S1:
                    begin
                        addr_bus_1.regf_addr <= '0;
                        addr_bus_1.dram_addr <= {{(CtrlUnit::DATA_ADDR_W - CtrlUnit::PS_ADDR_W){1'b0}}, pc};
                        addr_bus_2 <= '0;
                        allocs_reg <= allocs_word; // -> (CtrlUnit.svh)
                        lstg_f <= allocs_reg.lstg_f;
                        upse_f <= allocs_reg.upse_f;                        
                    end
                    CtrlUnit::S2:
                    begin
                        addr_bus_1.regf_addr <= allocs_reg.result_reg - 1;
                        addr_bus_1.dram_addr <= head[allocs_reg.vector_id];
                        addr_bus_2.regf_addr <= allocs_reg.error_reg;
                        addr_bus_2.dram_addr <= '0;
                    end
                    CtrlUnit::S3:
                    begin
                        addr_bus_1.regf_addr <= '0;
                        addr_bus_1.dram_addr <= (addr_bus_1.dram_addr == allocs_reg.data_ptr)? data_end_ptr : addr_bus_1.dram_addr - 1;
                        addr_bus_2.regf_addr <= '0;
                        addr_bus_2.dram_addr <= addr_bus_2.dram_addr + 1;
                        vecp_f <= cend_f;
                        coef_and_data_end_falg: assert (dtail_f === cend_f)
                            else $error("Assertion coef_and_data_end_falg failed!");
                    end
                    CtrlUnit::S4:
                    begin
                        addr_bus_1.regf_addr <= allocs_reg.result_reg;
                        addr_bus_1.dram_addr <= '0;
                        addr_bus_2 <= '0;
                        head[allocs_reg.vector_id] <= (head[allocs_reg.vector_id] == data_end_ptr)? allocs_reg.data_ptr : head[allocs_reg.vector_id] + 1;
                    end
                    CtrlUnit::S5:
                    begin
                        addr_bus_1.regf_addr <= allocs_reg.result_reg;
                        addr_bus_1.dram_addr <= '0;
                        addr_bus_2 <= '0;
                    end
                    CtrlUnit::S6:
                    begin
                        addr_bus_1.regf_addr <= allocs_reg.result_reg;
                        addr_bus_1.dram_addr <= '0;
                        addr_bus_2 <= '0;
                    end
                    CtrlUnit::S7:
                    begin
                        addr_bus_1.regf_addr <= allocs_reg.result_reg;
                        addr_bus_1.dram_addr <= '0;
                        addr_bus_2 <= '0;
                    end
                    CtrlUnit::S8:
                    begin
                        if (!upse_f) begin
                            pc <= pc + 1;
                        end else begin
                            pc <= '0;
                        end
                    end
                endcase
            end
        else
        begin
            {pc, head, allocs_reg, addr_bus_1, addr_bus_2, vecp_f, lstg_f, upse_f} <= '0;
        end
    end : addres_calculation

endmodule : AddrCalc