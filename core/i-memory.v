module i_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BASE_ADDR = 32'h00000000  // Base address parameter
    parameter MEM_DEPTH = 1024,
)(
    input wire clk,
    input wire reset_n,
    input wire [ADDR_WIDTH-1:0] addr, // Address from CPU
    output reg [DATA_WIDTH-1:0] rdata // Data to CPU
);

    // Memory array
    reg [7:0] memory [0:DATA_WIDTH*MEM_DEPTH/8-1];

    // Initialize memory (optional)
    initial begin
        integer i;
        for (i = 0; i < DATA_WIDTH*MEM_DEPTH/8; i = i + 1) begin
            memory[i] = 0;
        end
    end

    // Read logic
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            rdata <= 0;
        end else begin
            if (addr >= BASE_ADDR && addr < BASE_ADDR + (MEM_DEPTH << 2)) begin
                rdata <= memory[(addr - BASE_ADDR) >> 2]; // Assuming word-aligned addresses
            end else begin
                rdata <= 32'b0; // Output zero if address is out of range
            end
        end
    end

endmodule