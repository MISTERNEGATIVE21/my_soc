

module WB_stage (
    input wire clk,
    input wire reset_n,
    input wire MEM_WB_RegWrite,
    input wire [31:0] MEM_WB_ReadData,
    input wire [4:0] MEM_WB_Rd,
    input wire [31:0] EX_MEM_ALUResult,
    input wire MemtoReg,
    input wire combined_stall, // New input for combined stall signal
    input wire memory_enable_out, // Updated input from memory stage
    output reg [31:0] regfile [0:31]
);

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            // Reset logic
            integer i;
            for (i = 0; i < 32; i = i + 1) begin
                regfile[i] <= 32'b0;
            end
        end else if (combined_stall) begin
            // Insert bubble (NOP) into the pipeline
            // No operation needed, just stall the pipeline
        end else if (memory_enable_out) begin
            if (MEM_WB_RegWrite) begin
                regfile[MEM_WB_Rd] <= (MemtoReg) ? MEM_WB_ReadData : EX_MEM_ALUResult;
            end
        end
    end
endmodule