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
7'b0110111 (LUI): Load Upper Immediate
7'b0010111 (AUIPC): Add Upper Immediate to PC
7'b1101111 (JAL): Jump and Link
7'b1100111 (JALR): Jump and Link Register
7'b1100011 (Branch): Conditional Branch
7'b0000011 (Load): Load from Memory
7'b0100011 (Store): Store to Memory
7'b0010011 (I-type): Immediate ALU Operations
7'b0110011 (R-type): Register-Register ALU Operations
7'b0001111 (FENCE): Fence
7'b1110011 (SYSTEM): System Instructions (ECALL, EBREAK, etc.)

This control unit will generate the appropriate control signals based on the opcode of the instruction being executed.

*/

module ControlUnit (
    input wire [6:0] opcode,      // Opcode input
    output reg ALUSrc,            // ALU source control signal, to ex-stage, alu
    output reg [1:0] ALUOp,       // ALU operation control signal, to ex-stage, alu
    output reg Branch,            // Branch control signal, to ex-stage, branch
    output reg Jump,              // Jump control signal, to ex-stage, branch
    output reg MemRead,           // Memory read control signal, to mem-stage, read  
    output reg MemWrite,          // Memory write control signal, to mem-stage, write
    output reg MemtoReg,          // Memory to register control signal, to wb-stage, write-source select
    output reg RegWrite           // Register write control signal, to wb-stage, write-enable
);

    // Control signal logic based on opcode
    always @(*) begin
        // 默认情况下将所有控制信号设为 0，以避免锁存器
        RegWrite = 0;
        MemRead = 0;
        MemWrite = 0;
        Branch = 0;
        Jump = 0;
        ALUSrc = 0;
        ALUOp = 2'b00;
        MemtoReg = 0;

        case (opcode)
            7'b0110111: begin // LUI
                ALUOp = 2'b00;
                ALUSrc = 1;
                RegWrite = 1;
            end
            7'b0010111: begin // AUIPC
                ALUOp = 2'b00;
                ALUSrc = 1;
                RegWrite = 1;
            end
            7'b1101111: begin // JAL
                ALUOp = 2'b00;
                ALUSrc = 1;
                RegWrite = 1;
                Jump = 1;
            end
            7'b1100111: begin // JALR
                ALUOp = 2'b00;
                ALUSrc = 1;
                RegWrite = 1;
                Jump = 1;
            end
            7'b1100011: begin // Branch
                ALUOp = 2'b01;
                Branch = 1;
            end
            7'b0000011: begin // Load
                ALUOp = 2'b00;
                ALUSrc = 1;
                MemRead = 1;
                MemtoReg = 1;
                RegWrite = 1;
            end
            7'b0100011: begin // Store
                ALUOp = 2'b00;
                ALUSrc = 1;
                MemWrite = 1;
            end
            7'b0010011: begin // I-type
                ALUOp = 2'b11;
                ALUSrc = 1;
                RegWrite = 1;
            end
            7'b0110011: begin // R-type
                ALUOp = 2'b10;
                RegWrite = 1;
            end
            7'b0001111: begin // FENCE
                // No control signals needed for FENCE
            end
            7'b1110011: begin // SYSTEM
                // No control signals needed for SYSTEM instructions
            end
            default: begin
                // 默认情况下所有控制信号已经设为 0
            end
        endcase
    end

endmodule