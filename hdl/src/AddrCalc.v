`include "./hdl/include/AddrCalc_h.v"

task assert_end ( input signal, input value );
    if (signal !== value)
        $display("SIMULATION ASSERTION FAILED: in %m expexted(%s === %b), but got (%s === %b)", "signal", value, "signal", signal);
    $finish(2);
endtask

module AddrCalc #(
    parameter VEC_ID_W = 4,
    parameter STAGE_W = 3,
    parameter DATA_ADDR_W = 12,
    parameter ALLOC_LEN_W = 10,
    parameter REGFILE_ADDR_W = 5
)(
    input                           clk, rst, en, init,
    input      [2:0]                mode,
    input      [`ALLOCSET_W-1:0]    as_word,
    output                          is_end_of_vec, mrst_f,
    output reg [DATA_ADDR_W-1:0]    ram_addr_a, ram_addr_b,
    output reg [REGFILE_ADDR_W-1:0] raddr_a, raddr_b, raddr_d
);
    // Loading from register file into RAM and MAC
    localparam [2:0] C1 = 3'b000;
    // Loading result into register file from MAC
    localparam [2:0] C2 = 3'b001;
    // Loading error into register file from MAC
    localparam [2:0] C3 = 3'b010;
    // Vector convolution caclulation
    localparam [2:0] C4 = 3'b011;
    // ASC increment
    localparam [2:0] C5 = 3'b100;
    
    /* --- Allocation Set Struct --- */
    reg [VEC_ID_W-1:0] allocs_arr_id;
    reg [STAGE_W-1:0] allocs_stgs;
    reg [REGFILE_ADDR_W-1:0] allocs_resreg, allocs_errreg;
    reg [ALLOC_LEN_W-1:0] allocs_length;
    reg [DATA_ADDR_W-1:0] allocs_data_arr_ptr, allocs_coef_arr_ptr;
    /* ----------------------------- */
    
    // Register set of head addres for each massive
    reg [DATA_ADDR_W-1:0] head [0:11];
    
    // ???
    reg [ALLOC_LEN_W-1:0] vecnt;
    
    // Start memory reset flag
    reg st_rstmf = 1'b0;
    
    // Finish memory reset flag
    reg fi_rstmf = 1'b0;
    
    // Stage counter
    reg [STAGE_W-1:0] scnt;
    
    // Data massive end addres
    wire [DATA_ADDR_W-1:0] data_end_ptr;
    assign data_end_ptr = allocs_data_arr_ptr + allocs_length - 1;
    
    // Coefficient massive end addres
    wire [DATA_ADDR_W-1:0] coef_end_ptr;
    assign coef_end_ptr = allocs_coef_arr_ptr + allocs_length - 1;
    
    // Data tail addres flag
    wire dtail_f;
    assign dtail_f = (ram_addr_a == (head[allocs_arr_id] + 1));
    
    // Coefficient massive end addres flag
    wire cend_f;
    assign cend_f = (ram_addr_b == coef_end_ptr);
    
    // Head addres 
    
    integer i;
    initial
    begin
        `REG_RESET;
    end
    assign is_end_of_vec = cend_f;

    always @(posedge clk)
    begin
        if (!rst)
            if (en)
                if (!init)
                    case (mode)
                        C1:
                        begin
                            raddr_a    <= allocs_resreg;
                            raddr_b    <= allocs_errreg;
                            ram_addr_a <= head[allocs_arr_id];
                            ram_addr_b <= allocs_coef_arr_ptr;
                            st_rstmf   <= 1'b0;
                            fi_rstmf   <= 1'b0;
                        end
                        C2: 
                        begin
                            raddr_d <= allocs_resreg;
                            head[allocs_arr_id] <= (head[allocs_arr_id] == data_end_ptr)? `GND_BUS(DATA_ADDR_W) : head[allocs_arr_id] + 1;
                        end
                        C3: 
                        begin
                            raddr_d <= allocs_errreg;
                            scnt <= (scnt == allocs_stgs)? `GND_BUS(STAGE_W) : scnt + 1;
                            vecnt <= `GND_BUS(ALLOC_LEN_W);
                        end
                        C4:
                        begin
                            ram_addr_a <= (ram_addr_a == allocs_data_arr_ptr)? data_end_ptr : ram_addr_a - 1;
                            ram_addr_b <= ram_addr_b + 1;
                            assert_end(!(dtail_f^cend_f), 1'b1);
                        end
                        C5:
                        begin
                            if (!st_rstmf)
                            begin
                                ram_addr_a <= `GND_BUS(DATA_ADDR_W);
                                st_rstmf <= 1'b1;
                            end
                            else if (!fi_rstmf)
                            begin
                                {fi_rstmf, ram_addr_a} <= ram_addr_a + 1;
                            end
                            else
                            begin
                                st_rstmf <= 1'b0;
                            end
                        end
                        default:;
                    endcase
                else
                    `ALLOC_STRUCT <= as_word;
        else
        begin
            `REG_RESET;
        end
    end
    
    assign mrst_f = fi_rstmf;

endmodule
