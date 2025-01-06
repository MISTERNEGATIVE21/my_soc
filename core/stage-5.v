module WB_stage (
    input wire clk,
    input wire reset,
    input wire MEM_WB_RegWrite,
    input wire [31:0] MEM_WB_ReadData,
    input wire [4:0] MEM_WB_Rd,
    input wire [31:0] EX_MEM_ALUResult,
    input wire MemtoReg,
    output reg [31:0] regfile [0:31]
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset logic
        end else begin
            if (MEM_WB_RegWrite) begin
                regfile[MEM_WB_Rd] <= (MemtoReg) ? MEM_WB_ReadData : EX_MEM_ALUResult;
            end
        end
    end
endmodule