

module MEM_stage (
    input wire clk,
    input wire reset,
    input wire [31:0] EX_MEM_ALUResult,
    input wire [31:0] EX_MEM_WriteData,
    input wire [4:0] EX_MEM_Rd,
    input wire EX_MEM_RegWrite,
    input wire MemRead,
    input wire MemWrite,
    input wire [31:0] HRDATA,
    input wire HREADY,
    input wire d_cache_ready,
    input wire d_cache_hit,
    input wire [31:0] d_cache_rdata,
    output reg [31:0] MEM_WB_ReadData,
    output reg [4:0] MEM_WB_Rd,
    output reg MEM_WB_RegWrite,
    output reg [31:0] HADDR,
    output reg [1:0] HTRANS,
    output reg HWRITE,
    output reg [31:0] HWDATA
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            MEM_WB_ReadData <= 0;
            MEM_WB_Rd <= 0;
            MEM_WB_RegWrite <= 0;
        end else begin
            if (MemRead) begin
                if (d_cache_ready && d_cache_hit) begin
                    MEM_WB_ReadData <= d_cache_rdata;
                end else if (HREADY) begin
                    HADDR <= EX_MEM_ALUResult;
                    HTRANS <= 2'b10; // NONSEQ
                    HWRITE <= 0;     // Read operation
                    MEM_WB_ReadData <= HRDATA;
                end
            end else if (MemWrite) begin
                if (d_cache_ready && d_cache_hit) begin
                    // Cache write handled in D-Cache
                end else if (HREADY) begin
                    HADDR <= EX_MEM_ALUResult;
                    HTRANS <= 2'b10; // NONSEQ
                    HWRITE <= 1;     // Write operation
                    HWDATA <= EX_MEM_WriteData;
                end
            end
            MEM_WB_Rd <= EX_MEM_Rd;
            MEM_WB_RegWrite <= EX_MEM_RegWrite;
        end
    end
endmodule