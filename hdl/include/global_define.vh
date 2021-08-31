`define VEC_ID_W 4
`define DATA_ADDR_W 12
`define ALLOC_LEN_W 10
`define REGFILE_ADDR_W 5
`define PROG_SIZE 16
`define ALLOC_INSTR_W 1+1+`VEC_ID_W+2*`REGFILE_ADDR_W+`ALLOC_LEN_W+2*`DATA_ADDR_W
`define GND_BUS(width) {width{1'b0}}