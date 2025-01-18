/*
Explanation

Inputs:
Other inputs include clk, reset, 
EX_MEM_enable_out, 
EX_MEM_ALUResult, 
EX_MEM_WriteData, 
EX_MEM_Rd, 
EX_MEM_RegWrite, 
EX_MEM_MemRead, 
EX_MEM_MemWrite, 
d_cache_ready, 
d_cache_hit, 
combined_stall.

Outputs:
MEM_WB_ReadData: Data to be written back.
MEM_WB_Rd: Destination register for write-back.
MEM_WB_RegWrite: Signal for register write-back.
MEM_WB_enable_out: Signal to enable the memory stage for the next stage.

Stall Signal: 
A new output signal mem_stall is introduced to indicate when the pipeline should be stalled.

Reset Condition: 
On reset, all signals, including mem_stall, are cleared.

Combined Stall Condition: 
If combined_stall is asserted, a NOP is inserted into the pipeline, and mem_stall is set to 1 to stall the pipeline.

Memory Read Operation:
If EX_MEM_MemRead is true and the D-Cache signals a hit, MEM_WB_ReadData is set to d_cache_rdata, MEM_WB_enable_out is set to 1, and mem_stall is set to 0.
If EX_MEM_MemRead is true and the D-Cache signals a miss but is ready, MEM_WB_enable_out is set to 0, and mem_stall is set to 1 to stall the pipeline.
If EX_MEM_MemRead is true and the D-Cache is not ready, MEM_WB_enable_out is set to 0, and mem_stall is set to 1 to stall the pipeline.

Memory Write Operation:
If EX_MEM_MemWrite is true and the D-Cache signals a hit, the write is handled by the D-Cache, MEM_WB_enable_out is set to 1, and mem_stall is set to 0.
If EX_MEM_MemWrite is true and the D-Cache signals a miss but is ready, MEM_WB_enable_out is set to 0, and mem_stall is set to 1 to stall the pipeline.
If EX_MEM_MemWrite is true and the D-Cache is not ready, MEM_WB_enable_out is set to 0, and mem_stall is set to 1 to stall the pipeline.

No Memory Operation:
If both EX_MEM_MemRead and EX_MEM_MemWrite are false, then MEM_WB_enable_out is set to 1 to allow the instruction to progress to the Write-Back (WB) stage without being blocked, and mem_stall is set to 0.

Pass-through Register Write Signals:
The MEM_WB_Rd and MEM_WB_RegWrite signals are updated only if mem_stall is not asserted. This ensures that these signals are correctly passed through to the WB stage only when the memory stage is not stalled.
*/

module MEM_stage_cache (
    input wire clk,               // Clock signal
    input wire reset_n,           // Asynchronous reset (active low)
    input wire EX_MEM_enable_out, // Enable signal from the execute stage
    input wire [31:0] EX_MEM_ALUResult, // ALU result from the execute stage (address for memory operations or register write content)
    input wire [31:0] EX_MEM_WriteData, // Write data from the execute stage (send to D-Cache already, not used here)
    input wire [4:0] EX_MEM_Rd,   // Destination register from the execute stage
    input wire EX_MEM_RegWrite,   // Register write enable signal from the execute stage
    input wire EX_MEM_MemRead,    // Memory read enable signal from the execute stage
    input wire EX_MEM_MemWrite,   // Memory write enable signal from the execute stage
    input wire d_cache_ready,     // D-Cache ready signal
    input wire d_cache_hit,       // D-Cache hit signal
    input wire [31:0] d_cache_rdata, // Data read from the D-Cache
    input wire combined_stall,    // Combined stall signal
    output reg [31:0] MEM_WB_PC,  // Program counter to WB stage
    output reg [31:0] MEM_WB_ReadData, // Data to be written back to the register file
    output reg [31:0] MEM_WB_ALUResult, // ALU result to be passed to the next stage
    output reg [4:0] MEM_WB_Rd,        // Destination register for write-back
    output reg MEM_WB_RegWrite,        // Register write enable signal for write-back
    output reg MEM_WB_enable_out,      // Enable signal for the memory stage
    output reg mem_stall               // Stall signal for the pipeline
);

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            MEM_WB_ReadData <= 32'b0;
            MEM_WB_Rd <= 5'b0;
            MEM_WB_RegWrite <= 1'b0;
            MEM_WB_enable_out <= 1'b0;
            mem_stall <= 1'b0; // Clear stall signal on reset
        end else if (combined_stall) begin
            // Insert bubble (NOP) into the pipeline
            MEM_WB_PC <= 32'b0;
            MEM_WB_ReadData <= 32'b0;
            MEM_WB_ALUResult <= 32'b0;
            MEM_WB_Rd <= 5'b0;
            MEM_WB_RegWrite <= 1'b0;
            MEM_WB_enable_out <= 1'b0;
            // Do not set mem_stall here to avoid deadlock
        end else if (EX_MEM_enable_out) begin
            if (EX_MEM_MemRead) begin
                if (d_cache_ready && d_cache_hit) begin
                    // Cache hit: read data from D-Cache
                    MEM_WB_ReadData <= d_cache_rdata;
                    MEM_WB_enable_out <= 1'b1; // Data is ready
                    mem_stall <= 1'b0; // No need to stall
                end else if (d_cache_ready && !d_cache_hit) begin
                    // Cache miss: wait for D-Cache to handle the miss
                    MEM_WB_enable_out <= 1'b0; // Wait for D-Cache
                    mem_stall <= 1'b1; // Stall pipeline
                end else begin
                    // D-Cache not ready
                    MEM_WB_enable_out <= 1'b0; // Wait for D-Cache
                    mem_stall <= 1'b1; // Stall pipeline
                end
            end else if (EX_MEM_MemWrite) begin
                if (d_cache_ready && d_cache_hit) begin
                    // Cache write handled in D-Cache
                    MEM_WB_enable_out <= 1'b1; // Write complete
                    mem_stall <= 1'b0; // No need to stall
                end else if (d_cache_ready && !d_cache_hit) begin
                    // Cache miss: wait for D-Cache to handle the miss
                    MEM_WB_enable_out <= 1'b0; // Wait for D-Cache
                    mem_stall <= 1'b1; // Stall pipeline
                end else begin
                    // D-Cache not ready
                    MEM_WB_enable_out <= 1'b0; // Wait for D-Cache
                    mem_stall <= 1'b1; // Stall pipeline
                end
            end else begin
                // No memory operation
                MEM_WB_enable_out <= 1'b1; // Allow progression to WB stage
                mem_stall <= 1'b0; // No need to stall
            end

            // Pass-through register write signals only if not stalled
            if (!mem_stall) begin
                MEM_WB_PC <= EX_MEM_PC;
                MEM_WB_ALUResult <= EX_MEM_ALUResult;
                MEM_WB_Rd <= EX_MEM_Rd;
                MEM_WB_RegWrite <= EX_MEM_RegWrite;
            end
        end else begin
            MEM_WB_enable_out <= 1'b0; // Disable next stage advance
            mem_stall <= 1'b0; // Clear stall signal
        end
    end
endmodule