/* Summary of Changes:
fetch_enable and IF_ID_enable_out are not necessarily the same.

fetch_enable is an input signal that indicates whether the instruction fetch stage should proceed with fetching the next instruction.
IF_ID_enable_out is an output signal that can be used to indicate the status of the fetch stage, such as whether the fetch stage is ready to 
fetch the next instruction or needs to stall.

Bubble Insertion: Added logic to insert a NOP instruction (32'h00000013) into the pipeline when combined_stall is asserted.
Reset Logic: Ensured the pipeline registers are reset to initial values, including the NOP instruction for IF_ID_Instruction.
fetch_enable Handling: Updated the handling of fetch_enable and IF_ID_enable_out signals to control whether fetching should continue or stall.
Program Counter Update: Added a separate always block to update the PC based on the fetch_enable and combined_stall signals.
This implementation ensures that the instruction is fetched from the cache when there is a hit, a NOP instruction is inserted into the pipeline
when a stall condition is detected, and the fetch_enable signal is properly controlled. 

cache-miss:
Redundant AHB accesses during a cache miss are generally detrimental to performance. 
It is important to ensure that only the I-cache initiates memory accesses during a cache miss and that the IF stage waits for the cache to signal readiness. 
This approach avoids bus contention, reduces latency, and ensures efficient use of memory resources.

*/
module IF_stage (
    input wire clk,
    input wire reset_n,              // Active-low reset signal
    input wire fetch_enable,
    input wire combined_stall, // New input for combined stall signal
    input wire [31:0] PC,
    input wire i_cache_ready,
    input wire i_cache_hit,
    input wire [31:0] i_cache_rdata,   
    output reg [31:0] IF_ID_PC,
    output reg [31:0] IF_ID_Instruction,
    output reg IF_ID_enable_out
);

    reg [31:0] next_PC;

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            IF_ID_PC <= 32'b0;
            IF_ID_Instruction <= 32'h00000013; // NOP instruction
            IF_ID_enable_out <= 1'b0;
            next_PC <= 32'b0;
        end else if (combined_stall) begin
            // Insert bubble (NOP) into the pipeline
            IF_ID_Instruction <= 32'h00000013; // NOP instruction
            IF_ID_enable_out <= 1'b0; // Stall fetching
        end else if (fetch_enable) begin
                if (i_cache_ready && i_cache_hit) begin
                    // Cache hit: Fetch instruction from cache
                    IF_ID_PC <= PC;
                    IF_ID_Instruction <= i_cache_rdata;
                    next_PC <= PC + 4;
                    IF_ID_enable_out <= 1'b1; // Continue fetching
            end else begin
                // i Cache miss or not ready: IF_ID_enable_out set to 0; next stage will not advance, so there's no need to out a stall like d-cache miss
                IF_ID_enable_out <= 1'b0;
                end               
        end else begin
            IF_ID_enable_out <= 1'b0; // Stall fetching
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            next_PC <= 32'b0;
        end else if (!combined_stall && fetch_enable && (i_cache_ready && i_cache_hit)) begin
            next_PC <= PC + 4; // Update PC if not stalling and fetch is enabled
        end
    end
endmodule