module rom #(
    parameter MEM_SIZE = 32 * 1024 // Example: 32KB memory size
) (
    input wire clk,
    input wire [31:0] addr,
    output reg [31:0] rdata
);

    // Internal memory array
    reg [31:0] mem [0:MEM_SIZE-1];

    initial begin
        // Load your ROM content here
        // $readmemh("rom_content.hex", mem);
    end

    always @(posedge clk) begin
        rdata <= mem[addr];
    end

endmodule