module sram #(
    parameter MEM_SIZE = 32 * 1024 // Example: 32KB memory size
) (
    input wire clk,
    input wire [31:0] addr,
    input wire [31:0] wdata,
    input wire write_enable,
    output reg [31:0] rdata
);

    // Internal memory array
    reg [31:0] mem [0:MEM_SIZE-1];

    always @(posedge clk) begin
        if (write_enable) begin
            mem[addr] <= wdata;
        end
        rdata <= mem[addr];
    end

endmodule