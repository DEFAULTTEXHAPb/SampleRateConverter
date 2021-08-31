`define GND_BUS(width) {width{1'b0}}

`define REG_RESET                                       \
    allocs_errreg       <= `GND_BUS(REGFILE_ADDR_W);    \
    allocs_resreg       <= `GND_BUS(REGFILE_ADDR_W);    \
    allocs_data_arr_ptr <= `GND_BUS(DATA_ADDR_W);       \
    allocs_coef_arr_ptr <= `GND_BUS(DATA_ADDR_W);       \
    allocs_length       <= `GND_BUS(ALLOC_LEN_W);       \
    vecnt               <= `GND_BUS(ALLOC_LEN_W);       \
    scnt                <= `GND_BUS(STAGE_W);           \
    ram_addr_a          <= `GND_BUS(DATA_ADDR_W);       \
    ram_addr_b          <= `GND_BUS(DATA_ADDR_W);       \
    raddr_a             <= `GND_BUS(REGFILE_ADDR_W);    \
    raddr_b             <= `GND_BUS(REGFILE_ADDR_W);    \
    raddr_d             <= `GND_BUS(REGFILE_ADDR_W);    \
    fi_rstmf            <= 1'b0;                        \
    st_rstmf            <= 1'b0;                        \
    for (i = 0; i < 6; i = i + 1)                       \
        head[i] <= `GND_BUS(DATA_ADDR_W)

`define ALLOC_STRUCT       \
{                          \
    allocs_stgs,           \
    allocs_arr_id,         \
    allocs_resreg,         \
    allocs_errreg,         \
    allocs_length,         \
    allocs_data_arr_ptr,   \
    allocs_coef_arr_ptr    \
}

`define ALLOCSET_W \
	STAGE_W + VEC_ID_W + 2*REGFILE_ADDR_W + ALLOC_LEN_W + 2*DATA_ADDR_W
