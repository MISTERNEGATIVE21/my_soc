/*
Parameters
DATA_WIDTH: Width of the data bus.
ADDR_WIDTH: Width of the address bus, which determines the depth of the FIFO.

Ports
wr_clk, rd_clk: Write and read clock signals.
wr_en, rd_en: Write and read enable signals.
wr_data: Data input bus for writing.
rd_data: Data output bus for reading.
full: Signal indicating that the FIFO is full.
empty: Signal indicating that the FIFO is empty.
fifo_fill_cnt: Signal indicating the number of elements in the FIFO.

Internal Registers and Memory
mem: Memory array to store the FIFO data.
wr_ptr, rd_ptr: Write and read pointers.

Binary to Gray Code Conversion
Binary to gray code and gray code to binary conversion functions are defined to synchronize pointers between different clock domains.

Write Operation
Occurs on the positive edge of wr_clk.
If wr_en is asserted and the FIFO is not full, data is written to the memory array at the location pointed to by wr_ptr, 
and the write pointer is incremented.

Read Operation
Occurs on the positive edge of rd_clk.
If rd_en is asserted and the FIFO is not empty, data is read from the memory array at the location pointed to by rd_ptr, 
and the read pointer is incremented.

Full Signal Generation
The write pointer in gray code is compared with the synchronized read pointer in gray code to determine if the FIFO is full.

Empty Signal Generation
The read pointer in gray code is compared with the synchronized write pointer in gray code to determine if the FIFO is empty.

FIFO Fill Count
The difference between the write pointer and the read pointer gives the number of elements in the FIFO.

Problem:
APB Bus Requirement: The APB bus expects the data to be read in one clock cycle.
FIFO Latency: The FIFO introduces a two-cycle latency due to the two-stage synchronization.
Solution:
Given that the software can check the RX FIFO's fill count (rx_fifo_fill_cnt), 
and the fill count is synchronized from the uart_clk domain to the PCLK domain, it should be safe to read the FIFO immediately. 
The synchronization of the fill count ensures that the software has an accurate view of the number of elements in the FIFO. (this will be done in upper module)

*/

module AsyncFIFO #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
) (
    input wire wr_clk,
    input wire rd_clk,
    input wire global_reset_n,  // Global active-low reset signal (PRESETn)
    input wire local_reset_n,   // Local active-low reset signal (reset_n from UART register)
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] wr_data,
    output reg [DATA_WIDTH-1:0] rd_data, // Changed to reg
    output wire full,
    output wire empty,
    output wire [ADDR_WIDTH:0] fifo_fill_cnt,
    output reg fifo_overflow,
    output reg fifo_underflow
);
    // Define internal storage array
    reg [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0];

    // Write and read pointers
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;

    // Combined reset signal
    wire combined_reset_n = global_reset_n & local_reset_n;

    // Binary to Gray code conversion
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        begin
            bin2gray = (bin >> 1) ^ bin;
        end
    endfunction

    // Gray code to binary conversion
    function [ADDR_WIDTH:0] gray2bin;
        input [ADDR_WIDTH:0] gray;
        reg [ADDR_WIDTH:0] bin;
        integer i;
        begin
            bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
            for (i = ADDR_WIDTH-1; i >= 0; i = i - 1) begin
                bin[i] = bin[i+1] ^ gray[i];
            end
            gray2bin = bin;
        end
    endfunction

    // Write operation
    always @(posedge wr_clk or negedge combined_reset_n) begin
        if (!combined_reset_n) begin
            wr_ptr <= 0;
            full <= 0;
            fifo_overflow <= 0;
        end else if (wr_en) begin
            if (!full) begin
                mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1;
                fifo_overflow <= 0;
            end else begin
                // FIFO is full, set overflow flag
                fifo_overflow <= 1;
            end
        end
    end

    // Read operation with registered output
    always @(posedge rd_clk or negedge combined_reset_n) begin
        if (!combined_reset_n) begin
            rd_ptr <= 0;
            fifo_underflow <= 0;
            rd_data <= 0; // Initialize rd_data
        end else if (rd_en) begin
            if (!empty) begin
                rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]]; // Immediate read from memory
                rd_ptr <= rd_ptr + 1;
                fifo_underflow <= 0;
            end else begin
                // FIFO is empty, set underflow flag
                fifo_underflow <= 1;
            end
        end
    end

    // Generate full signal
    wire [ADDR_WIDTH:0] wr_ptr_gray = bin2gray(wr_ptr);
    wire [ADDR_WIDTH:0] rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync_r1, rd_ptr_gray_sync_r2;
    always @(posedge wr_clk or negedge combined_reset_n) begin
        if (!combined_reset_n) begin
            rd_ptr_gray_sync_r1 <= 0;
            rd_ptr_gray_sync_r2 <= 0;
        end else begin
        rd_ptr_gray_sync_r1 <= bin2gray(rd_ptr);
        rd_ptr_gray_sync_r2 <= rd_ptr_gray_sync_r1;
        end
    end
    assign full = (wr_ptr_gray == {~rd_ptr_gray_sync_r2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync_r2[ADDR_WIDTH-2:0]});

    // Generate empty signal
    wire [ADDR_WIDTH:0] rd_ptr_gray = bin2gray(rd_ptr);
    wire [ADDR_WIDTH:0] wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync_r1, wr_ptr_gray_sync_r2;
    always @(posedge rd_clk or negedge combined_reset_n) begin
        if (!combined_reset_n) begin
            wr_ptr_gray_sync_r1 <= 0;
            wr_ptr_gray_sync_r2 <= 0;
        end else begin
        wr_ptr_gray_sync_r1 <= bin2gray(wr_ptr);
        wr_ptr_gray_sync_r2 <= wr_ptr_gray_sync_r1;
        end
    end
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync_r2);

    // Calculate fifo_fill_cnt
    assign fifo_fill_cnt = wr_ptr - rd_ptr;

endmodule