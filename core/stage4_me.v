module MEM_stage (
    //system signals
    input wire clk,               // 时钟信号
    input wire reset_n,           // 异步复位信号（低电平有效）
    
    //global stall signal
    input wire combined_stall,    // 组合暂停信号
    input wire [1:0] hazard_stall, // hazard stall signal
    
    //enable signals from previous stage
    input wire EX_MEM_enable_out, // 来自执行阶段的使能信号
    
    //from previous stage
    input wire [31:0] EX_MEM_PC,  // 来自执行阶段的程序计数器
    input wire [31:0] EX_MEM_ALUResult, // 来自执行阶段的ALU结果（用于内存操作的地址或寄存器写入内容）
    input wire [31:0] EX_MEM_WriteData, // 来自执行阶段的写数据
    input wire [4:0] EX_MEM_Rd,   // 来自执行阶段的目标寄存器
    input wire EX_MEM_MemRead,    // 来自执行阶段的内存读使能信号
    input wire EX_MEM_MemWrite,   // 来自执行阶段的内存写使能信号
    input wire EX_MEM_MemToReg,   // 来自执行阶段的内存写入寄存器选择信号
    input wire EX_MEM_RegWrite,   // 来自执行阶段的寄存器写使能信号

    //to next stage
    output reg [31:0] MEM_WB_PC,  // 传递到写回阶段的程序计数器
    output reg [31:0] MEM_WB_ReadData, // 传递到寄存器文件的写回数据
    output reg [31:0] MEM_WB_ALUResult, // 传递到下一个阶段的ALU结果
    output reg [4:0] MEM_WB_Rd,        // 传递到写回阶段的目标寄存器
    output reg MEM_WB_RegWrite,        // 传递到写回阶段的寄存器写使能信号
    output reg MEM_WB_MemToReg,        // 传递到写回阶段的内存写入寄存器选择信号
    
    //next stage enable signal
    output reg MEM_WB_enable_out       // 内存阶段的使能信号
);

    // 实例化 d_memory
    wire [31:0] d_memory_rdata;
    reg d_memory_mem_read;
    reg d_memory_mem_write;

    d_memory #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .MEM_DEPTH(1024)
    ) d_memory_inst (
        .clk(clk),
        .reset_n(reset_n),
        .addr(EX_MEM_ALUResult),
        .wdata(EX_MEM_WriteData),
        .mem_read(d_memory_mem_read),
        .mem_write(d_memory_mem_write),
        .rdata(d_memory_rdata)
    );

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            // 复位逻辑
            MEM_WB_PC <= 32'b0;
            MEM_WB_ReadData <= 32'b0;
            MEM_WB_ALUResult <= 32'b0;
            MEM_WB_Rd <= 5'b0;
            MEM_WB_RegWrite <= 1'b0;
            MEM_WB_MemToReg <= 1'b0;
            MEM_WB_enable_out <= 1'b0;
            d_memory_mem_read <= 1'b0;
            d_memory_mem_write <= 1'b0;
        end else if (combined_stall) begin
            // hazard detected on ex or mem stage, not stall mem stage
            if (hazard_stall == 2'b01 || hazard_stall == 2'b10) begin
                if (EX_MEM_enable_out) begin
                    // EX_MEM_enable_out = 1 流水线有效 内存操作
                    d_memory_mem_read <= EX_MEM_MemRead;
                    d_memory_mem_write <= EX_MEM_MemWrite;
                    MEM_WB_ReadData <= EX_MEM_MemRead ? d_memory_rdata : 32'b0;
                    MEM_WB_ALUResult <= EX_MEM_ALUResult;
                    MEM_WB_PC <= EX_MEM_PC;
                    MEM_WB_Rd <= EX_MEM_Rd;
                    MEM_WB_RegWrite <= EX_MEM_RegWrite;
                    MEM_WB_MemToReg <= EX_MEM_MemToReg;
                    MEM_WB_enable_out <= 1'b1;
                end
            end else begin  // other case of stall
                MEM_WB_enable_out <= 1'b0;
                d_memory_mem_read <= 1'b0;
                d_memory_mem_write <= 1'b0;
            end
        end else if (EX_MEM_enable_out) begin
            // normal case
            d_memory_mem_read <= EX_MEM_MemRead;
            d_memory_mem_write <= EX_MEM_MemWrite;
            MEM_WB_ReadData <= EX_MEM_MemRead ? d_memory_rdata : 32'b0;
            MEM_WB_ALUResult <= EX_MEM_ALUResult;
            MEM_WB_PC <= EX_MEM_PC;
            MEM_WB_Rd <= EX_MEM_Rd;
            MEM_WB_RegWrite <= EX_MEM_RegWrite;
            MEM_WB_MemToReg <= EX_MEM_MemToReg;
            MEM_WB_enable_out <= 1'b1;
        end else begin
            // EX_MEM_enable_out = 0； 禁用下一个阶段的进展
            MEM_WB_enable_out <= 1'b0;
            d_memory_mem_read <= 1'b0;
            d_memory_mem_write <= 1'b0;
        end
    end

endmodule