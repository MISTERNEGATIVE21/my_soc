/* Summary of Changes:
 fetch inst from i_memory
*/
module IF_stage (
    // System signals
    input wire clk,               // Clock signal
    input wire reset_n,           // Asynchronous reset (active low)
    
    // Global stall signal
    input wire combined_stall,    // Combined stall signal
    input wire hazard_flush,      // Branch or jump, clear IF/ID stage
    input wire [31:0] next_pc,    // Next program counter value for flush

    // Enable signals from previous stage
    input wire fetch_enable,      // Fetch enable signal for hazard control
    
    // Branch Prediction Unit output
    input wire [1:0] hazard_stall,      // hazard stall stage
    input wire hazard_flush,      // Branch or jump, clear IF/ID stage
    input wire [31:0] next_pc,    // Next program counter value for flush
    input wire branch_prediction, // Branch prediction signal
    
    // Output to next stage
    output reg [31:0] IF_ID_PC,          // Program counter ID stage
    output reg [31:0] IF_ID_Instruction, // Instruction ID stage
    output reg IF_ID_jump_branch_taken   // Branch or jump taken signal ID stage
    output reg IF_ID_enable_out,         // Enable signal for the next stage
);

    // Internal program counter register
    reg [31:0] pc;

    // Instantiate i_memory
    wire [31:0] i_memory_rdata;
    i_memory #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .MEM_DEPTH(1024)
    ) i_memory_inst (
        .clk(clk),
        .reset_n(reset_n),
        .addr(pc),
        .rdata(i_memory_rdata)
    );

    // Instantiate ImmediateGenerator generate immediate from inst to determine branch/jump target address
    wire [31:0] immediate;
    ImmediateGenerator imm_gen (
        .clk(clk),
        .reset_n(reset_n),
        .instruction(i_memory_rdata),
        .immediate(immediate)
    );

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            pc <= 32'b0;
            IF_ID_PC <= 32'b0;
            IF_ID_Instruction <= 32'b0;
            IF_ID_jump_branch_taken <= 1'b0;
            IF_ID_enable_out <= 1'b0;
        end else if (hazard_flush) begin
            // Flush condition
            pc <= next_pc;
            IF_ID_PC <= 32'b0;
            IF_ID_Instruction <= 32'b0;
            IF_ID_jump_branch_taken <= 1'b0;
            IF_ID_enable_out <= 1'b0;
        end else if (hazard_stall == 2'b00 || hazard_stall == 2'b01) begin
            // Stall the pipeline (hold current state)
            IF_ID_enable_out <= 1'b0;
            IF_ID_jump_branch_taken <= 1'b0;
        end else if (fetch_enable) begin
            // Fetch the instruction normally
            IF_ID_PC <= pc;
            IF_ID_Instruction <= i_memory_rdata;
            IF_ID_enable_out <= 1'b1;
            
            // Check if the instruction is a branch or jump and generate the predicted target address
            if (is_branch_instruction(i_memory_rdata)) begin
                if (branch_prediction) begin
                    pc <= pc + immediate; // Branch predict taken
                    IF_ID_jump_branch_taken <= 1'b1; // Indicate that a branch is taken
                end else begin
                    pc <= pc + 4; // Branch predict not taken
                    IF_ID_jump_branch_taken <= 1'b0;
                end
            end else if (is_jump_instruction(i_memory_rdata)) begin
                pc <= immediate; // Jump always taken
                IF_ID_jump_branch_taken <= 1'b1; // Indicate that a jump is taken
            end else begin
                pc <= pc + 4; // Normal instruction
                IF_ID_jump_branch_taken <= 1'b0;
            end
        end else begin
            IF_ID_enable_out <= 1'b0;
            IF_ID_jump_branch_taken <= 1'b0;
        end
    end

    // Function to determine if an instruction is a branch
    function is_branch_instruction(input [31:0] instruction);
        // Check if the instruction opcode matches branch opcodes (e.g., BEQ, BNE, etc.)
        reg [6:0] opcode;
        begin
            opcode = instruction[6:0];
            case (opcode)
                7'b1100011: is_branch_instruction = 1; // Example opcode for branch instructions
                default: is_branch_instruction = 0;
            endcase
        end
    endfunction

    // Function to determine if an instruction is a jump
    function is_jump_instruction(input [31:0] instruction);
        // Check if the instruction opcode matches jump opcodes (e.g., JAL, JALR)
        reg [6:0] opcode;
        begin
            opcode = instruction[6:0];
            case (opcode)
                7'b1101111, // JAL
                7'b1100111: // JALR
                    is_jump_instruction = 1;
                default:
                    is_jump_instruction = 0;
            endcase
        end
    endfunction

endmodule