objdump 是一个用于显示二进制文件信息的工具。它是 GNU Binutils 工具集的一部分。以下是 objdump 常用的参数说明：

常用参数
-a or --archive-headers：显示归档成员的头信息。
-d or --disassemble：反汇编可执行代码。
-D or --disassemble-all：反汇编所有部分，不仅仅是可执行代码。
-b or --target=bfdname：指定目标文件的格式。
-f or --file-header：显示目标文件的头信息。
-h or --section-headers or --headers：显示文件头信息。
-i or --info：显示BFD（Binary File Descriptor）库支持的所有目标和体系结构。
-j or --section=name：只显示指定的部分。
-l or --line-numbers：与反汇编输出一起，显示行号信息。
-r or --reloc：显示重定位信息。
-s or --full-contents：显示文件所有部分的完整内容。
-t or --syms：显示符号表。
-T or --dynamic-syms：显示动态符号表。
-g or --debugging：显示调试信息。
-e or --debugging-tags：显示调试信息（使用 DWARF 标签）。
-G or --stabs：显示调试信息（使用 stabs）。
-V or --version：显示版本信息并退出。
-x or --all-headers：显示所有头信息。
-w or --wide：不要截断输出信息。
-z or --disassembler-options=options：传递特定选项给反汇编器。

示例用法
反汇编一个 ELF 文件：

```bash
objdump -d program.elf
```

反汇编并显示行号：
```bash
objdump -d -l program.elf
```

显示文件头信息：
```bash
objdump -f program.elf
```
显示所有部分的内容：
```bash
objdump -s program.elf
```
显示符号表：
```bash
objdump -t program.elf
```

指定部分进行反汇编：
```bash
objdump -d -j .text program.elf
```

生成汇编和机器码对应的文档
你可以使用 objdump 生成汇编和机器码对应的文档，并将其写入 .txt 文件。例如：
```bash
objdump -d program.elf > program.txt
```

# 不用伪指令，不用寄存器别名，方便 inst debug

要确保 objdump 在反汇编时不使用伪指令和寄存器别名（例如 ra, sp 等），你可以结合使用 -M no-aliases 和 -M numeric 选项。-M numeric 选项将寄存器显示为数字，而不是别名。

以下是具体步骤：

步骤 1: 编写汇编代码
编写一个简单的汇编代码文件，例如 example.s：

Assembly
.section .text
.global _start

_start:
    li x1, 0x10
步骤 2: 编译汇编代码
使用 riscv64-unknown-elf-as 将汇编代码编译成目标文件：

sh
riscv64-unknown-elf-as -o example.o example.s
步骤 3: 链接目标文件
使用 riscv64-unknown-elf-ld 将目标文件链接成可执行文件：

sh
riscv64-unknown-elf-ld -o example example.o
步骤 4: 生成反汇编文件
使用 objdump 生成反汇编文件，并禁用伪指令别名和寄存器别名：

sh
riscv64-unknown-elf-objdump -d -M no-aliases,numeric example > example.txt
查看生成的反汇编文件
打开生成的 example.txt 文件，你应该会看到实际的机器指令和数字形式的寄存器名称：

plaintext
example:     file format elf64-littleriscv

Disassembly of section .text:

0000000000000000 <_start>:
   0:   01000113                addi    x1, x0, 16
在这个示例中，li x1, 0x10 被翻译成了 addi x1, x0, 16，并且寄存器名称使用 x1, x0 等数字形式，而不是别名。

总结
通过使用 objdump 的 -M no-aliases,numeric 选项，你可以生成包含实际寄存器名称和机器指令的反汇编文件，而不是伪指令别名和寄存器别名。这种方法有助于更好地理解和调试汇编代码。