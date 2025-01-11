# x.s - Simple RISC-V Assembly Program to Test RV32I Core

.section .data
# Data section (if needed)

.section .text
.globl _start

_start:
    # Initialize registers
    li x1, 10       # Load immediate 10 into x1
    li x2, 20       # Load immediate 20 into x2

    # Perform arithmetic operations
    add x3, x1, x2  # x3 = x1 + x2
    sub x4, x2, x1  # x4 = x2 - x1
    and x5, x1, x2  # x5 = x1 & x2
    or  x6, x1, x2  # x6 = x1 | x2
    xor x7, x1, x2  # x7 = x1 ^ x2

    # Store results to memory (if needed)
    # sw x3, 0(x0)  # Store x3 to memory address 0 (example)
    # sw x4, 4(x0)  # Store x4 to memory address 4 (example)

    # End program
    loop:
        j loop      # Infinite loop to halt the CPU

# End of program