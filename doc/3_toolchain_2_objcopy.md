objcopy 是 GNU Binutils 工具集的一部分，用于复制和转换目标文件的格式。以下是 objcopy 常用参数的说明：

常用参数
-I or --input-target=bfdname：指定输入文件的格式。
-O or --output-target=bfdname：指定输出文件的格式。
-B or --binary-architecture=bfdname：用于指定二进制文件的目标架构。
-F or --target=bfdname：将输入文件和输出文件的格式都设置为 bfdname。
-j or --only-section=sectionname：只拷贝指定的部分。
-R or --remove-section=sectionname：从输出文件中移除指定的部分。
-S or --strip-all：从输出文件中移除所有符号信息。
-g or --strip-debug：从输出文件中移除调试信息。
-x or --discard-all：从输出文件中移除所有非全局符号。
-w or --wildcard：允许使用通配符匹配部分名。
-p or --preserve-dates：保持文件的访问和修改时间。
--strip-unneeded：移除所有未使用的符号。
--only-keep-debug：保留调试信息到一个单独的文件。
--add-gnu-debuglink=filename：将调试信息文件的链接添加到输出文件。
-v or --verbose：显示详细操作信息。
--help：显示帮助信息并退出。
--version：显示版本信息并退出。

示例用法
将 ELF 文件转换为二进制文件：

```bash
objcopy -O binary input.elf output.bin
```

将二进制文件转换为 ELF 文件：
```bash
objcopy -I binary -O elf32-littlearm input.bin output.elf
```

只拷贝指定部分：
```bash
objcopy -O binary -j .text input.elf output.bin
```

移除指定部分：
```bash
objcopy -R .comment -R .note input.elf output.elf
```

移除所有符号信息：
```bash
objcopy -S input.elf output.elf
```

保留调试信息到单独文件：
```bash
objcopy --only-keep-debug input.elf debug.elf
```

通过这些参数和示例，你可以灵活地使用 objcopy 工具来转换和处理目标文件。