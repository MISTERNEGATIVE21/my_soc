# Makefile for assembling, linking, and generating an executable binary and memory file for RV32I core

# Toolchain and flags
AS = riscv32-unknown-elf-as
LD = riscv32-unknown-elf-ld
OBJCOPY = riscv32-unknown-elf-objcopy
OBJDUMP = riscv32-unknown-elf-objdump
CFLAGS = -march=rv32i -mabi=ilp32
LDFLAGS = -T linker.ld

# Source and output files
SRCS = $(wildcard *.s)
OBJS = $(SRCS:.s=.o)
BIN = x.bin
HEX = x.hex
DUMP = x.dump

# Default target
all: $(BIN) $(HEX) $(DUMP)

# Rule to assemble the source files
%.o: %.s
    $(AS) $(CFLAGS) $< -o $@

# Rule to link the object files and create the binary
$(BIN): $(OBJS)
    $(LD) $(LDFLAGS) $(OBJS) -o $@ -e 0 -Ttext 0x0

# Rule to generate the hexadecimal memory file
$(HEX): $(BIN)
    $(OBJCOPY) -O verilog $< $@

# Rule to generate the disassembly of the binary
$(DUMP): $(BIN)
    $(OBJDUMP) -d $< > $@

# Clean up generated files
clean:
    rm -f $(OBJS) $(BIN) $(HEX) $(DUMP)

# Phony targets
.PHONY: all clean