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
    input  wire       rst_n,             //! __Reset__
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

  reg [1:0] state = 2'b00;  //! State register

  wire assert_ptr_req = (req_complete == 1'b1)&&(iw_valid == 1'b1);

  //! Switch path
  always @(posedge clk) begin : state_machine
    if (rst_n == 1'b0) begin
      state <= PTR_REQ;
    end else if (en == 1'b1) begin
      case (state)
        PTR_REQ:
          if (assert_ptr_req == 1'b1)
            state <= CALC_INIT;
          else
            state <= PTR_REQ;
        CALC_INIT:
          state <= CALC;
        CALC:
          if (count_passed == 1'b1)
            state <= LOAD;
          else
            state <= CALC;
        LOAD:
          state <= PTR_REQ;
      endcase
    end
  end


  //! Output Moore FSM logic
  always @(*) begin : moore_output_logic
    en_fetch         = (state == PTR_REQ);
    ptrs_req         = (state == PTR_REQ);
    ringbuf_addr_clr = (state == PTR_REQ);
    en_init          = (state == CALC_INIT);
    mac_init         = (state == CALC_INIT);
    ringbuf_init     = (state == CALC_INIT);
    ena              = (((state == CALC_INIT) || (state == CALC)) == 1'b1);
    wea              = (state == CALC_INIT);
    en_calc          = (state == CALC);
    count            = (state == CALC);
    en_load          = (state == LOAD);
    regf_rd          = (state == CALC_INIT);
    regf_en          = (((state == CALC_INIT) || (state == LOAD))== 1'b1);
    regf_wr          = (state == LOAD);
  end

  //! Output Mealy FSM logic
  always @(*) begin : mealy_output_logic
    enb              = (((state == CALC_INIT) || (prog == 1'b1)) == 1'b1);
    web              = (prog == 1'b1);    
  end


endmodule
