/* 
In a pipelined processor, each stage of the pipeline typically has an enable signal that controls whether the stage should perform its operation or stall. The EX_stage module having both execute_enable and ID_EX_enable_out as inputs might seem redundant, but it depends on the design context. Here's how you can decide if you need both signals or just one:

Understanding the Signals
execute_enable: 
This signal usually indicates whether the execute stage (EX) should perform its operation. It is generally controlled by the previous stage (ID stage) or the control unit.
ID_EX_enable_out: 
This signal might be propagated from the decode stage (ID stage) to indicate the status of decoding and whether the execute stage should proceed.

Decision Criteria
Redundancy: 
If execute_enable is derived directly from ID_EX_enable_out or if both signals essentially control the same behavior, you might only need one of them.

Control Logic: 
If execute_enable is part of a more complex control logic that takes into account multiple factors (e.g., hazards, stalls, etc.), you might need to keep both signals. 
    
*/

module EX_stage (
    input wire clk,                      // Clock input
    input wire reset_n,                  // Asynchronous reset (active low)
    input wire ID_EX_enable_out,         // Input from ID stage, indicating enable
    input wire [31:0] ID_EX_ReadData1,   // Input from ID/EX pipeline register, Read Data 1
    input wire [31:0] ID_EX_ReadData2,   // Input from ID/EX pipeline register, Read Data 2
    input wire [31:0] ID_EX_Immediate,   // Input from ID/EX pipeline register, Immediate value
    input wire [4:0] ID_EX_Rd,           // Input from ID/EX pipeline register, destination register
    input wire [6:0] ID_EX_Funct7,       // Input from ID/EX pipeline register, funct7 field
    input wire [2:0] ID_EX_Funct3,       // Input from ID/EX pipeline register, funct3 field
    input wire [3:0] ALUControl,         // Input from ALUControl unit, ALU control signal
    input wire combined_stall,           // Combined stall signal
    output reg [31:0] EX_MEM_ALUResult,  // Output to EX/MEM pipeline register, ALU result
    output reg [31:0] EX_MEM_WriteData,  // Output to EX/MEM pipeline register, Write Data
    output reg [4:0] EX_MEM_Rd,          // Output to EX/MEM pipeline register, destination register
    output reg EX_MEM_RegWrite,          // Output to EX/MEM pipeline register, Register write control signal
    output reg execute_enable_out        // Output to EX/MEM pipeline register, indicating enable
);

    wire [31:0] ALUResult;               // Wire for ALU result
    wire Zero;                           // Wire for Zero flag from ALU

    // Instantiate ALUControl
    ALUControlUnit alu_cu (
        .ALUOp(ALUOp),                   // Input signal
        .Funct7(ID_EX_Funct7),           // Input signal
        .Funct3(ID_EX_Funct3),           // Input signal
        .ALUControl(ALUControl)          // Output signal
    );

    // Instantiate ALU
    ALU alu (
        .A(ID_EX_ReadData1),             // Input signal
        .B(ID_EX_ReadData2),             // Input signal
        .ALUControl(ALUControl),         // Input signal
        .Result(ALUResult),              // Output signal
        .Zero(Zero)                      // Output signal
    );

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            EX_MEM_ALUResult <= 32'b0;
            EX_MEM_WriteData <= 32'b0;
            EX_MEM_Rd <= 5'b0;
            EX_MEM_RegWrite <= 1'b0;
            execute_enable_out <= 1'b0;
        end else if (combined_stall) begin
            // Insert bubble (NOP) into the pipeline
            EX_MEM_ALUResult <= 32'b0;
            EX_MEM_WriteData <= 32'b0;
            EX_MEM_Rd <= 5'b0;
            EX_MEM_RegWrite <= 1'b0;
            execute_enable_out <= 1'b0;
        end else if (ID_EX_enable_out) begin
            // Execute stage
            EX_MEM_ALUResult <= ALUResult;
            EX_MEM_WriteData <= ID_EX_ReadData2;
            EX_MEM_Rd <= ID_EX_Rd;
            EX_MEM_RegWrite <= ID_EX_RegWrite;
            execute_enable_out <= 1'b1; // Enable execution for the next stage
        end else begin
            execute_enable_out <= 1'b0; // Disable execution
        end
    end

endmodule