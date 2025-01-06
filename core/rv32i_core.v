module RegisterFile(
    input clk,
    input reset,
    input RegWrite,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] WriteData,
    output reg [31:0] ReadData1,
    output reg [31:0] ReadData2
);
    reg [31:0] registers [0:31];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ReadData1 <= 0;
            ReadData2 <= 0;
        end else begin
            if (RegWrite) begin
                registers[rd] <= WriteData;
            end
            ReadData1 <= registers[rs1];
            ReadData2 <= registers[rs2];
        end
    end
endmodule

module InstructionMemory(
    input [31:0] Address,
    output [31:0] Instruction
);
    reg [31:0] memory [0:255];

    initial begin
        // Load instructions into memory here
        // Example: memory[0] = 32'h00000000;
    end

    assign Instruction = memory[Address[9:2]];
endmodule


module DataMemory(
    input clk,
    input MemRead,
    input MemWrite,
    input [31:0] Address,
    input [31:0] WriteData,
    output [31:0] ReadData
);
    reg [31:0] memory [0:255];

    always @(posedge clk) begin
        if (MemWrite) begin
            memory[Address[9:2]] <= WriteData;
        end
    end

    assign ReadData = (MemRead) ? memory[Address[9:2]] : 32'bz;
endmodule

module IFStage(
    input clk,
    input reset,
    input [31:0] PC_in,
    output reg [31:0] Instruction,
    output reg [31:0] PC_out
);
    reg [31:0] instruction_memory [0:255];

    initial begin
        // Load instructions into memory here
        // Example: instruction_memory[0] = 32'h00000000;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC_out <= 0;
        end else begin
            Instruction <= instruction_memory[PC_in[9:2]];
            PC_out <= PC_in + 4;
        end
    end
endmodule

module IDStage(
    input clk,
    input reset,
    input [31:0] Instruction,
    output reg [6:0] opcode,
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [4:0] rd,
    output reg [2:0] funct3,
    output reg [6:0] funct7,
    output reg [31:0] imm
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            opcode <= 0;
            rs1 <= 0;
            rs2 <= 0;
            rd <= 0;
            funct3 <= 0;
            funct7 <= 0;
            imm <= 0;
        end else begin
            opcode <= Instruction[6:0];
            rd <= Instruction[11:7];
            funct3 <= Instruction[14:12];
            rs1 <= Instruction[19:15];
            rs2 <= Instruction[24:20];
            funct7 <= Instruction[31:25];
            // Immediate value extraction based on instruction type
            imm <= (opcode == 7'b0000011 || opcode == 7'b0100011) ? {{20{Instruction[31]}}, Instruction[31:20]} : 32'b0;
        end
    end
endmodule

module EXStage(
    input clk,
    input reset,
    input [31:0] ReadData1,
    input [31:0] ReadData2,
    input [31:0] imm,
    input [3:0] ALUControl,
    output reg [31:0] ALUResult,
    output reg Zero
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ALUResult <= 0;
            Zero <= 0;
        end else begin
            case(ALUControl)
                4'b0000: ALUResult <= ReadData1 + (ALUSrc ? imm : ReadData2); // ADD
                4'b0001: ALUResult <= ReadData1 - ReadData2; // SUB
                4'b0010: ALUResult <= ReadData1 & (ALUSrc ? imm : ReadData2); // AND
                4'b0011: ALUResult <= ReadData1 | (ALUSrc ? imm : ReadData2); // OR
                4'b0100: ALUResult <= ReadData1 ^ (ALUSrc ? imm : ReadData2); // XOR
                4'b0101: ALUResult <= (ReadData1 < (ALUSrc ? imm : ReadData2)) ? 1 : 0; // SLT
                default: ALUResult <= 0;
            endcase
            Zero <= (ALUResult == 0);
        end
    end
endmodule

module MEMStage(
    input clk,
    input reset,
    input MemRead,
    input MemWrite,
    input [31:0] ALUResult,
    input [31:0] WriteData,
    output reg [31:0] ReadData
);
    reg [31:0] data_memory [0:255];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ReadData <= 0;
        end else begin
            if (MemRead) begin
                ReadData <= data_memory[ALUResult[9:2]];
            end
            if (MemWrite) begin
                data_memory[ALUResult[9:2]] <= WriteData;
            end
        end
    end
endmodule

module WBStage(
    input clk,
    input reset,
    input MemtoReg,
    input [31:0] ALUResult,
    input [31:0] ReadData,
    output reg [31:0] WriteData
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            WriteData <= 0;
        end else begin
            WriteData <= (MemtoReg) ? ReadData : ALUResult;
        end
    end
endmodule


module Cache #(
    parameter CACHE_SIZE = 1024,   // Total cache size in bytes
    parameter LINE_SIZE = 32,      // Line size in bytes
    parameter WAYS = 1             // Number of ways (associativity)
)(
    input wire clk,
    input wire reset,
    input wire [31:0] addr,
    input wire [31:0] wdata,
    input wire r_w,                // Read/Write (1=Write, 0=Read)
    input wire valid,
    output reg [31:0] rdata,
    output reg ready,
    output reg hit
);
    // Cache implementation here...
    // This includes tag array, data array, and replacement policy logic.
endmodule


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



/* 
---------------------------------------------------------------------------------------------------------------
Explanation:
Parameters: The CACHE_SIZE, LINE_SIZE, WAYS, and WRITE_POLICY parameters configure the cache size, line size, associativity, and write policy.
Derived Parameters: The NUM_LINES, INDEX_BITS, OFFSET_BITS, and TAG_BITS are derived based on the cache configuration.
Cache Structures: The cache includes tag, data, valid, and dirty arrays.
Address Decomposition: The address is decomposed into index, tag, and offset.
Initialization: The cache arrays are initialized.
Cache Operation: The main cache operation logic handles cache hits and misses, and performs read or write operations based on the write policy.
Memory Operations: Example tasks for memory operations (write_to_memory, handle_write_miss, handle_read_miss) are placeholders for the actual logic to handle memory interactions. 

---------------------------------------------------------------------------------------------------------------
*/
module DCache #(
    parameter CACHE_SIZE = 1024,         // Total cache size in bytes
    parameter LINE_SIZE = 32,            // Line size in bytes
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
    output reg hit
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
    reg writeback_required;
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
            writeback_required <= 0;
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
                        // Assume write_to_memory is a task to handle memory write
                        write_to_memory(addr, wdata);
                    end else if (WRITE_POLICY == "WRITE_BACK") begin
                        // Write-back: mark the line as dirty
                        dirty_array[index][hit_way] <= 1;
                    end
                end else begin
                    // Read operation
                    rdata <= data_array[index][hit_way][offset/4];
                end
                ready <= 1;
            end else begin
                // Cache miss
                ready <= 0;
                if (r_w) begin
                    // Write miss: handle accordingly based on policy
                    // Assume handle_write_miss is a task to handle write miss
                    handle_write_miss(addr, wdata);
                end else begin
                    // Read miss: handle read miss
                    // Assume handle_read_miss is a task to handle read miss
                    handle_read_miss(addr);
                end
            end
        end else begin
            ready <= 0;
        end
    end

    // Example tasks for memory operations
    task write_to_memory(input [31:0] addr, input [31:0] data);
        // Memory write logic
    endtask

    task handle_write_miss(input [31:0] addr, input [31:0] data);
        // Write miss handling logic
        // Example: fetch the line from memory, update the cache, and write back if necessary
    endtask

    task handle_read_miss(input [31:0] addr);
        // Read miss handling logic
        // Example: fetch the line from memory and update the cache
    endtask

endmodule

module CPU_Debug (
    input wire clk,
    input wire reset,
    input wire enable,
    input wire rd_wr,
    input wire [31:0] address,
    input wire [31:0] data_out,
    output wire [31:0] data_in,
    input wire step,
    input wire run,
    output reg halt
);
    // Internal signals
    reg [31:0] memory [0:1023]; // Example memory array
    reg [31:0] registers [0:31]; // Example register array
    reg [31:0] pc; // Program counter

    // Memory and register access
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            halt <= 0;
            pc <= 0;
        end else if (enable) begin
            if (rd_wr) begin
                // Write operation
                if (address < 1024) begin
                    memory[address] <= data_out;
                end else if (address >= 1024 && address < 1056) begin
                    registers[address - 1024] <= data_out;
                end
            end else begin
                // Read operation
                if (address < 1024) begin
                    data_in <= memory[address];
                end else if (address >= 1024 && address < 1056) begin
                    data_in <= registers[address - 1024];
                end
            end
        end

        if (step) begin
            // Step CPU
            halt <= 0;
            pc <= pc + 4; // Example step operation
        end

        if (run) begin
            // Run CPU
            halt <= 0;
        end else begin
            halt <= 1;
        end
    end
endmodule

module PipelineRV32ICore_AHB #(
    parameter ICACHE_SIZE = 1024,
    parameter ICACHE_LINE_SIZE = 32,
    parameter ICACHE_WAYS = 1,
    parameter DCACHE_SIZE = 1024,
    parameter DCACHE_LINE_SIZE = 32,
    parameter DCACHE_WAYS = 1,
    parameter DCACHE_WRITE_POLICY = "WRITE_BACK"
)(
    input clk,
    input reset,
    // AHB Interface
    output reg [31:0] HADDR,
    output reg [2:0] HBURST,
    output reg HMASTLOCK,
    output reg [3:0] HPROT,
    output reg [2:0] HSIZE,
    output reg [1:0] HTRANS,
    output reg [31:0] HWDATA,
    output reg HWRITE,
    input [31:0] HRDATA,
    input HREADY,
    input HRESP
    // JTAG Interface
    input wire TCK,
    input wire TMS,
    input wire TDI,
    output wire TDO   
);

    // Pipeline registers
    reg [31:0] IF_ID_PC;
    reg [31:0] IF_ID_Instruction;
    reg [31:0] ID_EX_PC;
    reg [31:0] ID_EX_ReadData1;
    reg [31:0] ID_EX_ReadData2;
    reg [31:0] ID_EX_Immediate;
    reg [4:0] ID_EX_Rs1;
    reg [4:0] ID_EX_Rs2;
    reg [4:0] ID_EX_Rd;
    reg [6:0] ID_EX_Funct7;
    reg [2:0] ID_EX_Funct3;
    reg [31:0] EX_MEM_ALUResult;
    reg [31:0] EX_MEM_WriteData;
    reg [4:0] EX_MEM_Rd;
    reg EX_MEM_RegWrite;
    reg MEM_WB_RegWrite;
    reg [31:0] MEM_WB_ReadData;
    reg [4:0] MEM_WB_Rd;
    
    // Program counter
    reg [31:0] PC;

    // Control signals (simplified for illustration purposes)
    wire [1:0] ALUOp;
    wire MemRead;
    wire MemtoReg;
    wire MemWrite;
    wire ALUSrc;
    wire RegWrite;

    // ALU control signals
    wire [3:0] ALUControl;
    wire [31:0] ALUResult;
    wire Zero;

    // Immediate generation
    wire [31:0] Immediate;

    // Register file
    wire [31:0] ReadData1;
    wire [31:0] ReadData2;

    // Cache outputs
    wire [31:0] i_cache_rdata;
    wire i_cache_ready;
    wire i_cache_hit;
    wire [31:0] d_cache_rdata;
    wire d_cache_ready;
    wire d_cache_hit;

    // Internal signals for debugging
    wire [31:0] jtag_address;
    wire [31:0] jtag_data_out;
    wire [31:0] jtag_data_in;
    wire jtag_rd_wr;
    wire jtag_enable;
    wire jtag_step;
    wire jtag_run;
    wire cpu_stall;

     // Internal signals for CPU control
    reg [31:0] pc; // Program counter
    reg [31:0] instruction; // Current instruction
    reg [31:0] regfile [0:31]; // Register file
    reg fetch_enable, decode_enable, execute_enable; // Pipeline stage enables
    reg cpu_stall; // CPU stall signal

    // Instantiate I-Cache
    ICache #(
        .CACHE_SIZE(ICACHE_SIZE),
        .LINE_SIZE(ICACHE_LINE_SIZE),
        .WAYS(ICACHE_WAYS)
    ) i_cache (
        .clk(clk),
        .reset(reset),
        .addr(PC),
        .valid(1'b1),
        .rdata(i_cache_rdata),
        .ready(i_cache_ready),
        .hit(i_cache_hit),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HWDATA(HWDATA),
        .HRDATA(HRDATA),
        .HREADY(HREADY),
        .HRESP(HRESP)
    );

    // Instantiate D-Cache with configurable write policy
    DCache #(
        .CACHE_SIZE(DCACHE_SIZE),
        .LINE_SIZE(DCACHE_LINE_SIZE),
        .WAYS(DCACHE_WAYS),
        .WRITE_POLICY(DCACHE_WRITE_POLICY)
    ) d_cache (
        .clk(clk),
        .reset(reset),
        .addr(EX_MEM_ALUResult),
        .wdata(EX_MEM_WriteData),
        .r_w(MemWrite),
        .valid(MemRead | MemWrite),
        .rdata(d_cache_rdata),
        .ready(d_cache_ready),
        .hit(d_cache_hit)
    );

    // Initial PC
    initial begin
        PC = 0;
    end

    // Instruction Fetch (IF) stage
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'b0;
            fetch_enable <= 1'b0;
        end else if (!cpu_stall) begin
            if (fetch_enable) begin
                if (i_cache_ready && i_cache_hit) begin
                    IF_ID_PC <= PC;
                    IF_ID_Instruction <= i_cache_rdata;
                    PC <= PC + 4;
                end else if (HREADY) begin
                    IF_ID_PC <= PC;
                    IF_ID_Instruction <= HRDATA;
                    HADDR <= PC;
                    HTRANS <= 2'b10; // NONSEQ
                    HWRITE <= 0;     // Read operation
                    PC <= PC + 4;
                end               
            end
            fetch_enable <= 1'b1;
        end else begin
            fetch_enable <= 1'b0;
        end
    end

    // Instruction Decode (ID) stage
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            decode_enable <= 1'b0;
            ID_EX_PC <= 0;
            ID_EX_ReadData1 <= 0;
            ID_EX_ReadData2 <= 0;
            ID_EX_Immediate <= 0;
            ID_EX_Rs1 <= 0;
            ID_EX_Rs2 <= 0;
            ID_EX_Rd <= 0;
            ID_EX_Funct7 <= 0;
            ID_EX_Funct3 <= 0;           
        end else if (!cpu_stall) begin
            if (decode_enable) begin
                // Decode instruction
                // (Implementation depends on the instruction set)
                ID_EX_PC <= IF_ID_PC;
                ID_EX_ReadData1 <= ReadData1;
                ID_EX_ReadData2 <= ReadData2;
                ID_EX_Immediate <= Immediate;
                ID_EX_Rs1 <= IF_ID_Instruction[19:15];
                ID_EX_Rs2 <= IF_ID_Instruction[24:20];
                ID_EX_Rd <= IF_ID_Instruction[11:7];
                ID_EX_Funct7 <= IF_ID_Instruction[31:25];
                ID_EX_Funct3 <= IF_ID_Instruction[14:12];
            end
            decode_enable <= fetch_enable;
        end else begin
            decode_enable <= 1'b0;
        end
    end


    // Execute (EX) stage
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            execute_enable <= 1'b0;

            EX_MEM_ALUResult <= 0;
            EX_MEM_WriteData <= 0;
            EX_MEM_Rd <= 0;
            EX_MEM_RegWrite <= 0;
        end else if (!cpu_stall) begin
            if (execute_enable) begin
                // Execute instruction
                // (Implementation depends on the instruction set)
                EX_MEM_ALUResult <= ALUResult;
                EX_MEM_WriteData <= ID_EX_ReadData2;
                EX_MEM_Rd <= ID_EX_Rd;
                EX_MEM_RegWrite <= RegWrite;
            end
            execute_enable <= decode_enable;
        end else begin
            execute_enable <= 1'b0;
        end
    end

    // Memory Access (MEM) stage
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            MEM_WB_ReadData <= 0;
            MEM_WB_Rd <= 0;
            MEM_WB_RegWrite <= 0;
        end else begin
            if (MemRead) begin
                if (d_cache_ready && d_cache_hit) begin
                    MEM_WB_ReadData <= d_cache_rdata;
                end else if (HREADY) begin
                    HADDR <= EX_MEM_ALUResult;
                    HTRANS <= 2'b10; // NONSEQ
                    HWRITE <= 0;     // Read operation
                    MEM_WB_ReadData <= HRDATA;
                end
            end else if (MemWrite) begin
                if (d_cache_ready && d_cache_hit) begin
                    // Cache write handled in D-Cache
                end else if (HREADY) begin
                    HADDR <= EX_MEM_ALUResult;
                    HTRANS <= 2'b10; // NONSEQ
                    HWRITE <= 1;     // Write operation
                    HWDATA <= EX_MEM_WriteData;
                end
            end
            MEM_WB_Rd <= EX_MEM_Rd;
            MEM_WB_RegWrite <= EX_MEM_RegWrite;
        end
    end

    // Write Back (WB) stage
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset logic
        end else begin
            if (MEM_WB_RegWrite) begin
                regfile[MEM_WB_Rd] <= (MemtoReg) ? MEM_WB_ReadData : EX_MEM_ALUResult;
            end
        end
    end

    // Control Unit
    ControlUnit cu (
        .opcode(IF_ID_Instruction[6:0]),
        .ALUOp(ALUOp),
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite)
    );

    // ALU Control Unit
    ALUControlUnit alu_cu (
        .ALUOp(ALUOp),
        .Funct7(ID_EX_Funct7),
        .Funct3(ID_EX_Funct3),
        .ALUControl(ALUControl)
    );

    // ALU
    ALU alu (
        .A(ID_EX_ReadData1),
        .B((ALUSrc) ? ID_EX_Immediate : ID_EX_ReadData2),
        .ALUControl(ALUControl),
        .Result(ALUResult),
        .Zero(Zero)
    );

    // Register File
    RegisterFile rf (
        .clk(clk),
        .RegWrite(MEM_WB_RegWrite),
        .rs1(IF_ID_Instruction[19:15]),
        .rs2(IF_ID_Instruction[24:20]),
        .rd(MEM_WB_Rd),
        .WriteData((MemtoReg) ? MEM_WB_ReadData : EX_MEM_ALUResult),
        .ReadData1(ReadData1),
        .ReadData2(ReadData2)
    );

    // Immediate Generation Unit
    ImmediateGenerator imm_gen (
        .instruction(IF_ID_Instruction),
        .immediate(Immediate)
    );

    // Instantiate JTAG Interface
    JTAG_Interface jtag (
        .TCK(TCK),
        .TMS(TMS),
        .TDI(TDI),
        .TDO(TDO),
        .address(jtag_address),
        .data_out(jtag_data_out),
        .data_in(jtag_data_in),
        .rd_wr(jtag_rd_wr),
        .enable(jtag_enable),
        .step(jtag_step),
        .run(jtag_run)
    );

    // Instantiate CPU Debug Logic
    CPU_Debug debug (
        .clk(clk),
        .reset(reset),
        .enable(jtag_enable),
        .rd_wr(jtag_rd_wr),
        .address(jtag_address),
        .data_out(jtag_data_out),
        .data_in(jtag_data_in),
        .step(jtag_step),
        .run(jtag_run),
        .halt(cpu_halt)
    );

    // CPU halt control logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cpu_stall <= 1'b0;
        end else begin
            cpu_stall <= cpu_halt;
        end
    end

    // AHB Master Interface (example)
    assign HADDR = pc;
    assign HBURST = 3'b000;
    assign HMASTLOCK = 1'b0;
    assign HPROT = 4'b0011;
    assign HSIZE = 3'b010;
    assign HTRANS = fetch_enable ? 2'b10 : 2'b00;
    assign HWDATA = 32'b0;
    assign HWRITE = 1'b0;

endmodule

