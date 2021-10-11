//! @title Coefficient address counter
//! @brief Counter for coefficient address
//! If `load` flag is active-high `coef_addr`
//! is set with value `coef_ptr` for coeffi-
//! cient downloading from CPU

module ctrl_ramdrv_coefcnt #(
    parameter integer ADDR_WIDTH = 12
) (
    input  wire                  clk,      //! __Clock__
    input  wire                  clr,      //! __Reset__
    input  wire                  load,     //! Coefficient load flag (and initial counter value set flag)
    input  wire                  cnt,      //! Counting enable
    input  wire [ADDR_WIDTH-1:0] coef_ptr, //! Initial coefficient pointer
    output wire [ADDR_WIDTH-1:0] coef_addr //! Output coefficient address
);
    
    //! Counter register
    reg [ADDR_WIDTH-1:0] coef_cnt = {ADDR_WIDTH{1'b0}};

    assign coef_addr = coef_cnt;

    //! Counting process with counter value set
    always @(negedge clk) begin : coef_offset_counting
      if (clr == 1'b1) begin
        coef_cnt <= {ADDR_WIDTH{1'b0}};
      end else if (load == 1'b1) begin
        coef_cnt <= coef_ptr;
      end if (cnt == 1'b1) begin
        coef_cnt <= coef_cnt + 1'b1;
      end
    end

endmodule