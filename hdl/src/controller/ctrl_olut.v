
//!                                State Table
//! |Signals      |  S1   |  S2   |  S3   |  S4   |  S5   |  S6   |  S7   |  S8   |
//! |:-----------:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
//! |`pc_incr     `|   0   |   0   |   0   |   0   |   0   |   0   |   0   |_**1**_|
//! |`pc_clr      `|as prog|as prog|as prog|as prog|as prog|as prog|as prog|as prog|
//! |`fetch       `|_**1**_|   0   |   0   |   0   |   0   |   0   |   0   |   0   |
//! |`accum       `|   0   |   0   |_**1**_|   0   |   0   |   0   |   0   |   0   |
//! |`mac_init    `|   0   |_**1**_|   0   |   0   |   0   |   0   |   0   |   0   |
//! |`res_err     `|   0   |   0   |   0   |_**1**_|   0   |   0   |   0   |   0   |
//! |`wea         `|   0   |_**1**_|   0   |   0   |   0   |   0   |   0   |   0   |
//! |`web         `|as prog|as prog|as prog|as prog|as prog|as prog|as prog|as prog|
//! |`ena         `|   0   |_**1**_|_**1**_|   0   |   0   |   0   |   0   |   0   |
//! |`enb         `|   0   |   0   |_**1**_|   0   |   0   |   0   |   0   |   0   |
//! |`regf_rd     `|   0   |_**1**_|   0   |   0   |   0   |_**1**_|   0   |   0   |
//! |`regf_wr     `|   0   |   0   |   0   |_**1**_|_**1**_|   0   |   0   |   0   |
//! |`regf_en     `|   0   |_**1**_|   0   |_**1**_|_**1**_|_**1**_|   0   |   0   |
//! |`new_in      `|   0   |   0   |   0   |   0   |   0   |   0   |_**1**_|   0   |
//! |`new_out     `|   0   |   0   |   0   |   0   |   0   |_**1**_|   0   |   0   |
//! |`addr_clr    `|   0   |   0   |   0   |   0   |_**1**_|   0   |   0   |   0   |
//! |`header_init `|_**1**_|   0   |   0   |   0   |   0   |   0   |   0   |   0   |
//! |`ringbuf_init`|   0   |_**1**_|   0   |   0   |   0   |   0   |   0   |   0   |
//! |`coeff_load  `|   0   |_**1**_|   0   |   0   |   0   |   0   |   0   |   0   |
//! |`cnt         `|   0   |   0   |_**1**_|   0   |   0   |   0   |   0   |   0   |
//! |`head_read   `|   0   |_**1**_|   0   |   0   |   0   |   0   |   0   |   0   |
//! |`head_incr   `|   0   |   0   |   0   |_**1**_|   0   |   0   |   0   |   0   |
//! |`w_r         `|   0   |   0   |   0   |_**1**_|   0   |   0   |   0   |   0   |

module ctrl_olut (
    input  wire [2:0] fsm_state,
    input  wire       prog,

    // Programm counter driving
    output wire       pc_clr,
    output wire       pc_incr,
    output wire       fetch,

    // MAC (and Register file addrsess calculator) driving
    output wire       accum,
    output wire       mac_init,
    output wire       res_err,
    output wire       w_r,

    // Dual-Port RAM driving
    output wire       wea,
    output wire       web,
    output wire       ena,
    output wire       enb,

    // Register file driving
    output wire       regf_rd,
    output wire       regf_wr,
    output wire       regf_en,

    // Audio I/O gates driving
    output wire       new_in,
    output wire       new_out,

    // Dual-Port RAM Address calculator driving
    output wire       addr_clr,
    output wire       header_init,
    output wire       ringbuf_init,
    output wire       coeff_load,
    output wire       cnt,
    output wire       head_read,
    output wire       head_incr
  );

  localparam [2:0] S1 = 3'b000;  //! Memory allocation
  localparam [2:0] S2 = 3'b001;  //! Load sample from regfile to RAM and initialize MAC
  localparam [2:0] S3 = 3'b010;  //! Vector convolution on MAC
  localparam [2:0] S4 = 3'b011;  //! Load result from MAC to register file
  localparam [2:0] S5 = 3'b100;  //! Load error from MAC to register file
  localparam [2:0] S6 = 3'b101;  //! Load system output sample
  localparam [2:0] S7 = 3'b110;  //! Load new sapmle from audio bus
  localparam [2:0] S8 = 3'b111;  //! Allocation list counter increment

  assign pc_incr      = (fsm_state == S8);
  assign fetch        = (fsm_state == S1);
  assign accum        = (fsm_state == S3);
  assign mac_init     = (fsm_state == S2);
  assign res_err      = (fsm_state == S4);
  assign wea          = (fsm_state == S2);
  assign web          = (prog == 1'b1);
  assign pc_clr       = (prog == 1'b1);
  assign ena          = ((fsm_state == S2)|(fsm_state == S3));
  assign enb          = (fsm_state == S3);
  assign regf_rd      = ((fsm_state == S2)|(fsm_state == S6));
  assign regf_wr      = ((fsm_state == S4)|(fsm_state == S5));
  assign regf_en      = ((fsm_state == S2)|(fsm_state == S4)|(fsm_state == S5)|(fsm_state == S6));
  assign new_in       = (fsm_state == S7);
  assign new_out      = (fsm_state == S6);
  assign addr_clr     = (fsm_state == S5);
  assign header_init  = (fsm_state == S1);
  assign ringbuf_init = (fsm_state == S2);
  assign coeff_load   = (fsm_state == S2);
  assign cnt          = (fsm_state == S3);
  assign head_read    = (fsm_state == S2);
  assign head_incr    = (fsm_state == S4);


endmodule
