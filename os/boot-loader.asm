.section .data   

# .word RAM_START 0x80000000

.word KERNEL_START 0x00010000
.word KERNEL_SIZE 0x00010000




.section .text   

.global _start


_start:
    # initialize CPU Register & Stack Pointer
    # configure MMU
    # initialize I/O - Keyboard & Display


    j KERNEL_START          # maybe, use `tail`


