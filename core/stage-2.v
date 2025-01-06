

module ID_stage (
    input wire clk,
    input wire reset,
    input wire fetch_enable_out, // Updated input from fetch stage
    input wire [31:0] IF_ID_PC,
    input wire [31:0] IF_ID_Instruction,
    input wire [31:0] ReadData1,
    input wire [31:0] ReadData2,
    input wire [31:0] Immediate,
    input wire combined_stall, // New input for combined stall signal
    output reg [31:0] ID_EX_PC,
    output reg [31:0] ID_EX_ReadData1,
    output reg [31:0] ID_EX_ReadData2,
    output reg [31:0] ID_EX_Immediate,
    output reg [4:0] ID_EX_Rs1,
    output reg [4:0] ID_EX_Rs2,
    output reg [4:0] ID_EX_Rd,
    output reg [6:0] ID_EX_Funct7,
    output reg [2:0] ID_EX_Funct3,
    output reg decode_enable_out // Output decode_enable_out signal
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ID_EX_PC <= 32'b0;
            ID_EX_ReadData1 <= 32'b0;
            ID_EX_ReadData2 <= 32'b0;
            ID_EX_Immediate <= 32'b0;
            ID_EX_Rs1 <= 5'b0;
            ID_EX_Rs2 <= 5'b0;
            ID_EX_Rd <= 5'b0;
            ID_EX_Funct7 <= 7'b0;
            ID_EX_Funct3 <= 3'b0;
            decode_enable_out <= 1'b0;
        end else if (combined_stall) begin
            // Insert bubble (NOP) into the pipeline
            ID_EX_PC <= 32'b0;
            ID_EX_ReadData1 <= 32'b0;
            ID_EX_ReadData2 <= 32'b0;
            ID_EX_Immediate <= 32'b0;
            ID_EX_Rs1 <= 5'b0;
            ID_EX_Rs2 <= 5'b0;
            ID_EX_Rd <= 5'b0;
            ID_EX_Funct7 <= 7'b0;
            ID_EX_Funct3 <= 3'b0;
            decode_enable_out <= 1'b0;
        end else if (fetch_enable_out) begin
                // Decode instruction
                ID_EX_PC <= IF_ID_PC;
                ID_EX_ReadData1 <= ReadData1;
                ID_EX_ReadData2 <= ReadData2;
                ID_EX_Immediate <= Immediate;
                ID_EX_Rs1 <= IF_ID_Instruction[19:15];
                ID_EX_Rs2 <= IF_ID_Instruction[24:20];
                ID_EX_Rd <= IF_ID_Instruction[11:7];
                ID_EX_Funct7 <= IF_ID_Instruction[31:25];
                ID_EX_Funct3 <= IF_ID_Instruction[14:12];
            decode_enable_out <= 1'b1; // Enable decoding for the next stage
        end else begin
            decode_enable_out <= 1'b0; // Disable decoding
        end
    end
endmodule