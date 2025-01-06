/* Summary of Changes:
fetch_enable and fetch_enable_out are not necessarily the same.

fetch_enable is an input signal that indicates whether the instruction fetch stage should proceed with fetching the next instruction.
fetch_enable_out is an output signal that can be used to indicate the status of the fetch stage, such as whether the fetch stage is ready to 
fetch the next instruction or needs to stall.

Bubble Insertion: Added logic to insert a NOP instruction (32'h00000013) into the pipeline when combined_stall is asserted.
Reset Logic: Ensured the pipeline registers are reset to initial values, including the NOP instruction for IF_ID_Instruction.
fetch_enable Handling: Updated the handling of fetch_enable and fetch_enable_out signals to control whether fetching should continue or stall.
Program Counter Update: Added a separate always block to update the PC based on the fetch_enable and combined_stall signals.
This implementation ensures that the instruction is fetched from the cache when there is a hit, a NOP instruction is inserted into the pipeline
when a stall condition is detected, and the fetch_enable signal is properly controlled. 

*/
module IF_stage (
    input wire clk,
    input wire reset,
    input wire fetch_enable,
    input wire [31:0] PC,
    input wire [31:0] HRDATA,
    input wire i_cache_ready,
    input wire i_cache_hit,
    input wire HREADY,
    input wire combined_stall, // New input for combined stall signal
    output reg [31:0] IF_ID_PC,
    output reg [31:0] IF_ID_Instruction,
    output reg [31:0] HADDR,
    output reg [1:0] HTRANS,
    output reg HWRITE,
    output reg fetch_enable_out // Output fetch_enable signal
);

    reg [31:0] next_PC;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            IF_ID_PC <= 32'b0;
            IF_ID_Instruction <= 32'h00000013; // NOP instruction
            HADDR <= 32'b0;
            HTRANS <= 2'b00; // IDLE
            HWRITE <= 1'b0; // Read operation
            fetch_enable_out <= 1'b0;
            next_PC <= 32'b0;
        end else if (combined_stall) begin
            // Insert bubble (NOP) into the pipeline
            IF_ID_Instruction <= 32'h00000013; // NOP instruction
            fetch_enable_out <= 1'b0;
        end else if (fetch_enable) begin
                if (i_cache_ready && i_cache_hit) begin
                    IF_ID_PC <= PC;
                    IF_ID_Instruction <= i_cache_rdata; // Fetch from cache on hit
                    next_PC <= PC + 4;
                    fetch_enable_out <= 1'b1; // Continue fetching
                end else if (HREADY) begin
                    IF_ID_PC <= PC;
                    IF_ID_Instruction <= HRDATA; // Fetch from HRDATA on miss
                    HADDR <= PC;
                    HTRANS <= 2'b10; // NONSEQ
                    HWRITE <= 1'b0; // Read operation
                    next_PC <= PC + 4;
                    fetch_enable_out <= 1'b1; // Continue fetching
                end else begin
                    fetch_enable_out <= 1'b0; // Stall fetching
                end               
        end else begin
            fetch_enable_out <= 1'b0; // Stall fetching
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC <= 32'b0;
        end else if (!combined_stall && fetch_enable) begin
            PC <= next_PC; // Update PC if not stalling and fetch is enabled
        end
    end
endmodule

module ID_stage (
    input wire clk,
    input wire reset,
    input wire fetch_enable_out, // Updated input from fetch stage
    input wire [31:0] IF_ID_PC,
    input wire [31:0] IF_ID_Instruction,
    input wire [31:0] ReadData1,
    input wire [31:0] ReadData2,
    input wire [31:0] Immediate,
    input wire combined_stall, // New input for combined stall signal
    output reg [31:0] ID_EX_PC,
    output reg [31:0] ID_EX_ReadData1,
    output reg [31:0] ID_EX_ReadData2,
    output reg [31:0] ID_EX_Immediate,
    output reg [4:0] ID_EX_Rs1,
    output reg [4:0] ID_EX_Rs2,
    output reg [4:0] ID_EX_Rd,
    output reg [6:0] ID_EX_Funct7,
    output reg [2:0] ID_EX_Funct3,
    output reg decode_enable_out // Output decode_enable_out signal
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ID_EX_PC <= 32'b0;
            ID_EX_ReadData1 <= 32'b0;
            ID_EX_ReadData2 <= 32'b0;
            ID_EX_Immediate <= 32'b0;
            ID_EX_Rs1 <= 5'b0;
            ID_EX_Rs2 <= 5'b0;
            ID_EX_Rd <= 5'b0;
            ID_EX_Funct7 <= 7'b0;
            ID_EX_Funct3 <= 3'b0;
            decode_enable_out <= 1'b0;
        end else if (combined_stall) begin
            // Insert bubble (NOP) into the pipeline
            ID_EX_PC <= 32'b0;
            ID_EX_ReadData1 <= 32'b0;
            ID_EX_ReadData2 <= 32'b0;
            ID_EX_Immediate <= 32'b0;
            ID_EX_Rs1 <= 5'b0;
            ID_EX_Rs2 <= 5'b0;
            ID_EX_Rd <= 5'b0;
            ID_EX_Funct7 <= 7'b0;
            ID_EX_Funct3 <= 3'b0;
            decode_enable_out <= 1'b0;
        end else if (fetch_enable_out) begin
            // Decode instruction
            ID_EX_PC <= IF_ID_PC;
            ID_EX_ReadData1 <= ReadData1;
            ID_EX_ReadData2 <= ReadData2;
            ID_EX_Immediate <= Immediate;
            ID_EX_Rs1 <= IF_ID_Instruction[19:15];
            ID_EX_Rs2 <= IF_ID_Instruction[24:20];
            ID_EX_Rd <= IF_ID_Instruction[11:7];
            ID_EX_Funct7 <= IF_ID_Instruction[31:25];
            ID_EX_Funct3 <= IF_ID_Instruction[14:12];
            decode_enable_out <= 1'b1; // Enable decoding for the next stage
        end else begin
            decode_enable_out <= 1'b0; // Disable decoding
        end
    end
endmodule

module EX_stage (
    input wire clk,
    input wire reset,
    input wire execute_enable,
    input wire decode_enable_out,
    input wire [31:0] ID_EX_ReadData1,
    input wire [31:0] ID_EX_ReadData2,
    input wire [31:0] ID_EX_Immediate,
    input wire [4:0] ID_EX_Rd,
    input wire [6:0] ID_EX_Funct7,
    input wire [2:0] ID_EX_Funct3,
    input wire [3:0] ALUControl,
    input wire combined_stall, // New input for combined stall signal
    output reg [31:0] EX_MEM_ALUResult,
    output reg [31:0] EX_MEM_WriteData,
    output reg [4:0] EX_MEM_Rd,
    output reg EX_MEM_RegWrite,
    output reg execute_enable_out // Output execute_enable signal
);

    wire [31:0] ALUResult;
    wire Zero;

    // ALU
    ALU alu (
        .A(ID_EX_ReadData1),
        .B((ALUSrc) ? ID_EX_Immediate : ID_EX_ReadData2),
        .ALUControl(ALUControl),
        .Result(ALUResult),
        .Zero(Zero)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            EX_MEM_ALUResult <= 32'b0;
            EX_MEM_WriteData <= 32'b0;
            EX_MEM_Rd <= 5'b0;
            EX_MEM_RegWrite <= 1'b0;
            execute_enable_out <= 1'b0;
        end else if (combined_stall) begin
            // Insert bubble (NOP) into the pipeline
            EX_MEM_ALUResult <= 32'b0;
            EX_MEM_WriteData <= 32'b0;
            EX_MEM_Rd <= 5'b0;
            EX_MEM_RegWrite <= 1'b0;
            execute_enable_out <= 1'b0;
        end else if (execute_enable) begin
                EX_MEM_ALUResult <= ALUResult;
                EX_MEM_WriteData <= ID_EX_ReadData2;
                EX_MEM_Rd <= ID_EX_Rd;
                EX_MEM_RegWrite <= RegWrite;
            execute_enable_out <= decode_enable_out; // Propagate decode_enable_out to execute_enable_out
        end else begin
            execute_enable_out <= 1'b0; // Disable execution
        end
    end
endmodule

module MEM_stage (
    input wire clk,
    input wire reset,
    input wire execute_enable_out, // Updated input from execute stage
    input wire [31:0] EX_MEM_ALUResult,
    input wire [31:0] EX_MEM_WriteData,
    input wire [4:0] EX_MEM_Rd,
    input wire EX_MEM_RegWrite,
    input wire MemRead,
    input wire MemWrite,
    input wire [31:0] HRDATA,
    input wire HREADY,
    input wire d_cache_ready,
    input wire d_cache_hit,
    input wire [31:0] d_cache_rdata,
    input wire combined_stall, // New input for combined stall signal
    output reg [31:0] MEM_WB_ReadData,
    output reg [4:0] MEM_WB_Rd,
    output reg MEM_WB_RegWrite,
    output reg [31:0] HADDR,
    output reg [1:0] HTRANS,
    output reg HWRITE,
    output reg [31:0] HWDATA,
    output reg memory_enable_out // Output memory enable signal
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            MEM_WB_ReadData <= 32'b0;
            MEM_WB_Rd <= 5'b0;
            MEM_WB_RegWrite <= 1'b0;
            HADDR <= 32'b0;
            HTRANS <= 2'b00; // IDLE
            HWRITE <= 1'b0;
            HWDATA <= 32'b0;
            memory_enable_out <= 1'b0;
        end else if (combined_stall) begin
            // Insert bubble (NOP) into the pipeline
            MEM_WB_ReadData <= 32'b0;
            MEM_WB_Rd <= 5'b0;
            MEM_WB_RegWrite <= 1'b0;
            memory_enable_out <= 1'b0;
        end else if (execute_enable_out) begin
            if (MemRead) begin
                if (d_cache_ready && d_cache_hit) begin
                    MEM_WB_ReadData <= d_cache_rdata;
                end else if (HREADY) begin
                    HADDR <= EX_MEM_ALUResult;
                    HTRANS <= 2'b10; // NONSEQ
                    HWRITE <= 1'b0; // Read operation
                    MEM_WB_ReadData <= HRDATA;
                end
            end else if (MemWrite) begin
                if (d_cache_ready && d_cache_hit) begin
                    // Cache write handled in D-Cache
                end else if (HREADY) begin
                    HADDR <= EX_MEM_ALUResult;
                    HTRANS <= 2'b10; // NONSEQ
                    HWRITE <= 1'b1; // Write operation
                    HWDATA <= EX_MEM_WriteData;
                end
            end
            MEM_WB_Rd <= EX_MEM_Rd;
            MEM_WB_RegWrite <= EX_MEM_RegWrite;
            memory_enable_out <= 1'b1; // Enable memory stage for the next stage
        end else begin
            memory_enable_out <= 1'b0; // Disable memory stage
        end
    end
endmodule

module WB_stage (
    input wire clk,
    input wire reset,
    input wire MEM_WB_RegWrite,
    input wire [31:0] MEM_WB_ReadData,
    input wire [4:0] MEM_WB_Rd,
    input wire [31:0] EX_MEM_ALUResult,
    input wire MemtoReg,
    input wire combined_stall, // New input for combined stall signal
    input wire memory_enable_out, // Updated input from memory stage
    output reg [31:0] regfile [0:31]
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset logic
            integer i;
            for (i = 0; i < 32; i = i + 1) begin
                regfile[i] <= 32'b0;
            end
        end else if (combined_stall) begin
            // Insert bubble (NOP) into the pipeline
            // No operation needed, just stall the pipeline
        end else if (memory_enable_out) begin
            if (MEM_WB_RegWrite) begin
                regfile[MEM_WB_Rd] <= (MemtoReg) ? MEM_WB_ReadData : EX_MEM_ALUResult;
            end
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
    input HRESP,
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

     // Internal signals for CPU control
    reg [31:0] regfile [0:31]; // Register file
    reg fetch_enable, decode_enable, execute_enable; // Pipeline stage enables

    reg debug_stall; // Debug stall signal

    // Hazard detection unit signals
    wire hazard_stall;

    // Combined stall signal
    wire combined_stall = debug_stall || hazard_stall;

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

    // Instantiate pipeline stages
    IF_stage if_stage (
        .clk(clk),
        .reset(reset),
        .fetch_enable(fetch_enable), // Input signal
        .PC(PC),
        .HRDATA(HRDATA),
        .i_cache_ready(i_cache_ready),
        .i_cache_hit(i_cache_hit),
        .HREADY(HREADY),
        .combined_stall(combined_stall), // Pass combined_stall signal
        .IF_ID_PC(IF_ID_PC),
        .IF_ID_Instruction(IF_ID_Instruction),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE)
        .fetch_enable_out(fetch_enable) // Output signal
    );

    ID_stage id_stage (
        .clk(clk),
        .reset(reset),
        .decode_enable(decode_enable),
        .fetch_enable(fetch_enable),
        .IF_ID_PC(IF_ID_PC),
        .IF_ID_Instruction(IF_ID_Instruction),
        .ReadData1(ReadData1),
        .ReadData2(ReadData2),
        .Immediate(Immediate),
        .combined_stall(combined_stall), // Pass combined_stall signal
        .ID_EX_PC(ID_EX_PC),
        .ID_EX_ReadData1(ID_EX_ReadData1),
        .ID_EX_ReadData2(ID_EX_ReadData2),
        .ID_EX_Immediate(ID_EX_Immediate),
        .ID_EX_Rs1(ID_EX_Rs1),
        .ID_EX_Rs2(ID_EX_Rs2),
        .ID_EX_Rd(ID_EX_Rd),
        .ID_EX_Funct7(ID_EX_Funct7),
        .ID_EX_Funct3(ID_EX_Funct3)
    );

    EX_stage ex_stage (
        .clk(clk),
        .reset(reset),
        .execute_enable(execute_enable),
        .decode_enable(decode_enable),
        .ID_EX_ReadData1(ID_EX_ReadData1),
        .ID_EX_ReadData2(ID_EX_ReadData2),
        .ID_EX_Immediate(ID_EX_Immediate),
        .ID_EX_Rd(ID_EX_Rd),
        .ID_EX_Funct7(ID_EX_Funct7),
        .ID_EX_Funct3(ID_EX_Funct3),
        .ALUControl(ALUControl),
        .combined_stall(combined_stall), // Pass combined_stall signal
        .EX_MEM_ALUResult(EX_MEM_ALUResult),
        .EX_MEM_WriteData(EX_MEM_WriteData),
        .EX_MEM_Rd(EX_MEM_Rd),
        .EX_MEM_RegWrite(EX_MEM_RegWrite)
    );

    MEM_stage mem_stage (
        .clk(clk),
        .reset(reset),
        .EX_MEM_ALUResult(EX_MEM_ALUResult),
        .EX_MEM_WriteData(EX_MEM_WriteData),
        .EX_MEM_Rd(EX_MEM_Rd),
        .EX_MEM_RegWrite(EX_MEM_RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .HRDATA(HRDATA),
        .HREADY(HREADY),
        .d_cache_ready(d_cache_ready),
        .d_cache_hit(d_cache_hit),
        .d_cache_rdata(d_cache_rdata),
        .combined_stall(combined_stall), // Pass combined_stall signal
        .MEM_WB_ReadData(MEM_WB_ReadData),
        .MEM_WB_Rd(MEM_WB_Rd),
        .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HWDATA(HWDATA)
    );

    WB_stage wb_stage (
        .clk(clk),
        .reset(reset),
        .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .MEM_WB_ReadData(MEM_WB_ReadData),
        .MEM_WB_Rd(MEM_WB_Rd),
        .EX_MEM_ALUResult(EX_MEM_ALUResult),
        .MemtoReg(MemtoReg),
        .combined_stall(combined_stall), // Pass combined_stall signal
        .regfile(regfile)
    );

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

    // Hazard Detection Unit
    HazardDetectionUnit hdu (
        .ID_EX_Rs1(ID_EX_Rs1),
        .ID_EX_Rs2(ID_EX_Rs2),
        .EX_MEM_Rd(EX_MEM_Rd),
        .EX_MEM_RegWrite(EX_MEM_RegWrite),
        .MEM_WB_Rd(MEM_WB_Rd),
        .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .hazard_stall(hazard_stall)
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
        .halt(debug_stall)
    );

    // Initial PC
    initial begin
        PC = 0;
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

