module AHB_SRAM_Slave #(
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

    // Parameterized SRAM size
    reg [31:0] sram [0:SIZE-1];

    // AHB states
    localparam ST_IDLE = 2'b00, ST_BUSY = 2'b01, ST_NONSEQ = 2'b10, ST_SEQ = 2'b11;

    // Base address of the SRAM
    localparam BASE_ADDR = 32'h0010_0000;

    initial begin
        $readmemh("../ram_init_file/sram_init.hex", sram);
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HRDATA <= 32'b0;
            HREADY <= 1'b1;
            HRESP <= 1'b0;
        end else begin
            // Check if the address is within the SRAM range
            if (HTRANS != ST_IDLE && HADDR >= BASE_ADDR && HADDR < BASE_ADDR + (SIZE * 4)) begin
                if (HWRITE) begin
                    // Write operation
                    sram[(HADDR - BASE_ADDR) >> 2] <= HWDATA;
                    HREADY <= 1'b1;
                    HRESP <= 1'b0; // OKAY response
                end else begin
                    // Read operation
                    HRDATA <= sram[(HADDR - BASE_ADDR) >> 2];
                    HREADY <= 1'b1;
                    HRESP <= 1'b0; // OKAY response
                end
            end else begin
                HREADY <= 1'b1;
                HRESP <= 1'b0; // OKAY response
            end
        end
    end

endmodule