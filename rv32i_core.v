module dcache #(parameter CACHE_LINE_SIZE = 32, // Size of each cache line in bytes
                parameter NUM_CACHE_LINES = 256, // Total number of cache lines
                parameter CACHE_WAYS = 1) // Number of ways in cache
(
    input wire clk,
    input wire reset,
    input wire [31:0] addr,
    input wire valid,
    input wire write_enable,
    input wire [31:0] write_data,
    output reg [31:0] read_data,
    output reg hit,
    output reg mem_write,
    output reg [31:0] mem_addr,
    output reg [31:0] mem_wdata,
    input wire [31:0] mem_rdata,
    input wire mem_ready
);

    // Derived parameters
    localparam CACHE_SIZE = CACHE_LINE_SIZE * NUM_CACHE_LINES;
    localparam INDEX_BITS = $clog2(NUM_CACHE_LINES / CACHE_WAYS);
    localparam OFFSET_BITS = $clog2(CACHE_LINE_SIZE);
    localparam TAG_BITS = 32 - INDEX_BITS - OFFSET_BITS;

    // Cache storage
    reg [31:0] cache_memory [0:NUM_CACHE_LINES-1];
    reg [TAG_BITS-1:0] tags [0:NUM_CACHE_LINES-1];
    reg valid_bits [0:NUM_CACHE_LINES-1];
    reg dirty_bits [0:NUM_CACHE_LINES-1];

    wire [INDEX_BITS-1:0] index = addr[OFFSET_BITS +: INDEX_BITS];
    wire [TAG_BITS-1:0] tag = addr[31 -: TAG_BITS];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            integer i;
            for (i = 0; i < NUM_CACHE_LINES; i = i + 1) begin
                valid_bits[i] <= 0;
                dirty_bits[i] <= 0;
            end
            hit <= 0;
            mem_write <= 0;
        end else if (valid) begin
            if (valid_bits[index] && tags[index] == tag) begin
                hit <= 1;
                read_data <= cache_memory[index];
                if (write_enable) begin
                    cache_memory[index] <= write_data;
                    dirty_bits[index] <= 1;
                end
            end else begin
                hit <= 0;
                if (dirty_bits[index]) begin
                    mem_write <= 1;
                    mem_addr <= {tags[index], index, {OFFSET_BITS{1'b0}}};
                    mem_wdata <= cache_memory[index];
                    if (mem_ready) begin
                        mem_write <= 0;
                        cache_memory[index] <= mem_rdata;
                        tags[index] <= tag;
                        valid_bits[index] <= 1;
                        dirty_bits[index] <= 0;
                    end
                end else begin
                    cache_memory[index] <= mem_rdata;
                    tags[index] <= tag;
                    valid_bits[index] <= 1;
                    dirty_bits[index] <= 0;
                end
            end
        end
    end

    // Cache update task
    task update_cache(input [31:0] addr, input [31:0] new_data);
        begin
            cache_memory[index] <= new_data;
            tags[index] <= tag;
            valid_bits[index] <= 1;
            dirty_bits[index] <= 1;
        end
    endtask

endmodule





module rv32i_core (
    input wire clk,
    input wire reset,
    output wire [31:0] pc,
    output wire [31:0] instruction,
    output wire [31:0] alu_result,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,
    output wire [31:0] imm,
    output wire [4:0] rd,
    output wire [6:0] opcode,
    output wire [2:0] funct3,
    output wire [6:0] funct7,
    input wire [31:0] read_data,
    output wire mem_read,
    output wire mem_write,
    input wire halt,
    input wire step
);

    // Intermediate signals
    wire [31:0] ex_mem_data;
    wire [31:0] mem_wb_data;
    wire [1:0] forward_a;
    wire [1:0] forward_b;

    // Instantiate forwarding unit
    forwarding_unit forward_unit (
        .rs1(rs1),
        .rs2(rs2),
        .ex_mem_rd(ex_mem_rd),
        .mem_wb_rd(mem_wb_rd),
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_reg_write(mem_wb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // Instantiate execution stage with forwarding
    execution_stage exec_stage (
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .ex_mem_data(ex_mem_data),
        .mem_wb_data(mem_wb_data),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .alu_input_a(alu_input_a),
        .alu_input_b(alu_input_b)
    );

    // Other pipeline stages and control logic here...
    // Fetch, Decode, Memory, Writeback, etc.

endmodule
