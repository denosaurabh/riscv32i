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

    ret


print_jal:
    ecall print x7

