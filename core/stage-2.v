module ID_stage (
    input wire clk,
    input wire reset,
    input wire decode_enable,
    input wire fetch_enable,
    input wire [31:0] IF_ID_PC,
    input wire [31:0] IF_ID_Instruction,
    input wire [31:0] ReadData1,
    input wire [31:0] ReadData2,
    input wire [31:0] Immediate,
    output reg [31:0] ID_EX_PC,
    output reg [31:0] ID_EX_ReadData1,
    output reg [31:0] ID_EX_ReadData2,
    output reg [31:0] ID_EX_Immediate,
    output reg [4:0] ID_EX_Rs1,
    output reg [4:0] ID_EX_Rs2,
    output reg [4:0] ID_EX_Rd,
    output reg [6:0] ID_EX_Funct7,
    output reg [2:0] ID_EX_Funct3
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            decode_enable <= 1'b0;
            ID_EX_PC <= 0;
            ID_EX_ReadData1 <= 0;
            ID_EX_ReadData2 <= 0;
            ID_EX_Immediate <= 0;
            ID_EX_Rs1 <= 0;
            ID_EX_Rs2 <= 0;
            ID_EX_Rd <= 0;
            ID_EX_Funct7 <= 0;
            ID_EX_Funct3 <= 0;           
        end else if (!cpu_stall) begin
            if (decode_enable) begin
                // Decode instruction
                // (Implementation depends on the instruction set)
                ID_EX_PC <= IF_ID_PC;
                ID_EX_ReadData1 <= ReadData1;
                ID_EX_ReadData2 <= ReadData2;
                ID_EX_Immediate <= Immediate;
                ID_EX_Rs1 <= IF_ID_Instruction[19:15];
                ID_EX_Rs2 <= IF_ID_Instruction[24:20];
                ID_EX_Rd <= IF_ID_Instruction[11:7];
                ID_EX_Funct7 <= IF_ID_Instruction[31:25];
                ID_EX_Funct3 <= IF_ID_Instruction[14:12];
            end
            decode_enable <= fetch_enable;
        end else begin
            decode_enable <= 1'b0;
        end
    end
endmodule