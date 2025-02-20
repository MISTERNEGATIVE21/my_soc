
# 1. CSR 指令

在 RISC-V 指令集架构中，CSR（Control and Status Register，控制和状态寄存器）指令用于访问和操作控制和状态寄存器。
这些寄存器用于存储处理器的状态信息，如异常向量、性能计数器等。RV32I 基础指令集提供了一系列用于读写 CSR 的指令。
以下是 RV32I 中常见的 CSR 指令及其功能介绍：

## 1.1. CSR 指令概述
### CSRRW (Atomic Read/Write CSR)
格式：csrrw rd, csr, rs1
功能：将寄存器 rs1 的值写入 CSR 寄存器 csr，并将原来的 CSR 寄存器值写入目标寄存器 rd。
示例：
Assembly
csrrw x5, 0x300, x1  // 将 x1 的值写入 CSR 0x300（mstatus），并将原来的 mstatus 值写入 x5

### CSRRS (Atomic Read and Set Bits in CSR)
格式：csrrs rd, csr, rs1
功能：将寄存器 rs1 的值与 CSR 寄存器 csr 的值按位 OR，并将结果写入 csr。同时，将原来的 CSR 寄存器值写入目标寄存器 rd。
示例：
Assembly
csr rs x5, 0x300, x1  // 将 x1 的值与 CSR 0x300（mstatus）按位 OR，并将结果写入 mstatus，同时将原来的 mstatus 值写入 x5

### CSRRC (Atomic Read and Clear Bits in CSR)
格式：csrrc rd, csr, rs1
功能：将 CSR 寄存器 csr 的值与 rs1 的按位 NOT 值按位 AND，并将结果写入 csr。同时，将原来的 CSR 寄存器值写入目标寄存器 rd。
示例：
Assembly
csrrc x5, 0x300, x1  // 将 CSR 0x300（mstatus）的值与 x1 的按位 NOT 值按位 AND，并将结果写入 mstatus，同时将原来的 mstatus 值写入 x5

### CSRRWI (Atomic Read/Write CSR Immediate)
格式：csrrwi rd, csr, imm
功能：将立即数 imm 写入 CSR 寄存器 csr，并将原来的 CSR 寄存器值写入目标寄存器 rd。
示例：
Assembly
csrrwi x5, 0x300, 1  // 将立即数 1 写入 CSR 0x300（mstatus），并将原来的 mstatus 值写入 x5

### CSRRSI (Atomic Read and Set Bits in CSR Immediate)

格式：csrrsi rd, csr, imm
功能：将立即数 imm 与 CSR 寄存器 csr 的值按位 OR，并将结果写入 csr。同时，将原来的 CSR 寄存器值写入目标寄存器 rd。
示例：
Assembly
csrrsi x5, 0x300, 1  // 将立即数 1 与 CSR 0x300（mstatus）按位 OR，并将结果写入 mstatus，同时将原来的 mstatus 值写入 x5

### CSRRCI (Atomic Read and Clear Bits in CSR Immediate)

格式：csrrci rd, csr, imm
功能：将 CSR 寄存器 csr 的值与立即数 imm 的按位 NOT 值按位 AND，并将结果写入 csr。同时，将原来的 CSR 寄存器值写入目标寄存器 rd。
示例：
Assembly
csrrci x5, 0x300, 1  // 将 CSR 0x300（mstatus）的值与立即数 1 的按位 NOT 值按位 AND，并将结果写入 mstatus，同时将原来的 mstatus 值写入 x5

## 1.2. 示例代码
以下是一个使用 CSR 指令的简单示例，展示如何读取和修改 mstatus 寄存器：

```Assembly
# 读取 mstatus 寄存器的值到 x5
csrr x5, 0x300

# 将 x1 的值写入 mstatus 寄存器，并将原来的 mstatus 值写入 x5
csrrw x5, 0x300, x1

# 将 x1 的值与 mstatus 寄存器按位 OR，并将结果写入 mstatus，同时将原来的 mstatus 值写入 x5
csr rs x5, 0x300, x1

# 将 mstatus 寄存器的值与 x1 的按位 NOT 值按位 AND，并将结果写入 mstatus，同时将原来的 mstatus 值写入 x5
csrrc x5, 0x300, x1

# 将立即数 1 写入 mstatus 寄存器，并将原来的 mstatus 值写入 x5
csrrwi x5, 0x300, 1

# 将立即数 1 与 mstatus 寄存器按位 OR，并将结果写入 mstatus，同时将原来的 mstatus 值写入 x5
csrrsi x5, 0x300, 1

# 将 mstatus 寄存器的值与立即数 1 的按位 NOT 值按位 AND，并将结果写入 mstatus，同时将原来的 mstatus 值写入 x5
csrrci x5, 0x300, 1
```

## 1.3. 总结
CSR 指令在 RISC-V 架构中用于访问和操作控制和状态寄存器。这些指令使得可以灵活地控制处理器的行为，并在需要时修改其状态。在实施这些指令时，需要注意寄存器的地址和具体的操作，以确保正确的功能和性能。

# 2. 常见 CSR 寄存器
在 RISC-V 中，CSR（控制和状态寄存器）用于存储处理器的状态信息、控制处理器的操作，以及执行特权操作。以下是一些常见的 CSR 寄存器及其地址的详细介绍：

常见的 CSR 寄存器及其地址

## 2.1. 用户模式（User-Level）CSR 寄存器
ustatus (User Status Register)

地址：0x000
功能：存储用户模式的状态信息。
uie (User Interrupt Enable Register)

地址：0x004
功能：控制用户模式下的中断使能。
utvec (User Trap Vector Base Address Register)

地址：0x005
功能：存储用户模式下陷阱处理程序的基地址。
uscratch (User Scratch Register)

地址：0x040
功能：用户模式下的临时寄存器，用于保存上下文信息。
uepc (User Exception Program Counter)

地址：0x041
功能：存储用户模式下发生异常时的程序计数器值。
ucause (User Cause Register)

地址：0x042
功能：存储用户模式下异常或中断的原因。
utval (User Trap Value Register)

地址：0x043
功能：存储用户模式下异常或陷阱相关的值。
uip (User Interrupt Pending Register)

地址：0x044
功能：指示用户模式下的中断挂起状态。

## 2.2. 超级用户模式（Supervisor-Level）CSR 寄存器
sstatus (Supervisor Status Register)

地址：0x100
功能：存储超级用户模式的状态信息。
sie (Supervisor Interrupt Enable Register)

地址：0x104
功能：控制超级用户模式下的中断使能。
stvec (Supervisor Trap Vector Base Address Register)

地址：0x105
功能：存储超级用户模式下陷阱处理程序的基地址。
sscratch (Supervisor Scratch Register)

地址：0x140
功能：超级用户模式下的临时寄存器，用于保存上下文信息。
sepc (Supervisor Exception Program Counter)

地址：0x141
功能：存储超级用户模式下发生异常时的程序计数器值。
scause (Supervisor Cause Register)

地址：0x142
功能：存储超级用户模式下异常或中断的原因。
stval (Supervisor Trap Value Register)

地址：0x143
功能：存储超级用户模式下异常或陷阱相关的值。
sip (Supervisor Interrupt Pending Register)

地址：0x144
功能：指示超级用户模式下的中断挂起状态。

## 2.3. 机器模式（Machine-Level）CSR 寄存器
mstatus (Machine Status Register)

地址：0x300
功能：存储机器模式的状态信息。
misa (Machine ISA Register)

地址：0x301
功能：指示处理器支持的指令集架构。
mie (Machine Interrupt Enable Register)

地址：0x304
功能：控制机器模式下的中断使能。
mtvec (Machine Trap Vector Base Address Register)

地址：0x305
功能：存储机器模式下陷阱处理程序的基地址。
mscratch (Machine Scratch Register)

地址：0x340
功能：机器模式下的临时寄存器，用于保存上下文信息。
mepc (Machine Exception Program Counter)

地址：0x341
功能：存储机器模式下发生异常时的程序计数器值。
mcause (Machine Cause Register)

地址：0x342
功能：存储机器模式下异常或中断的原因。
mtval (Machine Trap Value Register)

地址：0x343
功能：存储机器模式下异常或陷阱相关的值。
mip (Machine Interrupt Pending Register)

地址：0x344
功能：指示机器模式下的中断挂起状态。
CSR 译码
在 RISC-V 处理器中，CSR 寄存器的地址常常以固定的偏移量来访问。译码逻辑通常用于确定具体操作的 CSR 寄存器。下面是一个简化的 CSR 译码示例：

```Verilog
module csr_decoder (
    input [11:0] csr_address, // CSR 地址
    output reg [31:0] csr_data // CSR 数据
);

    always @(*) begin
        case (csr_address)
            12'h300: csr_data = mstatus; // 机器状态寄存器
            12'h301: csr_data = misa;    // 机器 ISA 寄存器
            12'h304: csr_data = mie;     // 机器中断使能寄存器
            12'h305: csr_data = mtvec;   // 机器陷阱向量基地址寄存器
            12'h340: csr_data = mscratch;// 机器临时寄存器
            12'h341: csr_data = mepc;    // 机器异常程序计数器
            12'h342: csr_data = mcause;  // 机器原因寄存器
            12'h343: csr_data = mtval;   // 机器陷阱值寄存器
            12'h344: csr_data = mip;     // 机器中断挂起寄存器
            default: csr_data = 32'h0;   // 默认值
        endcase
    end
endmodule
```

## 总结
CSR 寄存器在 RISC-V 处理器中扮演着至关重要的角色，用于管理处理器的状态和控制特权操作。了解常见的 CSR 寄存器及其地址，以及如何进行译码，对于设计和调试 RISC-V 系统非常重要。