module d_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BASE_ADDR = 32'h0001_0000  // Base address parameter
    parameter MEM_DEPTH = 1024,
)(
    input wire clk,
    input wire reset_n,
    input wire mem_read,          // Memory read enable signal
    input wire mem_write,         // Memory write enable signal
    input wire [ADDR_WIDTH-1:0] addr, // Address from CPU
    input wire [DATA_WIDTH-1:0] wdata, // Data to be written to memory
    output reg [DATA_WIDTH-1:0] rdata // Data read from memory
);

    // Memory array
    reg [DATA_WIDTH-1:0] memory [0:MEM_DEPTH-1];

    // Initialize memory (optional)
    initial begin
        integer i;
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            memory[i] = 0;
        end
    end

    // Read and write logic
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            rdata <= 0;
        end else begin
            if (addr >= BASE_ADDR && addr < BASE_ADDR + (MEM_DEPTH << 2)) begin
            if (mem_read) begin
                    rdata <= memory[(addr - BASE_ADDR) >> 2]; // Assuming word-aligned addresses
            end
            if (mem_write) begin
                    memory[(addr - BASE_ADDR) >> 2] <= wdata; // Assuming word-aligned addresses
                end
            end else begin
                rdata <= 32'b0; // Output zero if address is out of range
            end
        end
    end

endmodule
