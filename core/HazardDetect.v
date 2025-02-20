/* 
data-hazard
    forwarding
    stall
control-hazard
    prediction & flush

*/

module HazardDetectionUnit (
    input wire [4:0] ID_EX_Rs1,    // Source register 1 from ID/EX stage
    input wire [4:0] ID_EX_Rs2,    // Source register 2 from ID/EX stage

    input wire [4:0] EX_MEM_Rd,    // Destination register from EX/MEM stage
    input wire EX_MEM_RegWrite,    // Register write signal from EX/MEM stage
    input wire EX_MEM_MemRead,     // Memory read signal from EX/MEM stage

    input wire [4:0] MEM_WB_Rd,    // Destination register from MEM/WB stage
    input wire MEM_WB_RegWrite,    // Register write signal from MEM/WB stage

    input wire [4:0] WB_Rd,        // Destination register from WB stage
    input wire WB_RegWrite,        // Register write signal from WB stage

    input wire [4:0] MEM_Rs2,      // Source register 2 from MEM stage

    input wire branch_mispredict,  // Signal indicating if a branch was mispredicted
    
    output reg [1:0] hazard_forwardA, // Forwarding control for Rs1
    output reg [1:0] hazard_forwardB, // Forwarding control for Rs2
    output reg hazard_stall,           // Signal to stall the pipeline
    output reg hazard_flush,           // Signal to flush the pipeline
    output reg [1:0] hazard_forward_mem // Forwarding control for MEM write data
);

    always @(*) begin
        // Initialize forwarding controls
        hazard_forwardA = 2'b00;
        hazard_forwardB = 2'b00;
        hazard_forward_mem = 2'b00;

        // EX stage forwarding
        if (EX_MEM_RegWrite && (EX_MEM_Rd != 0)) begin
            if (EX_MEM_Rd == ID_EX_Rs1) 
                hazard_forwardA = 2'b01;
            if (EX_MEM_Rd == ID_EX_Rs2) 
                hazard_forwardB = 2'b01;
        end

        if (MEM_WB_RegWrite && (MEM_WB_Rd != 0)) begin
            if (MEM_WB_Rd == ID_EX_Rs1) 
                hazard_forwardA = 2'b10;
            if (MEM_WB_Rd == ID_EX_Rs2) 
                hazard_forwardB = 2'b10;
        end

        if (WB_RegWrite && (WB_Rd != 0)) begin
            if (WB_Rd == ID_EX_Rs1) 
                hazard_forwardA = 2'b11;
            if (WB_Rd == ID_EX_Rs2) 
                hazard_forwardB = 2'b11;
        end

        // MEM write data forwarding
        if (MEM_WB_RegWrite && (MEM_WB_Rd != 0) && (MEM_WB_Rd == MEM_Rs2)) begin
            hazard_forward_mem = 2'b01;
        end else if (WB_RegWrite && (WB_Rd != 0) && (WB_Rd == MEM_Rs2)) begin
            hazard_forward_mem = 2'b10;
        end

        // Load-use hazard detection
        hazard_stall = 1'b0;  // Default: no stall
        if (EX_MEM_MemRead && (EX_MEM_Rd != 0) && 
            ((EX_MEM_Rd == ID_EX_Rs1) || (EX_MEM_Rd == ID_EX_Rs2))) begin
            // Stall due to load-use hazard
            hazard_stall = 1'b1;
        end
        
        // Control hazard detection
        hazard_flush = branch_mispredict;
    end

endmodule