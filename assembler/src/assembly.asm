.globl _start

_start:
    li x6 12345
    li x7 456

    add x8 x6 x7

    ecall print x8

