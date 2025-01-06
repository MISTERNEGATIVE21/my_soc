/* Summary of Changes:
fetch_enable and fetch_enable_out are not necessarily the same.

fetch_enable is an input signal that indicates whether the instruction fetch stage should proceed with fetching the next instruction.
fetch_enable_out is an output signal that can be used to indicate the status of the fetch stage, such as whether the fetch stage is ready to 
fetch the next instruction or needs to stall.


Bubble Insertion: Added logic to insert a NOP instruction (32'h00000013) into the pipeline when combined_stall is asserted.
Reset Logic: Ensured the pipeline registers are reset to initial values, including the NOP instruction for IF_ID_Instruction.
fetch_enable Handling: Updated the handling of fetch_enable and fetch_enable_out signals to control whether fetching should continue or stall.
Program Counter Update: Added a separate always block to update the PC based on the fetch_enable and combined_stall signals.
This implementation ensures that the instruction is fetched from the cache when there is a hit, a NOP instruction is inserted into the pipeline
when a stall condition is detected, and the fetch_enable signal is properly controlled. 

*/

module IF_stage (
    input wire clk,
    input wire reset,
    input wire fetch_enable,
    input wire [31:0] PC,
    input wire [31:0] HRDATA,
    input wire i_cache_ready,
    input wire i_cache_hit,
    input wire HREADY,
    input wire combined_stall, // New input for combined stall signal
    output reg [31:0] IF_ID_PC,
    output reg [31:0] IF_ID_Instruction,
    output reg [31:0] HADDR,
    output reg [1:0] HTRANS,
    output reg HWRITE,
    output reg fetch_enable_out // Output fetch_enable signal
);

    reg [31:0] next_PC;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            IF_ID_PC <= 32'b0;
            IF_ID_Instruction <= 32'h00000013; // NOP instruction
            HADDR <= 32'b0;
            HTRANS <= 2'b00; // IDLE
            HWRITE <= 1'b0; // Read operation
            fetch_enable_out <= 1'b0;
            next_PC <= 32'b0;
        end else if (combined_stall) begin
            // Insert bubble (NOP) into the pipeline
            IF_ID_Instruction <= 32'h00000013; // NOP instruction
            fetch_enable_out <= 1'b0;
        end else if (fetch_enable) begin
                if (i_cache_ready && i_cache_hit) begin
                    IF_ID_PC <= PC;
                    IF_ID_Instruction <= i_cache_rdata; // Fetch from cache on hit
                    next_PC <= PC + 4;
                    fetch_enable_out <= 1'b1; // Continue fetching
                end else if (HREADY) begin
                    IF_ID_PC <= PC;
                    IF_ID_Instruction <= HRDATA; // Fetch from HRDATA on miss
                    HADDR <= PC;
                    HTRANS <= 2'b10; // NONSEQ
                    HWRITE <= 1'b0; // Read operation
                    next_PC <= PC + 4;
                    fetch_enable_out <= 1'b1; // Continue fetching
                end else begin
                    fetch_enable_out <= 1'b0; // Stall fetching
                end               
        end else begin
            fetch_enable_out <= 1'b0; // Stall fetching
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC <= 32'b0;
        end else if (!combined_stall && fetch_enable) begin
            PC <= next_PC; // Update PC if not stalling and fetch is enabled
        end
    end
endmodule