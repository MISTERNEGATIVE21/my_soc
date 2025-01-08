/*
this sram for i/d cache

To transition the cache storage to SRAM, you can replace the reg arrays with SRAM modules. 
Here’s a simplified approach to modify the i-cache.v and d-cache.v files to use SRAM.

This change should improve the efficiency and scalability of your cache storage.

*/

module SRAM #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] wdata,
    input wire we,
    output reg [DATA_WIDTH-1:0] rdata
);
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk) begin
        if (we)
            mem[addr] <= wdata;
        else
            rdata <= mem[addr];
    end
endmodule