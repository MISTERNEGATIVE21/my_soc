module EX_stage (
    input wire clk,
    input wire reset,
    input wire execute_enable,
    input wire decode_enable,
    input wire [31:0] ID_EX_ReadData1,
    input wire [31:0] ID_EX_ReadData2,
    input wire [31:0] ID_EX_Immediate,
    input wire [4:0] ID_EX_Rd,
    input wire [6:0] ID_EX_Funct7,
    input wire [2:0] ID_EX_Funct3,
    input wire [3:0] ALUControl,
    output reg [31:0] EX_MEM_ALUResult,
    output reg [31:0] EX_MEM_WriteData,
    output reg [4:0] EX_MEM_Rd,
    output reg EX_MEM_RegWrite
);

    wire [31:0] ALUResult;
    wire Zero;

    // ALU
    ALU alu (
        .A(ID_EX_ReadData1),
        .B((ALUSrc) ? ID_EX_Immediate : ID_EX_ReadData2),
        .ALUControl(ALUControl),
        .Result(ALUResult),
        .Zero(Zero)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            execute_enable <= 1'b0;
            EX_MEM_ALUResult <= 0;
            EX_MEM_WriteData <= 0;
            EX_MEM_Rd <= 0;
            EX_MEM_RegWrite <= 0;
        end else if (!cpu_stall) begin
            if (execute_enable) begin
                EX_MEM_ALUResult <= ALUResult;
                EX_MEM_WriteData <= ID_EX_ReadData2;
                EX_MEM_Rd <= ID_EX_Rd;
                EX_MEM_RegWrite <= RegWrite;
            end
            execute_enable <= decode_enable;
        end else begin
            execute_enable <= 1'b0;
        end
    end
endmodule