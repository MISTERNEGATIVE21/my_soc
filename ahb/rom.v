`include "../common.vh"


module AHB_ROM_Slave #(
    parameter BASE_ADDR = 32'h0000_0000, // Default base address
    parameter SIZE = 8192 // Default size is 8192 words (32KB)
)(
    input wire HCLK,         // AHB system clock
    input wire HRESETn,      // AHB system reset (active low)
    input wire [31:0] HADDR, // AHB address
    input wire [2:0] HBURST, // Burst type
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

    // AHB states
    localparam ST_IDLE = 2'b00, ST_BUSY = 2'b01, ST_NONSEQ = 2'b10, ST_SEQ = 2'b11;

    // Internal signals
    wire [31:0] rom_data_out;
    reg [clog2(SIZE)-1:0] rom_addr;
    reg [3:0] burst_count; // Burst transfer counter

    // Instantiate the new ROM module
    rom_ahb #(
        .SIZE(SIZE)
    ) rom_inst (
        .clk(HCLK),
        .addr(rom_addr),
        .data_out(rom_data_out)
    );

    // Address calculation for burst transfers
    always @(*) begin
        case (HBURST)
            3'b000: rom_addr = (HADDR - BASE_ADDR) >> 2; // SINGLE
            3'b001: rom_addr = ((HADDR - BASE_ADDR) >> 2) + burst_count; // INCR
            3'b010: rom_addr = (((HADDR - BASE_ADDR) >> 2) & ~(4-1)) | ((((HADDR - BASE_ADDR) >> 2) + burst_count) & (4-1)); // WRAP4
            3'b011: rom_addr = ((HADDR - BASE_ADDR) >> 2) + burst_count; // INCR4
            3'b100: rom_addr = (((HADDR - BASE_ADDR) >> 2) & ~(8-1)) | ((((HADDR - BASE_ADDR) >> 2) + burst_count) & (8-1)); // WRAP8
            3'b101: rom_addr = ((HADDR - BASE_ADDR) >> 2) + burst_count; // INCR8
            3'b110: rom_addr = (((HADDR - BASE_ADDR) >> 2) & ~(16-1)) | ((((HADDR - BASE_ADDR) >> 2) + burst_count) & (16-1)); // WRAP16
            3'b111: rom_addr = ((HADDR - BASE_ADDR) >> 2) + burst_count; // INCR16
            default: rom_addr = (HADDR - BASE_ADDR) >> 2;
        endcase
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HRDATA <= 32'b0;
            HREADY <= 1'b1;
            HRESP <= 1'b0;
            burst_count <= 0;
        end else begin
            // Default values
            HREADY <= 1'b1;
            HRESP <= 1'b0; // OKAY response

            // Check if the address is within the ROM range
            if (HTRANS != ST_IDLE && HADDR >= BASE_ADDR && HADDR < BASE_ADDR + (SIZE * 4)) begin
                if (!HWRITE) begin
                    // Read operation
                    if (HREADY) begin
                    HRDATA <= rom_data_out;
                        burst_count <= burst_count + 1;
                    end
                end else begin
                    // Write operation not allowed in ROM
                    HREADY <= 1'b1;
                    HRESP <= 1'b1; // ERROR response
                end
            end else begin
                burst_count <= 0;
                HREADY <= 1'b1;
                HRESP <= 1'b1; // ERROR response, addr range err
            end
        end
    end
endmodule

module rom_ahb #(
    parameter SIZE = 8192 // Default size is 8192 words (32KB)
)(
    input wire clk,
    input wire [$clog2(SIZE)-1:0] addr, // Address width based on SIZE
    output reg [31:0] data_out
);
    // Declare ROM (Read-Only Memory)
    reg [31:0] memory [0:SIZE-1];

    // Initialize ROM content from hex file
    initial begin
        $readmemh("../ram_init_file/rom_init.hex", memory);
    end

    // Read data from ROM
    always @(posedge clk) begin
        data_out <= memory[addr];
    end
endmodule
