/* Explanation:
This module generates the immediate value based on the instruction type.

Inputs:
instruction: The 32-bit instruction from which the immediate value is to be extracted.

Outputs:
immediate: The 32-bit immediate value generated based on the instruction type.

Instruction Fields:
opcode: The 7-bit opcode field of the instruction.
imm_11_7, imm_31_20, imm_31_25_11_7, imm_31_12, imm_31_20_7_6: These are extracted fields from the instruction used to construct the immediate value.
Immediate Generation:

I-type and Load Instructions (7'b0010011, 7'b0000011):
The immediate value is formed by sign-extending the 12-bit immediate from bits [31:20].

S-type Instructions (7'b0100011):
The immediate value is formed by sign-extending the 12-bit immediate from bits [31:25] and [11:7].

B-type Instructions (7'b1100011):
The immediate value is formed by sign-extending the 13-bit immediate from bits [31], [7], [30:25], and [11:8], with the least significant bit being 0.

U-type Instructions (7'b0110111, 7'b0010111):
The immediate value is formed by taking the 20-bit immediate from bits [31:12] and shifting it left by 12 bits.

J-type Instructions (7'b1101111):
The immediate value is formed by sign-extending the 21-bit immediate from bits [31], [19:12], [20], and [30:21], with the least significant bit being 0.

Default Case:
If the opcode does not match any of the specified types, the immediate value is set to 0.
This implementation ensures that the ImmediateGenerator module correctly generates the immediate value based on the type of instruction being executed, 
following the RISC-V instruction set specifications. 

*/

module ImmediateGenerator (
    input wire clk,                // Clock signal
    input wire reset_n,            // Active-low reset signal
    input [31:0] instruction,
    output reg [31:0] immediate
);

    // Extract instruction fields
    wire [6:0] opcode = instruction[6:0];
    wire [4:0] imm_11_7 = instruction[11:7];
    wire [11:0] imm_31_20 = instruction[31:20];
    wire [11:0] imm_31_25_11_7 = {instruction[31:25], instruction[11:7]};
    wire [19:0] imm_31_12 = instruction[31:12];
    wire [11:0] imm_31_20_7_6 = {instruction[31], instruction[7], instruction[30:25], instruction[11:8]};

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            immediate <= 32'b0;
        end else begin
        case (opcode)
            7'b0010011, // I-type (ADDI, SLTI, etc.)
            7'b0000011: // Load (LB, LH, LW, etc.)
                immediate <= {{20{imm_31_20[11]}}, imm_31_20}; // Sign-extend 12-bit immediate

            7'b0100011: // S-type (Store: SB, SH, SW, etc.)
                immediate <= {{20{imm_31_25_11_7[11]}}, imm_31_25_11_7}; // Sign-extend 12-bit immediate

            7'b1100011: // B-type (Branch: BEQ, BNE, etc.)
                immediate <= {{19{imm_31_20_7_6[11]}}, imm_31_20_7_6, 1'b0}; // Sign-extend 13-bit immediate

            7'b0110111, // U-type (LUI)
            7'b0010111: // U-type (AUIPC)
                immediate <= {imm_31_12, 12'b0}; // 20-bit immediate shifted left by 12

            7'b1101111: // J-type (JAL)
                immediate <= {{11{imm_31_12[19]}}, imm_31_12[19:12], imm_31_12[20], imm_31_12[30:21], 1'b0}; // Sign-extend 21-bit immediate

            default: // Default case
                immediate <= 32'b0;
        endcase
        end
    end

endmodule