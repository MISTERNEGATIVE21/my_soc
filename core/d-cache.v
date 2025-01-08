/* 
---------------------------------------------------------------------------------------------------------------
Explanation:
Parameters: 
The CACHE_SIZE, LINE_SIZE, WAYS, and WRITE_POLICY parameters configure the cache size, line size, associativity, and write policy.

Derived Parameters: The NUM_LINES, INDEX_BITS, OFFSET_BITS, and TAG_BITS are derived based on the cache configuration.

Cache Structures: 
The cache includes tag, data, valid, and dirty arrays.

Address Decomposition: 
The address is decomposed into index, tag, and offset.

Initialization: The cache arrays are initialized.

Memory Operations:
Example tasks for memory operations (write_to_memory, handle_write_miss, handle_read_miss) are placeholders for the actual logic to handle memory interactions. 

Write Miss Handling: 
The handle_write_miss task has been corrected to perform a write operation. It first checks if the address is aligned with the cache line size. 
If the address is aligned, it uses an incrementing burst; otherwise, it uses a wrapping burst. The data from the cache line is written to memory using burst transfers.

Read Miss Handling: 
The handle_read_miss task remains the same, using burst transfers to fetch cache lines from memory, with appropriate checks for address alignment.

Cache Operations: 
The always block continues to handle cache operations, including checking for hits and handling misses. 
If a miss occurs, the appropriate handle_write_miss or handle_read_miss task is called to fetch the necessary data from the AHB-slave SRAM using burst transfers.
---------------------------------------------------------------------------------------------------------------
*/

module DCache #(
    parameter CACHE_SIZE = 1024,         // Total cache size in bytes
    parameter LINE_SIZE = 64,            // Line size in bytes
    parameter WAYS = 1,                  // Number of ways (associativity)
    parameter WRITE_POLICY = "WRITE_BACK" // Write policy: "WRITE_BACK" or "WRITE_THROUGH"
)(
    input wire clk,
    input wire reset,
    input wire [31:0] addr,
    input wire [31:0] wdata,
    input wire r_w,                      // Read/Write (1=Write, 0=Read)
    input wire valid,
    output reg [31:0] rdata,
    output reg ready,
    output reg hit,
    // AHB Interface
    output reg [31:0] HADDR,
    output reg [2:0] HBURST,
    output reg HMASTLOCK,
    output reg [3:0] HPROT,
    output reg [2:0] HSIZE,
    output reg [1:0] HTRANS,
    output reg [31:0] HWDATA,
    output reg HWRITE,
    input wire [31:0] HRDATA,
    input wire HREADY,
    input wire HRESP
);

    // Derived parameters
    localparam NUM_LINES = CACHE_SIZE / (LINE_SIZE * WAYS);
    localparam INDEX_BITS = $clog2(NUM_LINES);
    localparam OFFSET_BITS = $clog2(LINE_SIZE);
    localparam TAG_BITS = 32 - INDEX_BITS - OFFSET_BITS;

    // Cache structures
    reg [TAG_BITS-1:0] tag_array [0:NUM_LINES-1][0:WAYS-1];
    reg [31:0] data_array [0:NUM_LINES-1][0:WAYS-1][0:LINE_SIZE/4-1]; // 4 bytes per word
    reg valid_array [0:NUM_LINES-1][0:WAYS-1];
    reg dirty_array [0:NUM_LINES-1][0:WAYS-1];

    // Extract index, tag, and offset from address
    wire [INDEX_BITS-1:0] index = addr[OFFSET_BITS + INDEX_BITS - 1:OFFSET_BITS];
    wire [TAG_BITS-1:0] tag = addr[31:OFFSET_BITS + INDEX_BITS];
    wire [OFFSET_BITS-1:0] offset = addr[OFFSET_BITS-1:0];

    integer way;
    reg hit_way;
    reg [31:0] writeback_addr;
    reg [31:0] writeback_data [0:LINE_SIZE/4-1];

    // Initialize cache structures
    initial begin
        for (integer i = 0; i < NUM_LINES; i = i + 1) begin
            for (integer j = 0; j < WAYS; j = j + 1) begin
                valid_array[i][j] = 0;
                dirty_array[i][j] = 0;
            end
        end
    end

    // Cache operation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ready <= 0;
            hit <= 0;
        end else if (valid) begin
            // Check for cache hit
            hit <= 0;
            for (way = 0; way < WAYS; way = way + 1) begin
                if (valid_array[index][way] && tag_array[index][way] == tag) begin
                    hit <= 1;
                    hit_way <= way;
                    break;
                end
            end

            if (hit) begin
                // Cache hit
                if (r_w) begin
                    // Write operation
                    data_array[index][hit_way][offset/4] <= wdata;
                    if (WRITE_POLICY == "WRITE_THROUGH") begin
                        // Write-through: write to memory immediately
                        write_to_memory(addr, wdata);
                    end else if (WRITE_POLICY == "WRITE_BACK") begin
                        // Write-back: mark the line as dirty
                        dirty_array[index][hit_way] <= 1;
                    end
                end else begin
                    // Read operation
                    rdata <= data_array[index][hit_way][offset/4];
                end
				ready <= 1; // Data is ready if hit
            end else begin
                // Cache miss
            ready <= 0; // Data is not ready if miss
                if (r_w) begin
                    // Write miss: handle accordingly based on policy
                    handle_write_miss(addr, wdata);
                end else begin
                    // Read miss: handle read miss
                    handle_read_miss(addr);
                end
            end
        end else begin
            ready <= 0;
        end
    end

    // Task for writing to memory using AHB bus
    task write_to_memory(input [31:0] addr, input [31:0] data);
        begin
            // Set AHB signals for a write transaction
            HADDR <= addr;
            HBURST <= 3'b000;       // Single transfer
            HMASTLOCK <= 1'b0;      // Not using locked transfer
            HPROT <= 4'b0011;       // Data access, non-cacheable, privileged, bufferable
            HSIZE <= 3'b010;        // 32-bit word transfer
            HTRANS <= 2'b10;        // Non-sequential transfer
            HWDATA <= data;
            HWRITE <= 1'b1;         // Write operation
            
            // Wait for the AHB transfer to complete
            @(posedge clk);
            while (!HREADY) begin
                @(posedge clk);
            end

            // Clear AHB signals after the transfer
            HTRANS <= 2'b00;        // Idle transfer
            HWRITE <= 1'b0;         // Clear write signal
        end
    endtask

    // Task for handling write miss using AHB bus with burst transfers
    task handle_write_miss(input [31:0] addr, input [31:0] data);
        integer i;
        begin
            // Check alignment with the cache line size
            if (addr[OFFSET_BITS-1:0] == 0) begin
                // Aligned address, use incrementing burst
                HADDR <= addr;
                HBURST <= 3'b011;       // 4-beat incrementing burst
            end else begin
                // Unaligned address, use wrapping burst
                HADDR <= addr & ~(LINE_SIZE - 1);
                HBURST <= 3'b100;       // 4-beat wrapping burst
            end

            HMASTLOCK <= 1'b0;          // Not using locked transfer
            HPROT <= 4'b0011;           // Data access, non-cacheable, privileged, bufferable
            HSIZE <= 3'b010;            // 32-bit word transfer
            HTRANS <= 2'b10;            // Non-sequential transfer
            HWRITE <= 1'b1;             // Write operation
            
            // Wait for the AHB transfer to complete for each word in the burst
            for (i = 0; i < LINE_SIZE/4; i = i + 1) begin
                HWDATA <= data_array[index][way][i]; // Write the current data to AHB bus
                @(posedge clk);
                while (!HREADY) begin
                    @(posedge clk);
                end
            end

            // Update the tag and valid bits
            tag_array[index][way] <= tag;
            valid_array[index][way] <= 1;
            dirty_array[index][way] <= 0;

            // Clear AHB signals after the transfer
            HTRANS <= 2'b00;        // Idle transfer
            HWRITE <= 1'b0;         // Clear write signal
            
            // Indicate the operation is ready
            ready <= 1;
        end
    endtask

    // Task for handling read miss using AHB bus with burst transfers
    task handle_read_miss(input [31:0] addr);
        integer i;
        begin
            // Check alignment with the cache line size
            if (addr[OFFSET_BITS-1:0] == 0) begin
                // Aligned address, use incrementing burst
                HADDR <= addr;
                HBURST <= 3'b011;       // 4-beat incrementing burst
            end else begin
                // Unaligned address, use wrapping burst
                HADDR <= addr & ~(LINE_SIZE - 1);
                HBURST <= 3'b100;       // 4-beat wrapping burst
            end

            HMASTLOCK <= 1'b0;          // Not using locked transfer
            HPROT <= 4'b0011;           // Data access, non-cacheable, privileged, bufferable
            HSIZE <= 3'b010;            // 32-bit word transfer
            HTRANS <= 2'b10;            // Non-sequential transfer
            HWRITE <= 1'b0;             // Read operation
            
            // Wait for the AHB transfer to complete for each word in the burst
            for (i = 0; i < LINE_SIZE/4; i = i + 1) begin
                @(posedge clk);
                while (!HREADY) begin
                    @(posedge clk);
                end
                // Store the fetched data in the cache line
                data_array[index][way][i] <= HRDATA;
            end

            // Update the tag and valid bits
            tag_array[index][way] <= tag;
            valid_array[index][way] <= 1;
            dirty_array[index][way] <= 0;

            // If this was a read operation, provide the data
            rdata <= data_array[index][way][offset/4];

            // Clear AHB signals after the transfer
            HTRANS <= 2'b00;        // Idle transfer
            
            // Indicate the operation is ready
            ready <= 1;
        end
    endtask

endmodule