`timescale 1ps/1ps
`default_nettype none

module block_dual_port_ram #(
    parameter ADDR_WIDTH = 12,
              DATA_WIDTH = 32
)(
    // Port A
    input   wire                        clka,
    input   wire                        rsta,
    input   wire                        ena,
    input   wire                        wea,
    input   wire  [ADDR_WIDTH - 1 : 0]  addra,
    input   wire  [DATA_WIDTH - 1 : 0]  dina,
    output  reg   [DATA_WIDTH - 1 : 0]  douta,
    // Port B
    input   wire                        clkb,
    input   wire                        rstb,
    input   wire                        enb,
    input   wire                        web,
    input   wire  [ADDR_WIDTH - 1 : 0]  addrb,
    input   wire  [DATA_WIDTH - 1 : 0]  dinb,
    output  reg   [DATA_WIDTH - 1 : 0]  doutb
);

    localparam RESETVAL = {DATA_WIDTH{1'b0}};
    integer i;

    reg [DATA_WIDTH - 1 : 0] memblock [0 : 2 ** ADDR_WIDTH - 1];

    initial
    begin
`ifdef INIT_STATE_CHECK
        for (i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
            memblock[i] = RESETVAL;
        end
`else
        $readmemh("ram_init.txt", memblock);
`endif
    end

    always @(posedge clka)
    begin
        if (rsta)
        begin
            douta <= RESETVAL;
        end
        else if (wea && ena)
        begin
            memblock[addra] <= dina;
        end
        else
        begin
            douta <= memblock[addra];
        end
    end

    always @(posedge clkb)
    begin
        if (rstb)
        begin
            doutb <= RESETVAL;
        end
        else if (web && enb)
        begin
            memblock[addrb] <= dinb;
        end
        else
        begin
            doutb <= memblock[addrb];
        end
    end
endmodule