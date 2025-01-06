
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

---------------------------------------------------------------------------------------------------------------
*/
module ICache #(
    parameter CACHE_SIZE = 1024,   // Total cache size in bytes
    parameter LINE_SIZE = 32,      // Line size in bytes
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
    reg [31:0] cache_data [0:NUM_LINES-1][0:WAYS-1];
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
                            rdata = cache_data[index][way];
                            ready = 1;
                        end
                    end
                    if (!hit) begin
                        // Cache miss: Fetch from AHB bus
                        HADDR = addr;
                        HTRANS = 2'b10; // NONSEQ
                        HWRITE = 0;     // Read operation
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
                        cache_data[index][way] = HRDATA;
                        cache_tags[index][way] = tag;
                        cache_valid[index][way] = 1;
                        break;
                    end
                end
                rdata = HRDATA;
                ready = 1;
                next_state = IDLE;
            end
        endcase
    end

endmodule
