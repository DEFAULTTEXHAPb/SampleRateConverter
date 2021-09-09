
module regFile(
    input  [31:0]  Ip1,
    input  [3:0]   sel_i1,
    output [31:0]  Op1,
    input  [3:0]   sel_o1,
    output [31:0]  Op2,
    input  [3:0]   sel_o2,
    input          RD, WR,
    input          rst,
    input          EN,
    input          clk
);      
       
    reg [31:0]  regFile [0:15];
    integer i;

    always @ (posedge clk) begin
 if (EN == 1) begin
  if (rst == 1) //If at reset 

   begin 

   for (i = 0; i < 16; i = i + 1) begin

    regFile [i] = 32'h0; 

   end 

   Op1 = 32'hx; 

   end 

  else if (rst == 0) //If not at reset 

   begin 

   case ({RD,WR}) 

    2'b00:  begin 

     end 

    2'b01:  begin //If Write only 

     regFile [sel_i1] = Ip1; 

     end 

    2'b10:  begin //If Read only 

     Op1 = regFile [sel_o1]; 

     Op2 = regFile [sel_o2]; 

     end 

    2'b11:  begin //If both active 

     Op1 = regFile[sel_o1]; 

     Op2 = regFile [sel_o2]; 

     regFile [sel_i1] = Ip1; 

     end 

    default: begin //If undefined 

      end 

   endcase 

   end 

  else; 

 end
 else;
end 

endmodule



`define GND_BUS(width) {width{1'b0}}
module RegFile #(
    parameter DATA_WIDTH = 32,
    parameter REGFILE_ADDR_W = 5
) (
    input clk, rst, en,
    input rw,
    input [REGFILE_ADDR_W-1:0] a_ra, a_rb, a_rd,
    input [DATA_WIDTH-1:0] rd,
    output reg [DATA_WIDTH-1:0] ra, rb
);

    reg [DATA_WIDTH-1:0] rfile [0:2**REGFILE_ADDR_W-1];

    integer i;
    initial begin
        ra = `GND_BUS(DATA_WIDTH);
        rb = `GND_BUS(DATA_WIDTH);
        for (i = 0; i < 2**REGFILE_ADDR_W; i = i + 1) begin
            rfile[i] = `GND_BUS(DATA_WIDTH);
        end
    end

    always @(posedge clk)
    begin
        if (!rst)
            if (en)
            begin
                if (!rw)
                    rfile[a_rd] <= rd;
                else
                begin
                    ra <= rfile[a_ra];
                    rb <= rfile[a_rb];
                end
            end
        else
        begin
            ra <= `GND_BUS(DATA_WIDTH);
            rb <= `GND_BUS(DATA_WIDTH);
        end
    end
    
endmodule