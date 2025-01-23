/* 
data-hazard
    forwarding
    stall
control-hazard
    prediction & flush

*/

module HazardDetectionUnit (
    input wire clk,                // Clock signal
    input wire reset_n,            // Active-low reset signal

    input wire [4:0] ID_EX_Rs1,    // Source register 1 from ID/EX stage
    input wire [4:0] ID_EX_Rs2,    // Source register 2 from ID/EX stage

    input wire [4:0] EX_MEM_Rd,    // Destination register from EX/MEM stage
    input wire EX_MEM_RegWrite,    // Register write signal from EX/MEM stage
    input wire EX_MEM_MemRead,    // Register write signal from EX/MEM stage

    input wire [4:0] MEM_WB_Rd,    // Destination register from MEM/WB stage
    input wire MEM_WB_RegWrite,    // Register write signal from MEM/WB stage

    input wire branch_mispredict,  // Signal indicating if a branch was mispredicted
    
    output reg [1:0] hazard_forwardA, // Forwarding control for Rs1
    output reg [1:0] hazard_forwardB  // Forwarding control for Rs2
    output reg hazard_stall, // Signal to stall the pipeline (0: no stall, 1: EX stage stall, 2: MEM stage stall)
    output reg hazard_flush,       // Signal to flush the pipeline
);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Reset signals
            hazard_stall <= 1'b0;
            hazard_flush <= 1'b0;
            hazard_forwardA <= 2'b00;
            hazard_forwardB <= 2'b00;
        end else begin
            // Initialize forwarding controls
            hazard_forwardA <= 2'b00;
            hazard_forwardB <= 2'b00;

            // EX stage forwarding
            if (EX_MEM_RegWrite && (EX_MEM_Rd != 0)) begin
                if (EX_MEM_Rd == ID_EX_Rs1) 
                    hazard_forwardA <= 2'b10;
                if (EX_MEM_Rd == ID_EX_Rs2) 
                    hazard_forwardB <= 2'b10;
            end

            // MEM stage forwarding
            if (MEM_WB_RegWrite && (MEM_WB_Rd != 0)) begin
                if (MEM_WB_Rd == ID_EX_Rs1) 
                    hazard_forwardA <= 2'b01;
                if (MEM_WB_Rd == ID_EX_Rs2) 
                    hazard_forwardB <= 2'b01;
            end

            // Load-use hazard detection
            hazard_stall <= 1'b0;  // Default: no stall
            if (EX_MEM_MemRead && (EX_MEM_Rd != 0) && 
                ((EX_MEM_Rd == ID_EX_Rs1) || (EX_MEM_Rd == ID_EX_Rs2))) begin
                // Stall due to load-use hazard
                hazard_stall <= 1'b1;
            end
            
            // Control hazard detection
            hazard_flush <= branch_mispredict;
        end
    end
endmodule