
# riscv64-unknown-elf-gcc


riscv64-unknown-elf-gcc 是用于编译 RISC-V 目标的 GNU 编译器。以下是一些常用参数的说明：

常用参数
输入和输出文件
-c：编译源文件而不进行链接。
-o <file>：指定输出文件名。
-S：将源代码编译成汇编代码。
-E：仅预处理，不进行编译。
-I<dir>：添加头文件搜索路径。

预处理器选项
-D<macro>：定义一个宏。
-U<macro>：取消定义一个宏。
-include <file>：在编译每个源文件之前，先包含指定的文件。

编译器选项
-O<n>：设置优化等级（0, 1, 2, 3, s, fast）。
-g：生成调试信息。
-Wall：启用所有常见的警告。
-Werror：将所有警告视为错误。
-std=<standard>：指定使用的 C/C++ 标准（如 c99, c11, c++11）。
-f<feature>：启用或禁用特定编译特性（如 -fPIC）。

链接器选项
-L<dir>：添加库文件搜索路径。
-l<library>：链接指定的库。
-T <script>：使用指定的链接脚本。
-nostartfiles：不使用标准启动文件。
-nodefaultlibs：不使用默认库。
-nostdlib：不使用标准库或启动文件。
-static：生成静态链接的可执行文件。

代码生成选项
-march=<arch>：指定目标架构（如 rv32im, rv64gc）。
-mabi=<abi>：指定目标 ABI（如 ilp32, lp64）。

其他选项
--version：显示编译器版本信息并退出。
--help：显示帮助信息并退出。

示例用法
编译 C 源文件为目标文件：

bash
riscv64-unknown-elf-gcc -c main.c -o main.o

编译并链接生成可执行文件：
bash
riscv64-unknown-elf-gcc main.c -o main.elf
生成汇编代码：

bash
riscv64-unknown-elf-gcc -S main.c -o main.s

添加头文件和库文件路径：
bash
riscv64-unknown-elf-gcc -I/path/to/includes -L/path/to/libs -lmy_library main.c -o main.elf

使用特定的目标架构和 ABI：
bash
riscv64-unknown-elf-gcc -march=rv64gc -mabi=lp64 main.c -o main.elf

生成带有调试信息的可执行文件：
bash
riscv64-unknown-elf-gcc -g main.c -o main.elf

通过这些参数，你可以灵活地使用 riscv64-unknown-elf-gcc 来编译和链接 RISC-V 目标的程序。根据你的具体需求，选择适合的参数组合。


# diff with gcc

riscv64-unknown-elf-gcc 和一般的 gcc 编译选项基本是一样的，主要区别在于目标架构和目标 ABI 的指定。以下是一些常见的编译选项以及它们在 riscv64-unknown-elf-gcc 中的使用：

常见编译选项
-c：编译源文件但不进行链接。
-o <file>：指定输出文件名。
-S：将源代码编译成汇编代码。
-E：仅预处理，不进行编译。
-I<dir>：添加头文件搜索路径。
预处理器选项
-D<macro>：定义一个宏。
-U<macro>：取消定义一个宏。
-include <file>：在编译每个源文件之前，先包含指定的文件。
优化选项
-O<n>：设置优化等级（0, 1, 2, 3, s, fast）。
-g：生成调试信息。
-Wall：启用所有常见的警告。
-Werror：将所有警告视为错误。
-std=<standard>：指定使用的 C/C++ 标准（如 c99, c11, c++11）。
-f<feature>：启用或禁用特定编译特性（如 -fPIC）。
链接选项
-L<dir>：添加库文件搜索路径。
-l<library>：链接指定的库。
-T <script>：使用指定的链接脚本。
-nostartfiles：不使用标准启动文件。
-nodefaultlibs：不使用默认库。
-nostdlib：不使用标准库或启动文件。
-static：生成静态链接的可执行文件。
RISC-V 特定选项
-march=<arch>：指定目标架构（如 rv32im, rv64gc）。
-mabi=<abi>：指定目标 ABI（如 ilp32, lp64）。
示例用法
编译 C 源文件为目标文件：

bash
riscv64-unknown-elf-gcc -c main.c -o main.o
编译并链接生成可执行文件：

bash
riscv64-unknown-elf-gcc main.c -o main.elf
生成汇编代码：

bash
riscv64-unknown-elf-gcc -S main.c -o main.s
添加头文件和库文件路径：

bash
riscv64-unknown-elf-gcc -I/path/to/includes -L/path/to/libs -lmy_library main.c -o main.elf
使用特定的目标架构和 ABI：

bash
riscv64-unknown-elf-gcc -march=rv64gc -mabi=lp64 main.c -o main.elf
生成带有调试信息的可执行文件：

bash
riscv64-unknown-elf-gcc -g main.c -o main.elf
总的来说，riscv64-unknown-elf-gcc 的编译选项与标准的 gcc 编译选项非常相似，主要区别在于需要指定 RISC-V 特定的架构和 ABI。