# Define the target executable name
TARGET = x.elf

# Define the source file
SRC = x.s

# Define the RISC-V GCC toolchain prefix
RISCV_PREFIX = riscv32-unknown-elf-

# Define the assembler and linker commands
AS = $(RISCV_PREFIX)gcc
LD = $(RISCV_PREFIX)gcc
OBJCOPY = $(RISCV_PREFIX)objcopy

# Define the build flags
ASFLAGS = -march=rv32i -mabi=ilp32 -c
LDFLAGS = -nostartfiles -nostdlib -T linker.ld -march=rv32i -mabi=ilp32

# Default rule to build the target
all: $(TARGET) rom.bin sram.bin

# Rule to assemble the source file into an object file
%.o: %.s
    $(AS) $(ASFLAGS) $< -o $@

# Rule to link the object file into the final executable
$(TARGET): $(SRC:.s=.o)
    $(LD) $^ -o $@ $(LDFLAGS)

# Rule to generate .bin files from .elf file
rom.bin: $(TARGET)
    $(OBJCOPY) -O binary --only-section=.text --only-section=.rodata $(TARGET) $@

sram.bin: $(TARGET)
    $(OBJCOPY) -O binary --only-section=.data --only-section=.bss $(TARGET) $@

# Clean rule to remove generated files
clean:
    rm -f $(SRC:.s=.o) $(TARGET) rom.bin sram.bin

.PHONY: all clean