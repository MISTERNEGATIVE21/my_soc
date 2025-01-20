

module PipelineRV32ICore_AHB_Cache #(
    parameter ICACHE_SIZE = 1024,
    parameter ICACHE_LINE_SIZE = 32,
    parameter ICACHE_WAYS = 1,
    parameter DCACHE_SIZE = 1024,
    parameter DCACHE_LINE_SIZE = 32,
    parameter DCACHE_WAYS = 1,
    parameter DCACHE_WRITE_POLICY = "WRITE_BACK"
)(
    input clk,                 // Clock input
    input reset_n,             // Asynchronous reset (active low)
    // AHB Interface
    output reg [31:0] HADDR,   // AHB address output
    output reg [2:0] HBURST,   // AHB burst type output
    output reg HMASTLOCK,      // AHB master lock output
    output reg [3:0] HPROT,    // AHB protection control output
    output reg [2:0] HSIZE,    // AHB size output
    output reg [1:0] HTRANS,   // AHB transfer type output
    output reg [31:0] HWDATA,  // AHB write data output
    output reg HWRITE,         // AHB write control output
    input [31:0] HRDATA,       // AHB read data input
    input HREADY,              // AHB ready input
    input HRESP                // AHB response input
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
    reg ID_EX_MemRead;         // New register to store MemRead signal
    reg [31:0] EX_MEM_ALUResult;
    reg [31:0] EX_MEM_WriteData;
    reg [4:0] EX_MEM_Rd;
    reg EX_MEM_RegWrite;
    reg EX_MEM_MemRead;        // New register to store MemRead signal
    reg EX_MEM_MemWrite;       // New register to store MemWrite signal
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

     // Internal signals for CPU control
    reg [31:0] regfile [0:31]; // Register file
    reg fetch_enable, IF_ID_enable_out, ID_EX_enable_out, EX_MEM_enable_out, MEM_WB_enable_out; // Pipeline stage enables

    // Debug stall signal
    reg debug_stall; 

    // Hazard detection unit signals
    wire hazard_stall;

    // mem stall unit signals
    wire mem_stall;

    // Combined stall signal
    wire combined_stall = debug_stall || hazard_stall || mem_stall;

    // Control signal for fetch_enable
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            fetch_enable <= 1'b0;
        end else if (combined_stall) begin
            fetch_enable <= 1'b0;
        end else begin
            fetch_enable <= 1'b1; // Enable fetching if no stall
        end
    end

    // Instantiate I-Cache
    ICache #(
        .CACHE_SIZE(ICACHE_SIZE),
        .LINE_SIZE(ICACHE_LINE_SIZE),
        .WAYS(ICACHE_WAYS)
    ) i_cache (
        .clk(clk),               // Input signal
        .reset(~reset_n),        // Input signal
        .addr(PC),               // Input signal
        .valid(1'b1),            // Input signal
        .rdata(i_cache_rdata),   // Output signal
        .ready(i_cache_ready),   // Output signal
        .hit(i_cache_hit),       // Output signal
        .HADDR(HADDR),           // Output signal
        .HTRANS(HTRANS),         // Output signal
        .HWRITE(HWRITE),         // Output signal
        .HWDATA(HWDATA),         // Output signal
        .HRDATA(HRDATA),         // Input signal
        .HREADY(HREADY),         // Input signal
        .HRESP(HRESP)            // Input signal
    );

    // Instantiate RegisterFile
    RegisterFile rf (
        .clk(clk),
        .rst_n(reset_n),
        .read_reg1(ID_EX_Rs1),
        .read_reg2(ID_EX_Rs2),
        .write_reg(MEM_WB_Rd),
        .write_data(MEM_WB_ReadData),
        .reg_write(MEM_WB_RegWrite),
        .read_data1(ReadData1),
        .read_data2(ReadData2)
    );

    //stage1----------------------------------------------------------------------------------------------------------------
    // Instantiate pipeline stages
    IF_stage if_stage (
        .clk(clk),               // Input signal
        .reset(~reset_n),        // Input signal
        .fetch_enable(fetch_enable), // Input signal
        .PC(PC),                 // Input signal
        .i_cache_ready(i_cache_ready), // Input signal
        .i_cache_hit(i_cache_hit),     // Input signal
        .i_cache_rdata(i_cache_rdata), // Input signal
        .combined_stall(combined_stall), // Input signal
        .IF_ID_PC(IF_ID_PC),     // Output signal
        .IF_ID_Instruction(IF_ID_Instruction), // Output signal
        .IF_ID_enable_out(fetch_enable_out) // Output signal
    );

    //stage2----------------------------------------------------------------------------------------------------------------
    ID_stage id_stage (
        .clk(clk),                       // Input signal
        .reset(~reset_n),                // Input signal
        .combined_stall(combined_stall), // Input signal
        .IF_ID_enable_out(IF_ID_enable_out), // Input signal
        .IF_ID_PC(IF_ID_PC),             // Input signal
        .IF_ID_Instruction(IF_ID_Instruction), // Input signal
        .ID_EX_PC(ID_EX_PC),             // Output signal
        .ID_EX_ReadData1(ID_EX_ReadData1), // Output signal
        .ID_EX_ReadData2(ID_EX_ReadData2), // Output signal
        .ID_EX_Immediate(ID_EX_Immediate), // Output signal
        .ID_EX_Rs1(ID_EX_Rs1),           // Output signal
        .ID_EX_Rs2(ID_EX_Rs2),           // Output signal
        .ID_EX_Rd(ID_EX_Rd),             // Output signal
        .ID_EX_Funct7(ID_EX_Funct7),     // Output signal
        .ID_EX_Funct3(ID_EX_Funct3),     // Output signal
        .ID_EX_enable_out(decode_enable_out), // Output signal
        .ID_EX_ALUOp(ALUOp),             // Output signal
        .ID_EX_MemRead(ID_EX_MemRead),   // Output signal
        .ID_EX_MemToReg(MemtoReg),       // Output signal
        .ID_EX_MemWrite(MemWrite),       // Output signal
        .ID_EX_ALUSrc(ALUSrc),           // Output signal
        .ID_EX_RegWrite(RegWrite),       // Output signal
        .ID_EX_ReadData1_out(ReadData1), // Output signal
        .ID_EX_ReadData2_out(ReadData2)  // Output signal
    );

    EX_stage ex_stage (
        .clk(clk),               // Input signal
        .reset(~reset_n),        // Input signal
        .decode_enable_out(ID_EX_enable_out), // Input signal
        .ID_EX_ReadData1(ID_EX_ReadData1), // Input signal
        .ID_EX_ReadData2(ID_EX_ReadData2), // Input signal
        .ID_EX_Immediate(ID_EX_Immediate), // Input signal
        .ID_EX_Rd(ID_EX_Rd),     // Input signal
        .ID_EX_Funct7(ID_EX_Funct7), // Input signal
        .ID_EX_Funct3(ID_EX_Funct3), // Input signal
        .ALUControl(ALUControl), // Output signal
        .combined_stall(combined_stall), // Input signal
        .EX_MEM_ALUResult(EX_MEM_ALUResult), // Output signal
        .EX_MEM_WriteData(EX_MEM_WriteData), // Output signal
        .EX_MEM_Rd(EX_MEM_Rd),   // Output signal
        .EX_MEM_RegWrite(EX_MEM_RegWrite), // Output signal
        .EX_MEM_execute_enable_out(execute_enable_out) // Output signal
    );

    MEM_stage mem_stage (
        .clk(clk),               // Input signal
        .reset(~reset_n),        // Input signal
        .execute_enable_out(execute_enable_out), // Input signal
        .EX_MEM_ALUResult(EX_MEM_ALUResult), // Input signal
        .EX_MEM_WriteData(EX_MEM_WriteData), // Input signal
        .EX_MEM_Rd(EX_MEM_Rd),   // Input signal
        .EX_MEM_RegWrite(EX_MEM_RegWrite), // Input signal
        .MemRead(MemRead),       // Output signal
        .MemWrite(MemWrite),     // Output signal
        .d_cache_ready(d_cache_ready), // Output signal
        .d_cache_hit(d_cache_hit), // Output signal
        .d_cache_rdata(d_cache_rdata), // Output signal
        .combined_stall(combined_stall), // Input signal
        .MEM_WB_ReadData(MEM_WB_ReadData), // Output signal
        .MEM_WB_Rd(MEM_WB_Rd),   // Output signal
        .MEM_WB_RegWrite(MEM_WB_RegWrite), // Output signal
        .memory_enable_out(memory_enable_out), // Output signal
        .mem_stall(mem_stall)    // Output signal
    );

    // Instantiate D-Cache with configurable write policy
    DCache #(
        .CACHE_SIZE(DCACHE_SIZE),
        .LINE_SIZE(DCACHE_LINE_SIZE),
        .WAYS(DCACHE_WAYS),
        .WRITE_POLICY(DCACHE_WRITE_POLICY)
    ) d_cache (
        .clk(clk),               // Input signal
        .reset(~reset_n),        // Input signal
        .addr(EX_MEM_ALUResult), // Input signal
        .wdata(EX_MEM_WriteData),// Input signal
        .r_w(MemWrite),          // Input signal
        .valid(MemRead | MemWrite), // Input signal
        .rdata(d_cache_rdata),   // Output signal
        .ready(d_cache_ready),   // Output signal
        .hit(d_cache_hit)        // Output signal
    );

    WB_stage wb_stage (
        .clk(clk),               // Input signal
        .reset(~reset_n),        // Input signal
        .MEM_WB_RegWrite(MEM_WB_RegWrite), // Input signal
        .MEM_WB_ReadData(MEM_WB_ReadData), // Input signal
        .MEM_WB_Rd(MEM_WB_Rd),   // Input signal
        .EX_MEM_ALUResult(EX_MEM_ALUResult), // Input signal
        .MemtoReg(MemtoReg),     // Output signal
        .combined_stall(combined_stall), // Input signal
        .memory_enable_out(memory_enable_out), // Output signal
        .regfile(regfile)        // Output signal
    );

    // Hazard Detection Unit
    HazardDetectionUnit hdu (
        .ID_EX_Rs1(ID_EX_Rs1),   // Input signal
        .ID_EX_Rs2(ID_EX_Rs2),   // Input signal
        .EX_MEM_Rd(EX_MEM_Rd),   // Input signal
        .EX_MEM_RegWrite(EX_MEM_RegWrite), // Input signal
        .MEM_WB_Rd(MEM_WB_Rd),   // Input signal
        .MEM_WB_RegWrite(MEM_WB_RegWrite), // Input signal
        .hazard_stall(hazard_stall) // Output signal
    );

    // Instantiate the cpu_counter module
    clk_counter clk_counter (
        .clk(clk),               // Input signal
        .reset_n(reset_n),       // Input signal
        .counter(cpu_counter_value) // Output signal
    );

    // Instantiate the CPU counter
    wire pc_changed = (PC != prev_PC); // Detect PC changes
    wire [63:0] cpu_counter_value;

    pc_counter pc_counter (
        .clk(clk),               // Input signal
        .reset_n(reset_n),       // Input signal
        .pc_changed(pc_changed), // Input signal
        .counter(cpu_counter_value) // Output signal
    );

    // Update prev_PC
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            prev_PC <= 0;
        end else begin
            prev_PC <= PC;
        end
    end

    // Initial PC
    initial begin
        PC = 0;
        prev_PC = 0;
    end    

    // AHB Master Interface (example)
    assign HADDR = PC;
    assign HBURST = 3'b000;
    assign HMASTLOCK = 1'b0;
    assign HPROT = 4'b0011;
    assign HSIZE = 3'b010;
    assign HTRANS = fetch_enable ? 2'b10 : 2'b00;
    assign HWDATA = 32'b0;
    assign HWRITE = 1'b0;

endmodule

