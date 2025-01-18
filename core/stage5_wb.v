module WB_stage (
    input wire clk,               // Clock signal
    input wire reset_n,           // Asynchronous reset (active low)
    input wire combined_stall,    // in: Combined stall signal
    input wire [31:0] MEM_WB_PC,  // in: Program counter from MEM stage
    input wire [31:0] MEM_WB_ReadData, // in: Read data from MEM stage
    input wire [31:0] MEM_WB_ALUResult, // in: ALU result from MEM stage
    input wire [4:0] MEM_WB_Rd,   // in: Destination register from MEM stage
    input wire MEM_WB_RegWrite,   // in: Register write enable from MEM stage
    input wire MEM_WB_MemToReg,   // in: Memory to register signal from MEM stage
    input wire MEM_WB_enable_out, // in: Enable signal from MEM stage

    output reg WB_RegWrite,       // out: Register write enable to register file
    output reg [31:0] WB_WriteData, // out: Write data to register file
    output reg [4:0] WB_Rd,       // out: Destination register to register file
    output reg [31:0] WB_PC       // out: Program counter to next stage
);

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            // 复位逻辑
            WB_RegWrite <= 1'b0;   // 禁用寄存器写入
            WB_WriteData <= 32'b0;
            WB_Rd <= 5'b0;
            WB_PC <= 32'b0;
        end else if (combined_stall) begin
            // 在流水线中插入空泡（NOP）
            WB_RegWrite <= 1'b0;
            WB_WriteData <= 32'b0;
            WB_Rd <= 5'b0;
            WB_PC <= 32'b0;
        end else if (MEM_WB_enable_out) begin
            // MEM_WB_enable_out = 1 流水线有效
            WB_RegWrite <= MEM_WB_RegWrite;
            WB_WriteData <= MEM_WB_MemToReg ? MEM_WB_ReadData : MEM_WB_ALUResult;
            WB_Rd <= MEM_WB_Rd;
            WB_PC <= MEM_WB_PC;
            end else begin
            // MEM_WB_enable_out = 0 禁用写回阶段
            WB_RegWrite <= 1'b0;
            WB_WriteData <= 32'b0;
            WB_Rd <= 5'b0;
            WB_PC <= 32'b0;
        end
    end

endmodule