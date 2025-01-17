module ID_stage (
    input wire clk,                    // Clock input
    input wire reset_n,                // Asynchronous reset (active low)
    input wire fetch_enable_out,       // Input from fetch stage, indicating fetch enable
    input wire [31:0] IF_ID_PC,        // Input from IF/ID pipeline register, carrying Program Counter
    input wire [31:0] IF_ID_Instruction,// Input from IF/ID pipeline register, carrying instruction
    input wire combined_stall,         // Combined stall signal
    output reg [31:0] ID_EX_PC,        // Output to ID/EX pipeline register, carrying Program Counter
    output reg [31:0] ID_EX_ReadData1, // Output to ID/EX pipeline register, carrying Read Data 1
    output reg [31:0] ID_EX_ReadData2, // Output to ID/EX pipeline register, carrying Read Data 2
    output reg [31:0] ID_EX_Immediate, // Output to ID/EX pipeline register, carrying Immediate value
    output reg [4:0] ID_EX_Rs1,        // Output to ID/EX pipeline register, carrying source register 1
    output reg [4:0] ID_EX_Rs2,        // Output to ID/EX pipeline register, carrying source register 2
    output reg [4:0] ID_EX_Rd,         // Output to ID/EX pipeline register, carrying destination register
    output reg [6:0] ID_EX_Funct7,     // Output to ID/EX pipeline register, carrying funct7 field
    output reg [2:0] ID_EX_Funct3,     // Output to ID/EX pipeline register, carrying funct3 field
    output reg ID_EX_enable_out,       // Output to ID/EX pipeline register, indicating enable
    output wire [1:0] ID_EX_ALUOp,     // Output from ControlUnit, ALU operation control signal
    output wire ID_EX_MemRead,         // Output from ControlUnit, Memory read control signal
    output wire ID_EX_MemtoReg,        // Output from ControlUnit, Memory to register control signal
    output wire ID_EX_MemWrite,        // Output from ControlUnit, Memory write control signal
    output wire ID_EX_ALUSrc,          // Output from ControlUnit, ALU source control signal
    output wire ID_EX_RegWrite,        // Output from ControlUnit, Register write control signal
    output wire [31:0] ID_EX_ReadData1_out, // Output from RegisterFile, Read Data 1
    output wire [31:0] ID_EX_ReadData2_out  // Output from RegisterFile, Read Data 2
);

    wire [31:0] Immediate;  // Wire for Immediate value generated
    wire [6:0] opcode = IF_ID_Instruction[6:0];

    // Instantiate ImmediateGenerator
    ImmediateGenerator imm_gen (
        .instruction(IF_ID_Instruction), // Input signal
        .immediate(Immediate)            // Output signal
    );

    // Instantiate ControlUnit
    ControlUnit cu (
        .opcode(opcode),                 // Input signal
        .ALUOp(ID_EX_ALUOp),             // Output signal
        .MemRead(ID_EX_MemRead),         // Output signal
        .MemtoReg(ID_EX_MemtoReg),       // Output signal
        .MemWrite(ID_EX_MemWrite),       // Output signal
        .ALUSrc(ID_EX_ALUSrc),           // Output signal
        .RegWrite(ID_EX_RegWrite)        // Output signal
    );

    // Instantiate RegisterFile
    RegisterFile rf (
        .clk(clk),                       // Input signal
        .RegWrite(ID_EX_RegWrite),       // Input signal
        .rs1(IF_ID_Instruction[19:15]),  // Input signal
        .rs2(IF_ID_Instruction[24:20]),  // Input signal
        .rd(ID_EX_Rd),                   // Input signal
        .WriteData((ID_EX_MemtoReg) ? ID_EX_ReadData1_out : ID_EX_ReadData2_out), // Input signal
        .ReadData1(ID_EX_ReadData1_out), // Output signal
        .ReadData2(ID_EX_ReadData2_out)  // Output signal
    );

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            // Reset all pipeline registers
            ID_EX_PC <= 32'b0;
            ID_EX_ReadData1 <= 32'b0;
            ID_EX_ReadData2 <= 32'b0;
            ID_EX_Immediate <= 32'b0;
            ID_EX_Rs1 <= 5'b0;
            ID_EX_Rs2 <= 5'b0;
            ID_EX_Rd <= 5'b0;
            ID_EX_Funct7 <= 7'b0;
            ID_EX_Funct3 <= 3'b0;
            ID_EX_enable_out <= 1'b0;
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
            ID_EX_enable_out <= 1'b0;
        end else if (fetch_enable_out) begin
            // Decode instruction
            ID_EX_PC <= IF_ID_PC;
            ID_EX_ReadData1 <= ID_EX_ReadData1_out;
            ID_EX_ReadData2 <= ID_EX_ReadData2_out;
            ID_EX_Immediate <= Immediate;
            ID_EX_Rs1 <= IF_ID_Instruction[19:15];
            ID_EX_Rs2 <= IF_ID_Instruction[24:20];
            ID_EX_Rd <= IF_ID_Instruction[11:7];
            ID_EX_Funct7 <= IF_ID_Instruction[31:25];
            ID_EX_Funct3 <= IF_ID_Instruction[14:12];
            ID_EX_enable_out <= 1'b1; // Enable decoding for the next stage
        end else begin
            ID_EX_enable_out <= 1'b0; // Disable decoding
        end
    end

endmodule