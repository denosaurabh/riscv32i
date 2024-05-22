# lui x10, 0x1D20
# addi x10, x10, 0xA5 
# ecall print x10
# jal x1, -12
# jalr x2, -12(x3)


# .globl main

# lui x5, 4

# Example JAL instruction
# jal x1, -12 # target    # Jump to 'target' and store return address in x1

# Code after JAL (this will be skipped initially due to the jump)
# addi x5, x5, 1    # x5 = x5 + 1 (should not be executed immediately)






.globl _start

_start:
    # Initialize registers
    li x5, 123456         # x5 = 0
    # lui x5, 0

    ecall print x5

