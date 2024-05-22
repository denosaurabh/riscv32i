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




.globl _jal

_jal:
    li x5, 123456
    li x6, 123460
    li x7, 0              # count

    ecall print x5
    ecall print x6
    ecall print x7

    jal x2, inc


inc:
    addi x5, x5, 1
    addi x7, x7, 1

    ecall print x5
    ecall print x6
    ecall print x7

    beq x5, x6, print_jal
    jal x1, inc


print_jal:
    ecall print x7


