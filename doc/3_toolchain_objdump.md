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