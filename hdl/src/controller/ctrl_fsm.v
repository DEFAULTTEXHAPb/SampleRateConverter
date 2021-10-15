//! State Table
//! |Output Signals    |PTR_REQ| CINIT |  CALC | LOAD  |
//! |:----------------:|:-----:|:-----:|:-----:|:-----:|
//! |`en_fetch        `|_**1**_|   0   |   0   |   0   |
//! |`ptrs_req        `|_**1**_|   0   |   0   |   0   |
//! |`ringbuf_addr_clr`|_**1**_|   0   |   0   |   0   |
//! |`en_init         `|   0   |_**1**_|   0   |   0   |
//! |`mac_init        `|   0   |_**1**_|   0   |   0   |
//! |`ringbuf_init    `|   0   |_**1**_|   0   |   0   |
//! |`regf_rd         `|   0   |_**1**_|   0   |   0   |
//! |`regf_en         `|   0   |_**1**_|   0   |_**1**_|
//! |`ena             `|   0   |_**1**_|_**1**_|   0   |
//! |`wea             `|   0   |_**1**_|   0   |   0   |
//! |`enb             `| prog  |_**1**_| prog  | prog  |
//! |`en_calc         `|   0   |   0   |_**1**_|   0   |
//! |`count           `|   0   |   0   |_**1**_|   0   |
//! |`en_load         `|   0   |   0   |   0   |_**1**_|
//! |`regf_wr         `|   0   |   0   |   0   |_**1**_|
//! |`web             `| prog  | prog  | prog  | prog  |


//! @title Controller FSM
//! @brief This is Finite State Machine for Controller
//! with 4 states. It allows to manage data flow of 
//! upsampling process

module ctrl_fsm (
    input  wire       clk,             //! __Clock__
    input  wire       rst,             //! __Reset__
    input  wire       en,              //! __Clock enable__
    input  wire       req_complete,    //! Pointer Struct request complete flag
    input  wire       iw_valid,        //! Pointer Struct content valid
    input  wire       count_passed,    //! Convolution Counting passed flag
    input  wire       prog,            //! Coefficient Load flag
    //input  wire       new_out,         //! Sample out flag
    //input  wire       new_in,          //! Sample in flag

    // Pointer struct request active-high signals
    output reg       en_fetch,         //! main enable flag for Pointer struct request
    output reg       ptrs_req,         //! next pointer struct request signal
    output reg       ringbuf_addr_clr, //! Ring buffer address register clear

    // MAC and RAM precalculation initialization active-high signals
    output reg       en_init,          //! main enable flag for calculation initialization
    output reg       mac_init,         //! MAC accumulator initialization
    output reg       ringbuf_init,     //! Ring buffer initialization
    output reg       regf_rd,          //! Register file read enable signal
    output reg       regf_en,          //! Clock Enable of register file (also active-high in load state)
    output reg       ena,              //! Data RAM clock enable for sample port (also active-high in calc state)
    output reg       wea,              //! Data RAM write enable for sample port
    output reg       enb,              //! Data RAM clock enable for coefficient port (also active-high in prog state)

    // Calculation active-high signals
    output reg       en_calc,          //! main enable flag for convolution calculation
    output reg       count,            //! Count process flag

    // Load Result active-high signals
    output reg       en_load,          //! main enable flag for result loading
    output reg       regf_wr,          //! Write Enable of register file

    // Coefficient loading active-high signals
    output reg       web               //! Data RAM write enable for coefficient port

);

  localparam [1:0] PTR_REQ   = 2'b00; //! Pointer Struct Request
  localparam [1:0] CALC_INIT = 2'b01; //! Convolution Calculation Initialization
  localparam [1:0] CALC      = 2'b11; //! Convolution Calculation
  localparam [1:0] LOAD      = 2'b10; //! Load Result

  reg [1:0] cstate = 2'b00;  //! Current state register
  reg [1:0] nstate = 2'b00;  //! Next state register

`ifndef ONE_HOT

  //! Next state logic
  always @(posedge clk) begin : state_switching
    if (!rst) begin
      cstate <= ((en == 1'b1)||(prog == 1'b0)) ? nstate : cstate;
    end else begin
      cstate <= PTR_REQ;
    end
  end

  //! Switch path
  always @(*) begin : next_state_switching_predition
    case (cstate)
      PTR_REQ:   nstate = ((req_complete == 1'b1)&&(iw_valid == 1'b1)) ? CALC_INIT : PTR_REQ;
      CALC_INIT: nstate = CALC;
      CALC:      nstate = (count_passed == 1'b1) ? LOAD : CALC;
      LOAD:      nstate = PTR_REQ;
    endcase
  end

`else

  always @(posedge clk) begin : state_machine
    case (cstate)
      PTR_REQ: begin
        if ((req_complete == 1'b1)&&(iw_valid == 1'b1)) begin
          cstate <= CALC_INIT;
        end else begin
          cstate <= PTR_REQ;
        end
      end
      CALC_INIT: cstate <= CALC;
      CALC: begin
        if (count_passed == 1'b1) begin
          cstate <= LOAD;
        end else begin
          cstate <= CALC;
        end
      end
      LOAD:      cstate <= PTR_REQ;
    endcase
  end

`endif

  //! Output Moore FSM logic
  always @(*) begin : moore_output_logic
    en_fetch         = (cstate == PTR_REQ);
    ptrs_req         = (cstate == PTR_REQ);
    ringbuf_addr_clr = (cstate == PTR_REQ);
    en_init          = (cstate == CALC_INIT);
    mac_init         = (cstate == CALC_INIT);
    ringbuf_init     = (cstate == CALC_INIT);
    ena              = (((cstate == CALC_INIT) || (cstate == CALC)) == 1'b1);
    wea              = (cstate == CALC_INIT);
    en_calc          = (cstate == CALC);
    count            = (cstate == CALC);
    en_load          = (cstate == LOAD);
    regf_rd          = (cstate == CALC_INIT);
    regf_en          = (((cstate == CALC_INIT) || (cstate == LOAD))== 1'b1);
    regf_wr          = (cstate == LOAD);
  end

  //! Output Mealy FSM logic
  always @(*) begin : mealy_output_logic
    enb              = (((cstate == CALC_INIT) || (prog == 1'b1)) == 1'b1);
    web              = (prog == 1'b1);    
  end


endmodule
