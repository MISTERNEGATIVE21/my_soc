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

