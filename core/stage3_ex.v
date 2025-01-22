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
    // System signals
    input wire clk,                      // Clock input
    input wire reset_n,                  // Asynchronous reset (active low)

    // Global stall signal
    input wire [1:0] hazard_stall,       // Hazard stall signal

    // Enable signals from previous stage
    input wire ID_EX_enable_out,         // Input from ID stage, indicating enable
    input wire ID_EX_jump_branch_taken,  // Input from ID/EX pipeline register, indicating branch or jump taken  
    
    // Inputs from previous stage
    input wire [31:0] ID_EX_PC,          // Input from ID/EX pipeline register, Program Counter
    input wire [31:0] ID_EX_ReadData1,   // Input from ID/EX pipeline register, Read Data 1
    input wire [31:0] ID_EX_ReadData2,   // Input from ID/EX pipeline register, Read Data 2
    input wire [31:0] ID_EX_Immediate,   // Input from ID/EX pipeline register, Immediate value
    input wire [4:0] ID_EX_Rd,           // Input from ID/EX pipeline register, destination register
    input wire [6:0] ID_EX_Funct7,       // Input from ID/EX pipeline register, funct7 field
    input wire [2:0] ID_EX_Funct3,       // Input from ID/EX pipeline register, funct3 field

    // Inputs from control unit
    input wire ID_EX_ALUSrc,             // Output from ControlUnit, ALU source control signal
    input wire [1:0] ID_EX_ALUOp,        // Input from ControlUnit, ALU operation control signal
    input wire ID_EX_Branch,             // Output from ControlUnit, Branch control signal
    input wire ID_EX_Jump,               // Output from ControlUnit, Jump control signal
    input wire ID_EX_MemRead,            // Output from ControlUnit, Memory read control signal
    input wire ID_EX_MemWrite,           // Output from ControlUnit, Memory write control signal
    input wire ID_EX_MemToReg,           // Output from ControlUnit, Memory to register control signal
    input wire ID_EX_RegWrite,           // Output from ControlUnit, Register write control signal

    // Forwarding signals
    input wire [1:0] hazard_forwardA,    // Forwarding control for ReadData1
    input wire [1:0] hazard_forwardB,    // Forwarding control for ReadData2
    input wire [31:0] EX_MEM_ALUResult,  // Data forwarded from EX/MEM stage
    input wire [31:0] MEM_WB_ALUResult,  // Data forwarded from MEM/WB stage

    // Branch prediction signals
    input wire branch_prediction,        // Prediction from BPU
    
    // Outputs to next stage
    output reg [31:0] EX_MEM_PC,         // Output to EX/MEM pipeline register, Program Counter
    output reg [31:0] EX_MEM_ALUResult,  // Output to EX/MEM pipeline register, ALU result
    output reg [31:0] EX_MEM_WriteData,  // Output to EX/MEM pipeline register, Write Data
    output reg [4:0] EX_MEM_Rd,          // Output to EX/MEM pipeline register, destination register
    output reg EX_MEM_MemRead,           // Output to EX/MEM pipeline register, Memory read control signal
    output reg EX_MEM_MemWrite,          // Output to EX/MEM pipeline register, Memory write control signal
    output reg EX_MEM_MemToReg,          // Output to EX/MEM pipeline register, Memory to register control signal
    output reg EX_MEM_RegWrite,          // Output to EX/MEM pipeline register, Register write control signal

    // Enable signal to next stage
    output reg EX_MEM_enable_out,        // Output to EX/MEM pipeline register, indicating enable

    // Branch signals
    output reg EX_branch_inst,           // Indicate branch instruction, to branch predictor
    output reg EX_branch_taken,          // Indicate branch is really taken, to branch predictor
    output reg EX_branch_mispredict,     // Indicate branch is mispredicted, to branch predictor
    output reg [31:0] EX_next_pc         // Next program counter value after flush to IF stage 
);

    wire [3:0] ALUControl;        // ALU control signal
    wire [31:0] ALUResult;        // ALU result
    wire Zero;                    // Zero flag from ALU
    wire [31:0] ALUInput1;        // ALU first input
    wire [31:0] ALUInput2;        // ALU second input
    reg [31:0] branch_target;

    // ALU control unit
    ALUControlUnit alu_control (
        .clk(clk),
        .reset_n(reset_n),
        .ALUOp(ID_EX_ALUOp),
        .Funct7(ID_EX_Funct7),
        .Funct3(ID_EX_Funct3),
        .ALUControl(ALUControl)
    );

    // Select ALU first input based on forwarding control
    assign ALUInput1 = (hazard_forwardA == 2'b10) ? EX_MEM_ALUResult :
                       (hazard_forwardA == 2'b01) ? MEM_WB_ALUResult :
                       ID_EX_ReadData1;

    // Select ALU second input based on ALUSrc signal and forwarding control
    assign ALUInput2 = ID_EX_ALUSrc ? ID_EX_Immediate :
                       (hazard_forwardB == 2'b10) ? EX_MEM_ALUResult :
                       (hazard_forwardB == 2'b01) ? MEM_WB_ALUResult :
                       ID_EX_ReadData2;

    // ALU
    ALU alu (
        .clk(clk),
        .reset_n(reset_n),
        .ALUControl(ALUControl),
        .A(ALUInput1),
        .B(ALUInput2),
        .Result(ALUResult),
        .Zero(Zero)
    );

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            // Reset logic
            EX_MEM_PC <= 32'b0;
            EX_MEM_ALUResult <= 32'b0;
            EX_MEM_WriteData <= 32'b0;
            EX_MEM_Rd <= 5'b0;
            EX_MEM_RegWrite <= 1'b0;
            EX_MEM_MemRead <= 1'b0;
            EX_MEM_MemWrite <= 1'b0;
            EX_MEM_MemToReg <= 1'b0;
            EX_MEM_enable_out <= 1'b0;
            EX_branch_inst <= 1'b0;
            EX_branch_taken <= 1'b0;
            EX_branch_mispredict <= 1'b0;
            EX_next_pc <= 32'b0;
        end else if (hazard_stall == 2'b10) begin
            // If stall is detected in MEM stage, let MEM stage go on; else, stall it
            // Insert bubble (NOP) into the pipeline
            EX_MEM_PC <= 32'b0;
            EX_MEM_ALUResult <= 32'b0;
            EX_MEM_WriteData <= 32'b0;
            EX_MEM_Rd <= 5'b0;
            EX_MEM_RegWrite <= 1'b0;
            EX_MEM_MemRead <= 1'b0;
            EX_MEM_MemWrite <= 1'b0;
            EX_MEM_MemToReg <= 1'b0;
            EX_MEM_enable_out <= 1'b0;
            EX_branch_inst <= 1'b0;
            EX_branch_taken <= 1'b0;
            EX_branch_mispredict <= 1'b0;
            EX_MEM_enable_out <= 1'b1;        
        end else if (ID_EX_enable_out) begin
            if (ID_EX_Jump) begin
                // Jump always taken
                EX_branch_taken <= 1'b1;
                EX_branch_mispredict <= 1'b0; // No misprediction check needed for jump
            end else if (ID_EX_Branch) begin
                // Branch instruction
                EX_branch_inst <= 1'b1; // Branch instruction
                if (Zero) begin
                    EX_branch_taken <= 1'b1; // Branch taken
                    // Check for misprediction
                    if (ID_EX_jump_branch_taken != EX_branch_taken) begin
                        EX_branch_mispredict <= 1'b1;
                        EX_next_pc <= ID_EX_PC + 4; // Next PC value for flush condition
                    end else begin
                        EX_branch_mispredict <= 1'b0;
                    end
                end else begin
                    EX_branch_taken <= 1'b0; // Branch not taken
                    // Check for misprediction
                    if (ID_EX_jump_branch_taken != EX_branch_taken) begin
                        EX_branch_mispredict <= 1'b1;
                        EX_next_pc <= ID_EX_PC + ID_EX_Immediate; // Next PC value for flush condition
                    end else begin
                        EX_branch_mispredict <= 1'b0;
                    end
                end
            end else begin  // Normal operation
                EX_branch_inst <= 1'b0;
                EX_branch_taken <= 1'b0;
                EX_branch_mispredict <= 1'b0;
                EX_next_pc <= 32'b0;
            end

            EX_MEM_PC <= ID_EX_PC;
            EX_MEM_ALUResult <= ALUResult;
            EX_MEM_WriteData <= ID_EX_ReadData2;
            EX_MEM_Rd <= ID_EX_Rd;
            EX_MEM_RegWrite <= ID_EX_RegWrite;
            EX_MEM_MemRead <= ID_EX_MemRead;
            EX_MEM_MemWrite <= ID_EX_MemWrite;
            EX_MEM_MemToReg <= ID_EX_MemToReg;
            EX_MEM_enable_out <= 1'b1; // Enable next stage
        end else begin
            EX_MEM_enable_out <= 1'b0; // Disable next stage
            EX_branch_inst <= 1'b0;
            EX_branch_taken <= 1'b0;
            EX_branch_mispredict <= 1'b0;
            EX_next_pc <= 32'b0;
        end
    end

endmodule