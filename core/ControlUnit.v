/*
Explanation:
Opcode: This is a 7-bit field from the instruction that specifies the operation to be performed.

Control Signals:

ALUOp: Determines the operation to be performed by the ALU (Arithmetic Logic Unit).
MemRead: Indicates whether a memory read operation is to be performed.
MemtoReg: Controls whether data from memory or the ALU result is written to the register file.
MemWrite: Indicates whether a memory write operation is to be performed.
ALUSrc: Determines whether the second ALU operand is a register value or an immediate value.
RegWrite: Indicates whether a register write operation is to be performed.
Opcode Decoding:

7'b0110011 (R-type): These instructions use two register operands and write the result back to a register.
7'b0000011 (Load): These instructions load data from memory into a register.
7'b0100011 (Store): These instructions store data from a register into memory.
7'b0010011 (I-type): These instructions use an immediate value for ALU operations.
7'b1100011 (Branch): These instructions perform branch operations based on the comparison of two register values.
This control unit will generate the appropriate control signals based on the opcode of the instruction being executed.
*/

module ControlUnit (
    input wire clk,          // Clock signal
    input wire reset_n,      // Active-low reset signal
    input [6:0] opcode,      // Opcode input
    output reg [1:0] ALUOp,  // ALU operation control signal
    output reg MemRead,      // Memory read control signal
    output reg MemtoReg,     // Memory to register control signal
    output reg MemWrite,     // Memory write control signal
    output reg ALUSrc,       // ALU source control signal
    output reg RegWrite      // Register write control signal
);

    // Control signal logic based on opcode
    always @(*) begin
        case (opcode)
            7'b0110011: begin // R-type
                ALUOp = 2'b10;
                MemRead = 0;
                MemtoReg = 0;
                MemWrite = 0;
                ALUSrc = 0;
                RegWrite = 1;
            end
            7'b0000011: begin // Load
                ALUOp = 2'b00;
                MemRead = 1;
                MemtoReg = 1;
                MemWrite = 0;
                ALUSrc = 1;
                RegWrite = 1;
            end
            7'b0100011: begin // Store
                ALUOp = 2'b00;
                MemRead = 0;
                MemtoReg = 0;
                MemWrite = 1;
                ALUSrc = 1;
                RegWrite = 0;
            end
            7'b0010011: begin // I-type (Immediate ALU Operations)
                ALUOp = 2'b11;
                MemRead = 0;
                MemtoReg = 0;
                MemWrite = 0;
                ALUSrc = 1;
                RegWrite = 1;
            end
            7'b1100011: begin // Branch
                ALUOp = 2'b01;
                MemRead = 0;
                MemtoReg = 0;
                MemWrite = 0;
                ALUSrc = 0;
                RegWrite = 0;
            end
            default: begin // Default case to handle undefined opcodes
                ALUOp = 2'b00;
                MemRead = 0;
                MemtoReg = 0;
                MemWrite = 0;
                ALUSrc = 0;
                RegWrite = 0;
            end
        endcase
    end

    // Reset logic to initialize control signals
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            ALUOp <= 2'b00;
            MemRead <= 0;
            MemtoReg <= 0;
            MemWrite <= 0;
            ALUSrc <= 0;
            RegWrite <= 0;
        end
    end

endmodule