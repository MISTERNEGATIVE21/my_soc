/*

since ID_EX_MemRead need a register , which is better ： the regisger generate in stage2 or in core ?

Both approaches can work, but each has its advantages and considerations.

Option 1: Register in stage2_id.v
Advantages:
Encapsulation: Keeping the register within stage2_id.v encapsulates the logic related to the memory read signal within the stage that generates it. 
This can make the design more modular and easier to maintain.
Locality: The control signal is generated and stored within the same module, reducing the need for additional wiring and simplifying the overall design.
Disadvantages:
Complexity in Stage 2: Adding more state to stage2_id.v might increase the complexity of the module.

Option 2: Register in rv32i_core.v
Advantages:
Centralized Control: Storing the register in the core module keeps all pipeline registers in one place, 
making it easier to understand and manage the flow of data through the entire pipeline.
Consistency: It maintains consistency with how other pipeline registers are managed.
Disadvantages:
Wiring Complexity: It requires additional wiring to pass the control signal from stage2_id.v to the core module, 
which can increase the complexity of inter-module connections.

Recommendation:
Given these points, it often makes sense to keep pipeline registers centralized in the core module to maintain consistency 
and ease of understanding for the entire pipeline's flow of control signals. This approach is generally more common in pipeline designs.
 
*/

module ID_stage (
    // System signals
    input wire clk,
    input wire reset_n,

    // Global stall signal
    input wire hazard_flush,
    input wire hazard_stall,

    // From previous stage
    input wire [31:0] IF_ID_PC,
    input wire [31:0] IF_ID_Instruction,
    input wire IF_ID_jump_branch_taken,
    input wire IF_ID_enable_out,

    // Output to next stage
    output reg [31:0] ID_EX_PC,
    output reg ID_EX_jump_branch_taken,
    output reg [31:0] ID_EX_Immediate,
    output reg [4:0] ID_EX_Rs1,
    output reg [4:0] ID_EX_Rs2,
    output reg [4:0] ID_EX_Rd,
    output reg [6:0] ID_EX_Funct7,
    output reg [2:0] ID_EX_Funct3,

    // Control unit outputs
    output wire ID_EX_ALUSrc,
    output wire [1:0] ID_EX_ALUOp,
    output wire ID_EX_Branch,
    output wire ID_EX_Jump,
    output wire ID_EX_MemRead,
    output wire ID_EX_MemWrite,
    output wire ID_EX_MemToReg,
    output wire ID_EX_RegWrite,

    // Enable signal to next stage
    output reg ID_EX_enable_out
);

    wire [31:0] Immediate;
    wire [6:0] opcode = IF_ID_Instruction[6:0];

    // Instantiate ImmediateGenerator
    ImmediateGenerator imm_gen (
        .instruction(IF_ID_Instruction), // Input signal
        .immediate(Immediate)            // Output signal
    );

    // Instantiate ControlUnit
    ControlUnit cu (
        .opcode(opcode),                 // Input signal
        .ALUSrc(ID_EX_ALUSrc),           // Output signal
        .ALUOp(ID_EX_ALUOp),             // Output signal
        .Branch(ID_EX_Branch),           // Output signal
        .Jump(ID_EX_Jump),               // Output signal       
        .MemRead(ID_EX_MemRead),         // Output signal
        .MemWrite(ID_EX_MemWrite),       // Output signal
        .MemtoReg(ID_EX_MemToReg),       // Output signal
        .RegWrite(ID_EX_RegWrite)        // Output signal
    );

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            // Reset all pipeline registers
            ID_EX_PC <= 32'b0;
            ID_EX_Immediate <= 32'b0;
            ID_EX_Rs1 <= 5'b0;
            ID_EX_Rs2 <= 5'b0;
            ID_EX_Rd <= 5'b0;
            ID_EX_Funct7 <= 7'b0;
            ID_EX_Funct3 <= 3'b0;
            ID_EX_enable_out <= 1'b0;
        end else if (hazard_flush) begin
            // Clear IF/ID stage
            ID_EX_PC <= 32'b0;
            ID_EX_Immediate <= 32'b0;
            ID_EX_Rs1 <= 5'b0;
            ID_EX_Rs2 <= 5'b0;
            ID_EX_Rd <= 5'b0;
            ID_EX_Funct7 <= 7'b0;
            ID_EX_Funct3 <= 3'b0;
            ID_EX_enable_out <= 1'b0;
        end else if (hazard_stall) begin
            // Insert bubble (NOP) into the pipeline
            ID_EX_PC <= 32'b0;
            ID_EX_Immediate <= 32'b0;
            ID_EX_Rs1 <= 5'b0;
            ID_EX_Rs2 <= 5'b0;
            ID_EX_Rd <= 5'b0;
            ID_EX_Funct7 <= 7'b0;
            ID_EX_Funct3 <= 3'b0;
            ID_EX_enable_out <= 1'b0;
        end else if (IF_ID_enable_out) begin
            // Decode instruction
            ID_EX_PC <= IF_ID_PC;
            ID_EX_jump_branch_taken <= IF_ID_jump_branch_taken;
            ID_EX_Immediate <= Immediate;
            ID_EX_Rs1 <= IF_ID_Instruction[19:15];
            ID_EX_Rs2 <= IF_ID_Instruction[24:20];
            ID_EX_Rd <= IF_ID_Instruction[11:7];
            ID_EX_Funct7 <= IF_ID_Instruction[31:25];
            ID_EX_Funct3 <= IF_ID_Instruction[14:12];
            ID_EX_enable_out <= 1'b1;
        end else begin
            ID_EX_enable_out <= 1'b0; // Stall next stage
        end
    end

endmodule