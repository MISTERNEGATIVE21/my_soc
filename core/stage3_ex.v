/* 
In a pipelined processor, each stage of the pipeline typically has an enable signal that controls whether the stage should perform its operation or stall. The EX_stage module having both execute_enable and decode_enable_out as inputs might seem redundant, but it depends on the design context. Here's how you can decide if you need both signals or just one:

Understanding the Signals
execute_enable: 
This signal usually indicates whether the execute stage (EX) should perform its operation. It is generally controlled by the previous stage (ID stage) or the control unit.
decode_enable_out: 
This signal might be propagated from the decode stage (ID stage) to indicate the status of decoding and whether the execute stage should proceed.

Decision Criteria
Redundancy: 
If execute_enable is derived directly from decode_enable_out or if both signals essentially control the same behavior, you might only need one of them.

Control Logic: 
If execute_enable is part of a more complex control logic that takes into account multiple factors (e.g., hazards, stalls, etc.), you might need to keep both signals. 
    
*/

module EX_stage (
    input wire clk,
    input wire reset,
    input wire decode_enable_out,
    input wire [31:0] ID_EX_ReadData1,
    input wire [31:0] ID_EX_ReadData2,
    input wire [31:0] ID_EX_Immediate,
    input wire [4:0] ID_EX_Rd,
    input wire [6:0] ID_EX_Funct7,
    input wire [2:0] ID_EX_Funct3,
    input wire [3:0] ALUControl,
    input wire combined_stall, // New input for combined stall signal
    output reg [31:0] EX_MEM_ALUResult,
    output reg [31:0] EX_MEM_WriteData,
    output reg [4:0] EX_MEM_Rd,
    output reg EX_MEM_RegWrite,
    output reg execute_enable_out // Output execute_enable signal
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
        end else if (decode_enable_out) begin
                EX_MEM_ALUResult <= ALUResult;
                EX_MEM_WriteData <= ID_EX_ReadData2;
                EX_MEM_Rd <= ID_EX_Rd;
                EX_MEM_RegWrite <= RegWrite;
                execute_enable_out <= 1'b1; // Enable for the next stage
        end else begin
            execute_enable_out <= 1'b0; // Disable execution
        end
    end
endmodule