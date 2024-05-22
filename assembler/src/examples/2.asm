.globl _start

_start:
    # Load immediate values into registers
    li t0, 5          # Load 5 into t0
    li t1, 10         # Load 10 into t1

    # Perform addition
    add t2, t0, t1    # t2 = t0 + t1 (5 + 10 = 15)

    # Perform subtraction
    sub t3, t1, t0    # t3 = t1 - t0 (10 - 5 = 5)

    # Check if t2 is equal to 15
    li t4, 15         # Load 15 into t4
    beq t2, t4, equal

    # Check if t3 is less than 10
    li t5, 10         # Load 10 into t5
    blt t3, t5, less_than

    # Check if t3 is greater than or equal to 10
    bge t3, t5, greater_or_equal

    # If no branch is taken, jump to the end
    j end

equal:
    # Set a register to indicate the result of the equal check
    li t6, 1          # Set t6 to 1 if t2 == 15
    j end

less_than:
    # Set a register to indicate the result of the less_than check
    li s10, 1          # Set t7 to 1 if t3 < 10
    j end

greater_or_equal:
    # Set a register to indicate the result of the greater_or_equal check
    li s9, 1          # Set t8 to 1 if t3 >= 10

end:
    # Exit the program
    li a7, 93         # ecall for exit
    li a0, 0          # Exit status 0
    ecall print t0
