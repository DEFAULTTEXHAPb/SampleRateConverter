typedef struct allocInstr {
    bool     lstg_f;
    bool     upse_f;
    uint8_t  vector_id;
    uint8_t  result_reg;
    uint8_t  error_reg;
    uint16_t vector_len;
    uint16_t data_ptr;
    uint16_t coef_ptr;
} TAllocInstr;