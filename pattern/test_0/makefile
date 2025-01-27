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
all: $(TARGET) rom.bin sram.bin copy

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

# Rule to copy the .bin files to the specified directory
copy: rom.bin sram.bin
    if [ -f ../ram_init_file/rom.bin ]; then rm ../ram_init_file/rom.bin; fi
    if [ -f ../ram_init_file/sram.bin ]; then rm ../ram_init_file/sram.bin; fi
    cp rom.bin ../ram_init_file/
    cp sram.bin ../ram_init_file/

# Clean rule to remove generated files
clean:
    rm -f $(SRC:.s=.o) $(TARGET) rom.bin sram.bin
    rm -f ../ram_init_file/rom.bin ../ram_init_file/sram.bin

.PHONY: all clean copy