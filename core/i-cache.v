
/* 
---------------------------------------------------------------------------------------------------------------
Explanation:
Derived Parameters:
NUM_LINES: Number of cache lines.
INDEX_BITS: Number of bits used for indexing into the cache.
OFFSET_BITS: Number of bits used for the block offset within the cache line.
TAG_BITS: Number of bits used for the tag.

Cache Storage:
cache_data: Stores the actual data.
cache_tags: Stores the tags for each cache line.
cache_valid: Valid bits indicating if the cache line contains valid data.

Cache Operation:
On each clock cycle, it checks if the address is valid and performs a cache hit check.
If there's a hit, it retrieves the data; otherwise, it handles the miss (placeholder for now). 

State Machine: The I-Cache uses a state machine to handle different states:
IDLE: The cache checks for hits and initiates a bus fetch on a miss.
FETCH: The cache waits for data to be fetched from the AHB bus.
UPDATE: The cache updates its content with the fetched data.

Initialization: The cache is initialized to mark all lines as invalid.

Cache Miss Handling: On a cache miss, the cache fetches the data from the AHB bus, updates the cache, and then sets the data to be read.

In the context of the I-Cache design, the CPU typically waits for the ready signal to indicate whether an instruction is available for processing. 
When there is an I-Cache miss, the ready signal will not be asserted until the requested instruction is fetched from the AHB bus and the cache is updated.
Here is a brief overview of the relevant signals and their roles:
valid: This signal indicates that the address provided by the CPU is valid and a cache lookup should be performed.
hit: This signal indicates whether the requested instruction is found in the cache.
ready: This signal indicates that the data is ready to be used by the CPU. If there is an I-Cache miss, this signal will be deasserted until the instruction is fetched from the AHB bus.

---------------------------------------------------------------------------------------------------------------
*/
module ICache #(
    parameter CACHE_SIZE = 1024,   // Total cache size in bytes
    parameter LINE_SIZE = 64,      // Line size in bytes
    parameter WAYS = 1             // Number of ways (associativity)
)(
    input wire clk,
    input wire reset,
    input wire [31:0] addr,
    input wire valid,
    output reg [31:0] rdata,
    output reg ready,
    output reg hit,
    // AHB interface signals
    output reg [31:0] HADDR,
    output reg [2:0] HBURST,
    output reg HMASTLOCK,
    output reg [3:0] HPROT,
    output reg [2:0] HSIZE,
    output reg [1:0] HTRANS,
    output reg HWRITE,
    output reg [31:0] HWDATA,
    input wire [31:0] HRDATA,
    input wire HREADY,
    input wire HRESP
);

    // Derived parameters
    localparam NUM_LINES = CACHE_SIZE / (LINE_SIZE * WAYS);
    localparam INDEX_BITS = $clog2(NUM_LINES);
    localparam OFFSET_BITS = $clog2(LINE_SIZE);
    localparam TAG_BITS = 32 - INDEX_BITS - OFFSET_BITS;

    // Cache storage
    reg [31:0] cache_data [0:NUM_LINES-1][0:WAYS-1][0:LINE_SIZE/4-1]; // 4 bytes per word
    reg [TAG_BITS-1:0] cache_tags [0:NUM_LINES-1][0:WAYS-1];
    reg cache_valid [0:NUM_LINES-1][0:WAYS-1];

    // Temporary variables
    wire [INDEX_BITS-1:0] index = addr[OFFSET_BITS + INDEX_BITS - 1 : OFFSET_BITS];
    wire [TAG_BITS-1:0] tag = addr[31 : 32 - TAG_BITS];
    wire [OFFSET_BITS-1:0] offset = addr[OFFSET_BITS-1:0];
    integer way;

    // State machine states
    localparam IDLE = 2'b00, FETCH = 2'b01, UPDATE = 2'b10;
    reg [1:0] state, next_state;

    // Initialize cache
    initial begin
        for (way = 0; way < WAYS; way = way + 1) begin
            for (int i = 0; i < NUM_LINES; i = i + 1) begin
                cache_valid[i][way] = 0;
            end
        end
        state = IDLE;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset logic
            for (way = 0; way < WAYS; way = way + 1) begin
                for (int i = 0; i < NUM_LINES; i = i + 1) begin
                    cache_valid[i][way] <= 0;
                end
            end
            hit <= 0;
            ready <= 0;
            rdata <= 0;
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (valid) begin
                    // Check for hit
                    hit = 0;
                    for (way = 0; way < WAYS; way = way + 1) begin
                        if (cache_valid[index][way] && cache_tags[index][way] == tag) begin
                            hit = 1;
                            rdata = cache_data[index][way][offset/4];
                            ready = 1; // Data is ready if hit
                        end
                    end
                    if (!hit) begin
                        // Cache miss: Fetch from AHB bus
                        ready = 0; // Data is not ready if miss
                        if (addr[OFFSET_BITS-1:0] == 0) begin
                            // Aligned address, use incrementing burst
                        HADDR = addr;
                            HBURST = 3'b011; // 4-beat incrementing burst
                        end else begin
                            // Unaligned address, use wrapping burst
                            HADDR = addr & ~(LINE_SIZE - 1);
                            HBURST = 3'b100; // 4-beat wrapping burst
                        end
                        HMASTLOCK = 1'b0; // Not using locked transfer
                        HPROT = 4'b0011; // Data access, non-cacheable, privileged, bufferable
                        HSIZE = 3'b010; // 32-bit word transfer
                        HTRANS = 2'b10; // NONSEQ
                        HWRITE = 0; // Read operation
                        next_state = FETCH;
                    end
                end
            end
            FETCH: begin
                if (HREADY) begin
                    // Data fetched from AHB bus
                    next_state = UPDATE;
                end
            end
            UPDATE: begin
                // Update cache with fetched data
                for (way = 0; way < WAYS; way = way + 1) begin
                    if (!cache_valid[index][way]) begin
                        // Store fetched data in cache line
                        for (int i = 0; i < LINE_SIZE/4; i = i + 1) begin
                            cache_data[index][way][i] = HRDATA; // Assuming burst transfers fill this correctly
                        end
                        cache_tags[index][way] = tag;
                        cache_valid[index][way] = 1;
                        break;
                    end
                end
                rdata = cache_data[index][way][offset/4];
                ready = 1; // Data is ready after update
                next_state = IDLE;
            end
        endcase
    end

endmodule
