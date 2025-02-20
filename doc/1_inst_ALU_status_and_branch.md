# Branch 指令与 ALU 状态位关系

| 指令  | 描述                             | Zero | Negative | Carry | Overflow |
|-------|----------------------------------|------|----------|-------|----------|
| BEQ   | Branch if Equal                  | 1    | -        | -     | -        |
| BNE   | Branch if Not Equal              | 0    | -        | -     | -        |
| BLT   | Branch if Less Than              | -    | 1        | -     | -        |
| BGE   | Branch if Greater Than or Equal  | -    | 0        | -     | -        |
| BLTU  | Branch if Less Than Unsigned     | -    | -        | 1     | -        |
| BGEU  | Branch if Greater or Equal Unsigned | - | -        | 0     | -        |

注释：
- `-` 表示该状态位在该指令中不相关。
- `Zero` 表示结果是否为零。
- `Negative` 表示结果是否为负数。
- `Carry` 表示是否有进位。
- `Overflow` 表示是否有溢出。

## 解释
BEQ (Branch if Equal): 当 Zero 标志位为 1 时，表示两个操作数相等，分支跳转。
BNE (Branch if Not Equal): 当 Zero 标志位为 0 时，表示两个操作数不相等，分支跳转。
BLT (Branch if Less Than): 当 Negative 标志位为 1 时，表示第一个操作数小于第二个操作数，分支跳转。
BGE (Branch if Greater Than or Equal): 当 Negative 标志位为 0 时，表示第一个操作数大于或等于第二个操作数，分支跳转。
BLTU (Branch if Less Than Unsigned): 当 Carry 标志位为 1 时，表示第一个操作数小于第二个操作数（无符号比较），分支跳转。
BGEU (Branch if Greater or Equal Unsigned): 当 Carry 标志位为 0 时，表示第一个操作数大于或等于第二个操作数（无符号比较），分支跳转。

# Overflow 
信号主要用于检测有符号算术运算（如加法和减法）中的溢出情况。处理器可以使用 Overflow 信号来处理异常情况或进行特定的操作。以下是一些常见的处理 Overflow 信号的方法：

1. 异常处理
当检测到溢出时，处理器可以触发异常处理机制。这通常涉及以下步骤：
保存当前状态：保存当前的程序计数器（PC）和其他重要寄存器的值，以便在处理完异常后能够恢复执行。
跳转到异常处理程序：将 PC 设置为异常处理程序的地址，开始执行异常处理程序。
处理异常：异常处理程序可以记录错误信息、执行特定的恢复操作或终止程序。
恢复执行：处理完异常后，恢复保存的状态，继续执行原来的程序。
```v
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            PC <= 32'b0;
            // 其他复位逻辑
        end else begin
            if (Overflow) begin
                // 处理溢出异常
                // 保存当前状态
                saved_PC <= PC;
                // 跳转到异常处理程序
                PC <= exception_handler_address;
            end else begin
                // 正常执行
                PC <= next_PC;
            end
        end
    end
```

2. 分支指令的条件判断
在某些情况下，Overflow 信号可以用于分支指令的条件判断。例如，某些处理器可能有条件分支指令，只有在发生溢出时才跳转。

