`ifndef OPCODE_V
`define OPCODE_V

parameter [1:0] OP_R_TYPE       = 4'b0001,
                OP_I_TYPE       = 4'b0010,
                OP_S_TYPE       = 4'b0011,
                OP_B_TYPE       = 4'b0100;
                OP_U_TYPE       = 4'b0101;
                OP_J_TYPE       = 4'b0111;
                OP_ECALL_TYPE   = 4'b0000;
`endif
