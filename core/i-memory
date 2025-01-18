module i_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH = 1024
)(
    input wire clk,
    input wire reset_n,
    input wire [ADDR_WIDTH-1:0] addr, // Address from CPU
    output reg [DATA_WIDTH-1:0] rdata // Data to CPU
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

    // Read logic
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            rdata <= 0;
        end else begin
            rdata <= memory[addr >> 2]; // Assuming word-aligned addresses
        end
    end

endmodule