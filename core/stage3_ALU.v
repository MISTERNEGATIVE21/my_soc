/* 
Explanation:
Inputs:

A: The first operand for the ALU operation.
B: The second operand for the ALU operation.
ALUControl: A 4-bit control signal that specifies the operation to be performed.
Outputs:

Result: The result of the ALU operation.
Zero: A flag that is set to high (1) if the result of the operation is zero, otherwise it is set to low (0).
Operations:

4'b0010: ADD - Adds operand A and B.
4'b0110: SUB - Subtracts operand B from A.
4'b0000: AND - Performs a bitwise AND operation between A and B.
4'b0001: OR - Performs a bitwise OR operation between A and B.
4'b0011: XOR - Performs a bitwise XOR operation between A and B.
4'b0100: SLL - Shifts A left by the number of positions specified in the lower 5 bits of B.
4'b0101: SRL - Shifts A right logically by the number of positions specified in the lower 5 bits of B.
4'b0117: SRA - Shifts A right arithmetically by the number of positions specified in the lower 5 bits of B.
4'b1000: SLT - Sets the result to 1 if A is less than B (signed comparison), otherwise sets the result to 0.
4'b1001: SLTU - Sets the result to 1 if A is less than B (unsigned comparison), otherwise sets the result to 0.
default: Sets the result to 0 for any undefined ALUControl codes.
Zero Flag:

The Zero flag is set to high (1) if the Result is zero, indicating that the operation resulted in zero. This is useful for branch instructions that depend on comparison results.
This implementation ensures that the ALU module can perform a variety of arithmetic and logical operations as specified by the control signals. 

*/

module ALU (
    input wire clk,           // Clock signal
    input wire reset_n,       // Active-low reset signal
    input [31:0] A,           // First operand
    input [31:0] B,           // Second operand
    input [4:0] ALUControl,   // Control signal indicating the operation to perform
    output reg [31:0] Result, // Result of the operation
    output reg Zero,          // Zero flag, indicates if the result is zero
    output reg Negative,      // Negative flag, indicates if the result is negative
    output reg Carry,         // Carry flag, indicates if there is a carry out
    output reg Overflow       // Overflow flag, indicates if there is an overflow
);

    always @(*) begin
        // 初始化标志位
        Zero = 1'b0;
        Negative = 1'b0;
        Carry = 1'b0;
        Overflow = 1'b0;

        case (ALUControl)
            5'b00010: Result = A + B;          // ADD
            5'b00110: Result = A - B;          // SUB
            5'b00000: Result = A & B;          // AND
            5'b00001: Result = A | B;          // OR
            5'b00011: Result = A ^ B;          // XOR
            5'b00100: Result = A << B[4:0];    // SLL (Shift Left Logical)
            5'b00101: Result = A >> B[4:0];    // SRL (Shift Right Logical)
            5'b00111: Result = A >>> B[4:0];   // SRA (Shift Right Arithmetic)
            5'b01000: Result = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0; // SLT (Set Less Than)
            5'b01001: Result = (A < B) ? 32'b1 : 32'b0; // SLTU (Set Less Than Unsigned)
            5'b01010: Result = B;              // LUI (直接输出 B)
            default: Result = 32'b0;          // Default case
        endcase

        // 设置标志位
        Zero = (Result == 32'b0);
        Negative = Result[31];
        Carry = (ALUControl == 5'b00010) && (A + B > 32'hFFFFFFFF);
        Overflow = (ALUControl == 5'b00010) && ((A[31] == B[31]) && (Result[31] != A[31]));

        // 单独处理 Overflow 标志位
        if (ALUControl == 5'b00010) begin
            Overflow = ((A[31] == B[31]) && (Result[31] != A[31])); // ADD 溢出
        end else if (ALUControl == 5'b00110) begin
            Overflow = ((A[31] != B[31]) && (Result[31] != A[31])); // SUB 溢出
        end else begin
            Overflow = 1'b0;
        end

    end

    // Reset logic to initialize Result and Zero
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            Result <= 32'b0;
            Zero <= 1'b0;
            Negative <= 1'b0;
            Carry <= 1'b0;
            Overflow <= 1'b0;
        end
    end

endmodule