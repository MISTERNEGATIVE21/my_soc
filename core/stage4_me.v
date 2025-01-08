/*
Explanation

Inputs:
d_cache_rdata: Data read from the D-Cache.
d_cache_ready: Signal indicating the D-Cache is ready.
d_cache_hit: Signal indicating a cache hit.
Other inputs include clk, reset, execute_enable_out, EX_MEM_ALUResult, EX_MEM_WriteData, EX_MEM_Rd, EX_MEM_RegWrite, MemRead, MemWrite, and combined_stall.

Outputs:
MEM_WB_ReadData: Data to be written back.
MEM_WB_Rd: Destination register for write-back.
MEM_WB_RegWrite: Signal for register write-back.
memory_enable_out: Signal to enable the memory stage for the next stage.

Stall Signal: 
A new output signal mem_stall is introduced to indicate when the pipeline should be stalled.

Reset Condition: 
On reset, all signals, including mem_stall, are cleared.

Combined Stall Condition: 
If combined_stall is asserted, a NOP is inserted into the pipeline, and mem_stall is set to 1 to stall the pipeline.

Memory Read Operation:
If MemRead is true and the D-Cache signals a hit, MEM_WB_ReadData is set to d_cache_rdata, memory_enable_out is set to 1, and mem_stall is set to 0.
If MemRead is true and the D-Cache signals a miss but is ready, memory_enable_out is set to 0, and mem_stall is set to 1 to stall the pipeline.
If MemRead is true and the D-Cache is not ready, memory_enable_out is set to 0, and mem_stall is set to 1 to stall the pipeline.

Memory Write Operation:
If MemWrite is true and the D-Cache signals a hit, the write is handled by the D-Cache, memory_enable_out is set to 1, and mem_stall is set to 0.
If MemWrite is true and the D-Cache signals a miss but is ready, memory_enable_out is set to 0, and mem_stall is set to 1 to stall the pipeline.
If MemWrite is true and the D-Cache is not ready, memory_enable_out is set to 0, and mem_stall is set to 1 to stall the pipeline.

No Memory Operation:
If both MemRead and MemWrite are false, then memory_enable_out is set to 1 to allow the instruction to progress to the Write-Back (WB) stage without being blocked, and mem_stall is set to 0.

Pass-through Register Write Signals:
The MEM_WB_Rd and MEM_WB_RegWrite signals are updated only if mem_stall is not asserted. This ensures that these signals are correctly passed through to the WB stage only when the memory stage is not stalled.

*/

module MEM_stage (
    input wire clk,
    input wire reset,
    input wire execute_enable_out, // Updated input from execute stage
    input wire [31:0] EX_MEM_ALUResult,
    input wire [31:0] EX_MEM_WriteData,
    input wire [4:0] EX_MEM_Rd,
    input wire EX_MEM_RegWrite,
    input wire MemRead,
    input wire MemWrite,
    input wire d_cache_ready,
    input wire d_cache_hit,
    input wire [31:0] d_cache_rdata,   
    input wire combined_stall,
    output reg [31:0] MEM_WB_ReadData,
    output reg [4:0] MEM_WB_Rd,
    output reg MEM_WB_RegWrite,
    output reg memory_enable_out,
    output reg mem_stall // Updated output to signal pipeline stall
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            MEM_WB_ReadData <= 32'b0;
            MEM_WB_Rd <= 5'b0;
            MEM_WB_RegWrite <= 1'b0;
            memory_enable_out <= 1'b0;
            mem_stall <= 1'b0; // Clear stall signal on reset
        end else if (combined_stall) begin
            // Insert bubble (NOP) into the pipeline
            MEM_WB_ReadData <= 32'b0;
            MEM_WB_Rd <= 5'b0;
            MEM_WB_RegWrite <= 1'b0;
            memory_enable_out <= 1'b0;
            mem_stall <= 1'b1; // Stall pipeline on combined stall
        end else if (execute_enable_out) begin
            if (MemRead) begin
                if (d_cache_ready && d_cache_hit) begin
                    // Cache hit: read data from D-Cache
                    MEM_WB_ReadData <= d_cache_rdata;
                    memory_enable_out <= 1'b1; // Data is ready
                    mem_stall <= 1'b0; // No need to stall
                end else if (d_cache_ready && !d_cache_hit) begin
                    // Cache miss: wait for D-Cache to handle the miss
                    memory_enable_out <= 1'b0; // Wait for D-Cache
                    mem_stall <= 1'b1; // Stall pipeline
                end else begin
                    // D-Cache not ready
                    memory_enable_out <= 1'b0; // Wait for D-Cache
                    mem_stall <= 1'b1; // Stall pipeline
                end
            end else if (MemWrite) begin
                if (d_cache_ready && d_cache_hit) begin
                    // Cache write handled in D-Cache
                    memory_enable_out <= 1'b1; // Write complete
                    mem_stall <= 1'b0; // No need to stall
                end else if (d_cache_ready && !d_cache_hit) begin
                    // Cache miss: wait for D-Cache to handle the miss
                    memory_enable_out <= 1'b0; // Wait for D-Cache
                    mem_stall <= 1'b1; // Stall pipeline
                end else begin
                    // D-Cache not ready
                    memory_enable_out <= 1'b0; // Wait for D-Cache
                    mem_stall <= 1'b1; // Stall pipeline
                end
            end else begin
                // No memory operation
                memory_enable_out <= 1'b1; // Allow progression to WB stage
                mem_stall <= 1'b0; // No need to stall
            end

            // Pass-through register write signals only if not stalled
            if (!mem_stall) begin
                MEM_WB_Rd <= EX_MEM_Rd;
                MEM_WB_RegWrite <= EX_MEM_RegWrite;
            end
			
        end else begin
            memory_enable_out <= 1'b0; // Disable next stage advance
            mem_stall <= 1'b0; // Clear stall signal
        end
    end
endmodule