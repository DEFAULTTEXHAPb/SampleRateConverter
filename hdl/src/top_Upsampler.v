`define GND_BUS(width) {width{1'b0}}
module top_Upsampler #(
    parameter DATA_WIDTH = 32
)(
    input wire clk, rst, en, init, rempty,
    input wire                  new_sample_valid,
    input wire [DATA_WIDTH-1:0] new_sample, coe_init,
    input wire [56 : 0]         vech_init,
    input wire [5 : 0]               calc_prog_init,
    output wire                  out_sample_valid,
    output reg [DATA_WIDTH-1:0] out_sample,
    output wire                          error_code
);

    wire acc_ovr, mult_ovr, out_valid, mac_init;
    wire [56 : 0] vech, mod_vech, get_vech;
    wire [5 : 0]  vechptr;
    wire [9 : 0]  pc;
    wire [5 : 0]  weword;
    wire [6 : 0]  enword;
    wire [11 : 0]  addrd, addrc;                                                  
    wire [2 : 0]  addrr, addre;
    wire          rinc;
    wire [DATA_WIDTH-1:0]  data, coe, acc_initval, get_res;
    wire [DATA_WIDTH:0] res, err;
    wire [DATA_WIDTH-1:0] ddina = (rinc && new_sample_valid)? new_sample : get_res;

    assign out_sample_valid = out_valid;
    assign get_vech = (init)? vech_init : mod_vech;

    always @(posedge clk) begin
      if (rst) begin
        out_sample <= `GND_BUS(DATA_WIDTH);
      end if (out_sample_valid) begin
        out_sample <= res;
      end
    end
                                                  

    controller #(
      .DADDR_WIDTH(12),
      .RADDR_WIDTH(3),
      .VECH_WIDTH(57),
      .MAX_STAGES(6),
      .VHPADDR_WIDTH(10)
    )
    system_fsm
    (
      .clk              (clk),
      .rst              (rst),
      .en               (en),
      .init             (init),
      .rempty           (rempty),
      .acc_ovr          (acc_ovr),
      .mult_ovr         (mult_ovr),
      .vech             (vech   ),
      .mod_vech         (mod_vech),
      .pc               (pc),
      .out_data_valid   (out_valid),
      .mac_init         (mac_init),
      .rinc             (rinc),
      .weword           (weword),
      .enword           (enword),
      .addrd            (addrd),
      .addrc            (addrc),
      .addrr            (addrr),
      .addre            (addre),
      .error_code       (error_code)
    );

  `ifndef XILINX_SIMULATOR

    block_dual_port_ram #(
      .ADDR_WIDTH(12),
      .DATA_WIDTH(32)
    ) coe_data_ram (
      // Data port
      .clka     (clk        ),     // input wire clka
      .rsta     (rst        ),     // input wire rsta
      .ena      (enword[0]  ),     // input wire ena
      .wea      (weword[0]  ),     // input wire [0 : 0] wea
      .addra    (addrd      ),     // input wire [11 : 0] addra
      .dina     (ddina      ),     // input wire [31 : 0] dina
      .douta    (data       ),     // output wire [31 : 0] douta
      // Coef port
      .clkb     (clk        ),     // input wire clkb
      .rstb     (rst        ),     // input wire rstb
      .enb      (enword[1]  ),     // input wire enb
      .web      (weword[1]  ),     // input wire [0 : 0] web
      .addrb    (addrc      ),     // input wire [11 : 0] addrb
      .dinb     (coe_init   ),     // input wire [31 : 0] dinb
      .doutb    (coe        )      // output wire [31 : 0] doutb
    );
    
    block_dual_port_ram #(
      .ADDR_WIDTH(3),
      .DATA_WIDTH(33)
    ) res_err_ram (
      // Result port
      .clka     (clk        ),     // input wire clka
      .rsta     (rst        ),     // input wire rsta
      .ena      (enword[2]  ),     // input wire ena
      .wea      (weword[2]  ),     // input wire [0 : 0] wea
      .addra    (addrr      ),     // input wire [2 : 0] addra
      .dina     (res       ),     // input wire [31 : 0] dina
      .douta    (get_res   ),     // output wire [31 : 0] douta
      // Error port
      .clkb     (clk        ),     // input wire clkb
      .rstb     (rst        ),     // input wire rstb
      .enb      (enword[3]  ),     // input wire enb
      .web      (weword[3]  ),     // input wire [0 : 0] web
      .addrb    (addre      ),     // input wire [2 : 0] addrb
      .dinb     (err        ),     // input wire [31 : 0] dinb
      .doutb    (acc_initval)      // output wire [31 : 0] doutb
    );
    
    block_singal_port_ram #(
      .ADDR_WIDTH(6),
      .DATA_WIDTH(57)
    ) vectorp_ram (
      .clka     (clk        ),     // input wire clka
      .rsta     (rst        ),     // input wire rsta
      .ena      (enword[4]  ),     // input wire ena
      .wea      (weword[4]  ),     // input wire [0 : 0] wea
      .addra    (vechptr    ),     // input wire [5 : 0] addra
      .dina     (get_vech   ),     // input wire [41 : 0] dina
      .douta    (vech       )      // output wire [41 : 0] douta
    );
    
    block_singal_port_ram #(
      .ADDR_WIDTH(10),
      .DATA_WIDTH(6)
    ) calc_order_prog_ram (
      .clka     (clk     ),     // input wire clka
      .rsta     (rst     ),     // input wire rsta
      .ena      (enword[5]  ),     // input wire ena
      .wea      (weword[5]  ),     // input wire [0 : 0] wea
      .addra    (pc      ),     // input wire [9 : 0] addra
      .dina     (calc_prog_init),     // input wire [5 : 0] dina
      .douta    (vechptr   )      // output wire [5 : 0] douta
    );

  `else

    blk_mem_gen_0 coe_data_ram (
      // Data port
      .clka     (clk        ),     // input wire clka
      .rsta     (rst        ),     // input wire rsta
      .ena      (enword[0]  ),     // input wire ena
      .wea      (weword[0]  ),     // input wire [0 : 0] wea
      .addra    (addrd      ),     // input wire [11 : 0] addra
      .dina     (ddina      ),     // input wire [31 : 0] dina
      .douta    (data       ),     // output wire [31 : 0] douta
      // Coef port
      .clkb     (clk        ),     // input wire clkb
      .rstb     (rst        ),     // input wire rstb
      .enb      (enword[1]  ),     // input wire enb
      .web      (weword[1]  ),     // input wire [0 : 0] web
      .addrb    (addrc      ),     // input wire [11 : 0] addrb
      .dinb     (coe_init   ),     // input wire [31 : 0] dinb
      .doutb    (coe        )      // output wire [31 : 0] doutb
    );
    
    blk_mem_gen_1 res_err_ram (
      // Result port
      .clka     (clk        ),     // input wire clka
      .rsta     (rst        ),     // input wire rsta
      .ena      (enword[2]  ),     // input wire ena
      .wea      (weword[2]  ),     // input wire [0 : 0] wea
      .addra    (addrr      ),     // input wire [2 : 0] addra
      .dina     (res       ),     // input wire [31 : 0] dina
      .douta    (get_res   ),     // output wire [31 : 0] douta
      // Error port
      .clkb     (clk        ),     // input wire clkb
      .rstb     (rst        ),     // input wire rstb
      .enb      (enword[3]  ),     // input wire enb
      .web      (weword[3]  ),     // input wire [0 : 0] web
      .addrb    (addre      ),     // input wire [2 : 0] addrb
      .dinb     (err        ),     // input wire [31 : 0] dinb
      .doutb    (acc_initval)      // output wire [31 : 0] doutb
    );
    
    blk_mem_gen_2 vectorp_ram (
      .clka     (clk        ),     // input wire clka
      .rsta     (rst        ),     // input wire rsta
      .ena      (enword[4]  ),     // input wire ena
      .wea      (weword[4]  ),     // input wire [0 : 0] wea
      .addra    (vechptr    ),     // input wire [5 : 0] addra
      .dina     (get_vech   ),     // input wire [41 : 0] dina
      .douta    (vech       )      // output wire [41 : 0] douta
    );
    
    blk_mem_gen_3 calc_order_prog_ram (
      .clka     (clk     ),     // input wire clka
      .rsta     (rst     ),     // input wire rsta
      .ena      (enword[5]  ),     // input wire ena
      .wea      (weword[5]  ),     // input wire [0 : 0] wea
      .addra    (pc      ),     // input wire [9 : 0] addra
      .dina     (calc_prog_init),     // input wire [5 : 0] dina
      .douta    (vechptr   )      // output wire [5 : 0] douta
    );
  
  `endif
    
    MAC #(
      .IN_DATA_WIDTH(DATA_WIDTH),
      .OUT_DATA_WIDTH(DATA_WIDTH+1)
    )
    mac_core
    (
      .op1          (data       ),
      .op2          (coe        ),
      .acc_initval  (acc_initval),
      .clk          (clk        ),
      .sclr         (rst        ),
      .cen          (enword[6]),
      .odata_valid  (out_valid),
      .mac_init     (mac_init),
      .res          (res),
      .err          (err),
      .mult_ovr     (mult_ovr),
      .acc_ovr      (acc_ovr)
    );
    
endmodule
