

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
    output reg HWRITE
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC <= 32'b0;
            fetch_enable <= 1'b0;
        end else if (!combined_stall) begin
            if (fetch_enable) begin
                if (i_cache_ready && i_cache_hit) begin
                    IF_ID_PC <= PC;
                    IF_ID_Instruction <= i_cache_rdata;
                    PC <= PC + 4;
                end else if (HREADY) begin
                    IF_ID_PC <= PC;
                    IF_ID_Instruction <= HRDATA;
                    HADDR <= PC;
                    HTRANS <= 2'b10; // NONSEQ
                    HWRITE <= 0;     // Read operation
                    PC <= PC + 4;
                end               
            end
            fetch_enable <= 1'b1;
        end else begin
            fetch_enable <= 1'b0;
        end
    end
endmodule