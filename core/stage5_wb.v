module WB_stage (
    // System signals
    input wire clk,               // Clock signal
    input wire reset_n,           // Asynchronous reset (active low)
    
    // Global stall and flush signals
    input wire hazard_stall,      // Hazard stall signal
    input wire hazard_flush,      // Hazard flush signal
    
    // Input from previous stage
    input wire [31:0] MEM_WB_PC,  // Program counter from MEM stage
    input wire [31:0] MEM_WB_ReadData, // Read data from MEM stage
    input wire [31:0] MEM_WB_ALUResult, // ALU result from MEM stage
    input wire [4:0] MEM_WB_Rd,   // Destination register from MEM stage
    input wire MEM_WB_RegWrite,   // Register write enable from MEM stage
    input wire MEM_WB_MemToReg,   // Memory to register signal from MEM stage
    
    // Enable signal from previous stage
    input wire MEM_WB_enable_out, // Enable signal from MEM stage

    // Output to next stage
    output reg WB_RegWrite,       // Register write enable to register file
    output reg [31:0] WB_WriteData, // Write data to register file
    output reg [4:0] WB_Rd,       // Destination register to register file
    output reg [31:0] WB_PC       // Program counter to next stage
);

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            // Reset logic
            WB_RegWrite <= 1'b0;   // Disable register write
            WB_WriteData <= 32'b0;
            WB_Rd <= 5'b0;
            WB_PC <= 32'b0;
        end else if (hazard_flush) begin
            // Handle hazard flush
            WB_RegWrite <= 1'b0;   // Disable register write
            WB_WriteData <= 32'b0;
            WB_Rd <= 5'b0;
            WB_PC <= 32'b0;
        end else if (hazard_stall) begin
            // Stall the pipeline, maintain current state
            // Do nothing, keep the current state
        end else if (MEM_WB_enable_out) begin
            // Normal case
            WB_RegWrite <= MEM_WB_RegWrite;
            WB_WriteData <= MEM_WB_MemToReg ? MEM_WB_ReadData : MEM_WB_ALUResult;
            WB_Rd <= MEM_WB_Rd;
            WB_PC <= MEM_WB_PC;
            end else begin
            // MEM_WB_enable_out = 0; Disable next stage
            WB_RegWrite <= 1'b0;
            WB_WriteData <= 32'b0;
            WB_Rd <= 5'b0;
            WB_PC <= 32'b0;
        end
    end

endmodule