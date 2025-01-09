module AHB_SRAM_Slave #(
    parameter BASE_ADDR = 32'h0010_0000 // Default base address       
    parameter SIZE = 256 // Default size is 256 words
)(
    input wire HCLK,         // AHB system clock
    input wire HRESETn,      // AHB system reset (active low)
    input wire [31:0] HADDR, // AHB address
    input wire [2:0] HBURST, // Burst type (not used in this example)
    input wire HMASTLOCK,    // Master lock signal (not used in this example)
    input wire [3:0] HPROT,  // Protection control (not used in this example)
    input wire [2:0] HSIZE,  // Transfer size (not used in this example)
    input wire [1:0] HTRANS, // Transfer type
    input wire HWRITE,       // Transfer direction (write=1, read=0)
    input wire [31:0] HWDATA,// Write data
    output reg [31:0] HRDATA,// Read data
    output reg HREADY,       // Transfer done
    output reg HRESP         // Transfer response (0=OKAY, 1=ERROR)
);

    // Instantiate the new SRAM module
    wire [31:0] sram_data_out;
    reg [31:0] sram_data_in;
    reg sram_we;
    reg [clog2(SIZE)-1:0] sram_addr;

    // New SRAM instance
    sram_ahb #(
        .SIZE(SIZE)
    ) sram_inst (
        .clk(HCLK),
        .we(sram_we),
        .addr(sram_addr),
        .data_in(sram_data_in),
        .data_out(sram_data_out)
    );

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HRDATA <= 32'b0;
            HREADY <= 1'b1;
            HRESP <= 1'b0;
            sram_we <= 1'b0;
        end else begin
            // Default values
            HREADY <= 1'b1;
            HRESP <= 1'b0; // OKAY response
            sram_we <= 1'b0;
            sram_addr <= (HADDR - BASE_ADDR) >> 2; // Adjust address width

            // Check if the address is within the SRAM range
            if (HTRANS != 2'b00 && HADDR >= BASE_ADDR && HADDR < BASE_ADDR + (SIZE * 4)) begin
                if (HWRITE) begin
                    // Write operation
                    sram_data_in <= HWDATA;
                    sram_we <= 1'b1;
                end else begin
                    // Read operation
                    HRDATA <= sram_data_out;
                end
            end
        end
    end

endmodule

// Function to calculate the ceiling of logarithm base 2
function integer clog2;
    input integer value;
    integer result;
    begin
        result = 0;
        while ((2 ** result) < value) begin
            result = result + 1;
        end
        clog2 = result;
    end
endfunction

/*
Yes, 
it is entirely possible to define and use two different SRAM modules in your design, each serving a different purpose. 
The SRAM module you already have in my_soc/core/sram.v for cache can remain unchanged, 
and you can define another SRAM module specifically for the AHB_SRAM_Slave with initialization from a hex file.
Here is an example of how you can incorporate the existing SRAM module for the cache and define a new SRAM module for the AHB_SRAM_Slave:    

In Verilog, 
the declaration reg [31:0] memory [0:SIZE-1] is typically used to model RAM or ROM in a behavioral simulation. 
When you synthesize your design using tools like Vivado, the tool will infer the appropriate hardware implementation (such as block RAM, distributed RAM, or ROM) 
based on the usage of the memory and the synthesis constraints.  

If the memory is only read and never written to during operation, synthesis tools can infer it as ROM.

*/

module sram_ahb #(
    parameter SIZE = 256 // Default size is 256 words
)(
    input wire clk,
    input wire we,
    input wire [$clog2(SIZE)-1:0] addr, // Address width based on SIZE
    input wire [31:0] data_in,
    output reg [31:0] data_out
);
    reg [31:0] memory [0:SIZE-1];   //just behavioral module, not mean this is a register array.

    initial begin
        $readmemh("../ram_init_file/sram_init.hex", memory);
    end

    always @(posedge clk) begin
        if (we) begin
            memory[addr] <= data_in;
        end
        data_out <= memory[addr];
    end
endmodule