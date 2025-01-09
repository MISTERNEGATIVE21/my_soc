module AHB_ROM_Slave (
    input wire HCLK,         // AHB system clock
    input wire HRESETn,      // AHB system reset (active low)
    input wire [31:0] HADDR, // AHB address
    input wire [2:0] HBURST, // Burst type (not used in this example)
    input wire HMASTLOCK,    // Master lock signal (not used in this example)
    input wire [3:0] HPROT,  // Protection control (not used in this example)
    input wire [2:0] HSIZE,  // Transfer size (not used in this example)
    input wire [1:0] HTRANS, // Transfer type
    input wire HWRITE,       // Transfer direction (write=1, read=0)
    input wire [31:0] HWDATA,// Write data (not used in ROM)
    output reg [31:0] HRDATA,// Read data
    output reg HREADY,       // Transfer done
    output reg HRESP         // Transfer response (0=OKAY, 1=ERROR)
);

    // 32KB ROM (8192 x 32-bit words)
    reg [31:0] rom [0:8191];

    // AHB states
    localparam ST_IDLE = 2'b00, ST_BUSY = 2'b01, ST_NONSEQ = 2'b10, ST_SEQ = 2'b11;

    // Base address of the ROM
    localparam BASE_ADDR = 32'h0000_0000;


    // Initialize ROM content (example data)
    initial begin
        $readmemh("../ram_init_file/rom_init.hex", rom);
    end   

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HRDATA <= 32'b0;
            HREADY <= 1'b1;
            HRESP <= 1'b0;
        end else begin
            // Check if the address is within the ROM range
            if (HTRANS != ST_IDLE && HADDR >= BASE_ADDR && HADDR < BASE_ADDR + 32'h0000_8000) begin
                if (!HWRITE) begin
                    // Read operation
                    HRDATA <= rom[HADDR[14:2]];
                    HREADY <= 1'b1;
                    HRESP <= 1'b0; // OKAY response
                end else begin
                    // Write operation not allowed in ROM
                    HREADY <= 1'b1;
                    HRESP <= 1'b1; // ERROR response
                end
            end else begin
                HREADY <= 1'b1;
                HRESP <= 1'b0; // OKAY response
            end
        end
    end

endmodule