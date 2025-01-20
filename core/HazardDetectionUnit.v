/* 
To handle hazards in your RV32I core, you can add a hazard detection unit. 
This module will identify data hazards and insert NOP instructions (or stall the pipeline) to resolve them 

The hazard detection unit will monitor the pipeline registers to detect hazards and control the pipeline accordingly.

In a typical 5-stage pipeline (Fetch, Decode, Execute, Memory, Write-back), the pipeline control logic to handle stalls 
due to hazards is usually placed in the Decode (ID) stage. 
This is because the Decode stage has access to the instruction being decoded and can thus detect hazards early 
enough to prevent issues in subsequent stages.

*/

module HazardDetectionUnit (
    input wire clk,                // Clock signal
    input wire reset_n,            // Active-low reset signal
    input wire [4:0] ID_EX_Rs1,
    input wire [4:0] ID_EX_Rs2,
    input wire [4:0] EX_MEM_Rd,
    input wire EX_MEM_RegWrite,
    input wire [4:0] MEM_WB_Rd,
    input wire MEM_WB_RegWrite,
    input wire branch_taken,       // Signal indicating if a branch is taken
    input wire branch_mispredict,  // Signal indicating if a branch was mispredicted
    output reg hazard_stall,
    output reg flush_pipeline      // Signal to flush the pipeline
);

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            hazard_stall <= 0;
            flush_pipeline <= 0;
        end else begin
            // Data hazard detection
            if ((EX_MEM_RegWrite && (EX_MEM_Rd != 0) && ((EX_MEM_Rd == ID_EX_Rs1) || (EX_MEM_Rd == ID_EX_Rs2))) ||
                (MEM_WB_RegWrite && (MEM_WB_Rd != 0) && ((MEM_WB_Rd == ID_EX_Rs1) || (MEM_WB_Rd == ID_EX_Rs2)))) begin
                hazard_stall <= 1;
            end else begin
                hazard_stall <= 0;
            end
            
            // Control hazard detection
            if (branch_mispredict) begin
                flush_pipeline <= 1;
            end else begin
                flush_pipeline <= 0;
            end
        end
    end
endmodule