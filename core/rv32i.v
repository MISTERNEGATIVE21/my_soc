module PipelineRV32ICore_AHB #(
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
    output reg [31:0] HADDR,   // out: AHB address output
    output reg [2:0] HBURST,   // out: AHB burst type output
    output reg HMASTLOCK,      // out: AHB master lock output
    output reg [3:0] HPROT,    // out: AHB protection control output
    output reg [2:0] HSIZE,    // out: AHB size output
    output reg [1:0] HTRANS,   // out: AHB transfer type output
    output reg [31:0] HWDATA,  // out: AHB write data output
    output reg HWRITE,         // out: AHB write control output
    input [31:0] HRDATA,       // in: AHB read data input
    input HREADY,              // in: AHB ready input
    input HRESP                // in: AHB response input
);

    // Pipeline registers
    reg [31:0] IF_ID_PC;           // out: Program counter to ID stage
    reg [31:32] IF_ID_Instruction; // out: Instruction to ID stage
    reg [31:0] ID_EX_PC;           // out: Program counter to EX stage
    reg [31:0] ID_EX_ReadData1;    // out: Read data 1 to EX stage
    reg [31:0] ID_EX_ReadData2;    // out: Read data 2 to EX stage
    reg [31:0] ID_EX_Immediate;    // out: Immediate value to EX stage
    reg [4:0] ID_EX_Rs1;           // out: Source register 1 to EX stage
    reg [4:0] ID_EX_Rs2;           // out: Source register 2 to EX stage
    reg [4:0] ID_EX_Rd;            // out: Destination register to EX stage
    reg [6:0] ID_EX_Funct7;        // out: Funct7 field to EX stage
    reg [2:0] ID_EX_Funct3;        // out: Funct3 field to EX stage
    reg ID_EX_MemRead;             // out: Memory read enable to EX stage
    reg ID_EX_MemWrite;            // out: Memory write enable to EX stage
    reg ID_EX_RegWrite;            // out: Register write enable to EX stage
    reg ID_EX_MemToReg;            // out: Memory to register signal to EX stage
    reg ID_EX_Branch;              // out: Branch signal to EX stage
    reg [31:0] EX_MEM_PC;          // out: Program counter to MEM stage
    reg [31:0] EX_MEM_ALUResult;   // out: ALU result to MEM stage
    reg [31:0] EX_MEM_WriteData;   // out: Write data to MEM stage
    reg [4:0] EX_MEM_Rd;           // out: Destination register to MEM stage
    reg EX_MEM_RegWrite;           // out: Register write enable to MEM stage
    reg EX_MEM_MemRead;            // out: Memory read enable to MEM stage
    reg EX_MEM_MemWrite;           // out: Memory write enable to MEM stage
    reg EX_MEM_MemToReg;           // out: Memory to register signal to MEM stage
    reg EX_MEM_Branch;             // out: Branch signal to MEM stage
    reg EX_clear_IF_ID;            // out: Branch signal to MEM stage 
    reg [31:0] MEM_WB_PC;          // out: Program counter to WB stage
    reg [31:0] MEM_WB_ReadData;    // out: Read data to WB stage
    reg [31:0] MEM_WB_ALUResult;   // out: ALU result to WB stage
    reg [4:0] MEM_WB_Rd;           // out: Destination register to WB stage
    reg MEM_WB_RegWrite;           // out: Register write enable to WB stage
    reg MEM_WB_MemToReg;           // out: Memory to register signal to WB stage

    // Control signals
    wire fetch_enable;             // out: Fetch enable signal from hazard control
    reg IF_ID_enable_out;          // out: Enable signal to next stage
    reg ID_EX_enable_out;          // out: Enable signal to next stage
    reg EX_MEM_enable_out;         // out: Enable signal to next stage
    reg MEM_WB_enable_out;         // out: Enable signal to next stage

    wire combined_stall;           // out: Combined stall signal
    wire hazard_detected;          // out: Hazard detection signal

    // Decode rs1 and rs2 from IF_ID_Instruction
    wire [4:0] rs1 = IF_ID_Instruction[19:15]; // out: Source register 1
    wire [4:0] rs2 = IF_ID_Instruction[24:20]; // out: Source register 2

    // enalbe signal to next stage



    // IF stage
    IF_stage if_stage (
        .clk(clk),                           // in: Clock signal
        .reset_n(reset_n),                   // in: Asynchronous reset (active low)
        .next_pc(next_pc),                   // in: Next program counter value
        .fetch_enable(fetch_enable),         // in: Fetch enable signal from hazard control
        .combined_stall(combined_stall),     // in: Combined stall signal
        .EX_clear_IF_ID(EX_clear_IF_ID)         // in: clear signal to if stage   
        .IF_ID_PC(IF_ID_PC),                 // out: Program counter to ID stage
        .IF_ID_Instruction(IF_ID_Instruction), // out: Instruction to ID stage
        .IF_ID_enable_out(IF_ID_enable_out)  // out: Enable signal to next stage
    );

    // ID stage
    ID_stage id_stage (
        .clk(clk),                           // in: Clock signal
        .reset_n(reset_n),                   // in: Asynchronous reset (active low)
        .combined_stall(combined_stall),     // in: Combined stall signal
        .EX_clear_IF_ID(EX_clear_IF_ID) // in: clear signal to id stage   
        .IF_ID_PC(IF_ID_PC),                 // in: Program counter from IF stage
        .IF_ID_Instruction(IF_ID_Instruction), // in: Instruction from IF stage
        .IF_ID_enable_out(IF_ID_enable_out), // in: Enable signal from IF stage
        .ID_EX_PC(ID_EX_PC),                 // out: Program counter to EX stage
        .ID_EX_ReadData1(ID_EX_ReadData1),   // out: Read data 1 to EX stage
        .ID_EX_ReadData2(ID_EX_ReadData2),   // out: Read data 2 to EX stage
        .ID_EX_Immediate(ID_EX_Immediate),   // out: Immediate value to EX stage
        .ID_EX_Rs1(ID_EX_Rs1),               // out: Source register 1 to EX stage
        .ID_EX_Rs2(ID_EX_Rs2),               // out: Source register 2 to EX stage
        .ID_EX_Rd(ID_EX_Rd),                 // out: Destination register to EX stage
        .ID_EX_Funct7(ID_EX_Funct7),         // out: Funct7 field to EX stage
        .ID_EX_Funct3(ID_EX_Funct3),         // out: Funct3 field to EX stage
        .ID_EX_ALUSrc(ID_EX_ALUSrc),         // out: ALU source control signal to EX stage
        .ID_EX_ALUOp(ID_EX_ALUOp),           // out: ALU operation control signal to EX stage
        .ID_EX_Branch(ID_EX_Branch),         // out: Branch signal to EX stage
        .ID_EX_Jump(ID_EX_Jump),             // out: Branch signal to EX stage       
        .ID_EX_MemRead(ID_EX_MemRead),       // out: Memory read enable to EX stage
        .ID_EX_MemWrite(ID_EX_MemWrite),     // out: Memory write enable to EX stage
        .ID_EX_MemToReg(ID_EX_MemToReg),     // out: Memory to register signal to EX stage
        .ID_EX_RegWrite(ID_EX_RegWrite),     // out: Register write enable to EX stage
        .ID_EX_enable_out(ID_EX_enable_out)  // out: Enable signal to EX stage
    );   

    // EX stage
    EX_stage ex_stage (
        .clk(clk),                           // in: Clock signal
        .reset_n(reset_n),                   // in: Asynchronous reset (active low)
        .combined_stall(combined_stall),     // in: Combined stall signal
        .ID_EX_enable_out(ID_EX_enable_out), // in: Enable signal from ID stage
        .ID_EX_PC(ID_EX_PC),                 // in: Program counter from ID stage
        .ID_EX_ReadData1(ID_EX_ReadData1),   // in: Read data 1 from ID stage
        .ID_EX_ReadData2(ID_EX_ReadData2),   // in: Read data 2 from ID stage
        .ID_EX_Immediate(ID_EX_Immediate),   // in: Immediate value from ID stage
        .ID_EX_Rd(ID_EX_Rd),                 // in: Destination register from ID stage
        .ID_EX_Funct7(ID_EX_Funct7),         // in: Funct7 field from ID stage
        .ID_EX_Funct3(ID_EX_Funct3),         // in: Funct3 field from ID stage
        .ID_EX_ALUSrc(ID_EX_ALUSrc),         // in: ALU source control signal from ID stage
        .ID_EX_ALUOp(ID_EX_ALUOp),           // in: ALU operation control signal
        .ID_EX_Branch(ID_EX_Branch),         // in: Branch signal from ID stage
        .ID_EX_Jump(ID_EX_Jump),         // in: Branch signal from ID stage       
        .ID_EX_MemRead(ID_EX_MemRead),       // in: Memory read enable from ID stage
        .ID_EX_MemWrite(ID_EX_MemWrite),     // in: Memory write enable from ID stage
        .ID_EX_MemToReg(ID_EX_MemToReg),     // in: Memory to register signal from ID stage
        .ID_EX_RegWrite(ID_EX_RegWrite),     // in: Register write enable from ID stage
        .EX_MEM_PC(EX_MEM_PC),               // out: Program counter to MEM stage
        .EX_MEM_ALUResult(EX_MEM_ALUResult), // out: ALU result to MEM stage
        .EX_MEM_WriteData(EX_MEM_WriteData), // out: Write data to MEM stage
        .EX_MEM_Rd(EX_MEM_Rd),               // out: Destination register to MEM stage
        .EX_MEM_MemRead(EX_MEM_MemRead),     // out: Memory read control signal to MEM stage
        .EX_MEM_MemWrite(EX_MEM_MemWrite),   // out: Memory write control signal to MEM stage
        .EX_MEM_MemToReg(EX_MEM_MemToReg),   // out: Memory to register control signal to MEM stage
        .EX_MEM_RegWrite(EX_MEM_RegWrite),   // out: Register write control signal to MEM stage
        .EX_MEM_enable_out(EX_MEM_enable_out) // out: Enable signal to MEM stage
        .EX_clear_IF_ID(EX_clear_IF_ID) // out: Enable signal to MEM stage       
    );

    // MEM stage
    MEM_stage mem_stage (
        .clk(clk),                           // in: Clock signal
        .reset_n(reset_n),                   // in: Asynchronous reset (active low)
        .combined_stall(combined_stall),     // in: Combined stall signal
        .EX_MEM_enable_out(EX_MEM_enable_out), // in: Enable signal from EX stage
        .EX_MEM_PC(EX_MEM_PC),               // in: Program counter from EX stage
        .EX_MEM_ALUResult(EX_MEM_ALUResult), // in: ALU result from EX stage
        .EX_MEM_WriteData(EX_MEM_WriteData), // in: Write data from EX stage
        .EX_MEM_Rd(EX_MEM_Rd),               // in: Destination register from EX stage
        .EX_MEM_RegWrite(EX_MEM_RegWrite),   // in: Register write enable from EX stage
        .EX_MEM_MemRead(EX_MEM_MemRead),     // in: Memory read enable from EX stage
        .EX_MEM_MemWrite(EX_MEM_MemWrite),   // in: Memory write enable from EX stage
        .EX_MEM_MemToReg(EX_MEM_MemToReg),   // in: Memory to register signal to MEM stage
        .MEM_WB_PC(MEM_WB_PC),               // out: Program counter to WB stage
        .MEM_WB_ReadData(MEM_WB_ReadData),   // out: Read data to WB stage
        .MEM_WB_ALUResult(MEM_WB_ALUResult), // out: ALU result to WB stage
        .MEM_WB_Rd(MEM_WB_Rd),               // out: Destination register to WB stage
        .MEM_WB_RegWrite(MEM_WB_RegWrite),   // out: Register write enable to WB stage
        .MEM_WB_MemToReg(MEM_WB_MemToReg),   // out: Memory to register signal to WB stage
        .MEM_WB_enable_out(MEM_WB_enable_out) // out: Enable signal to WB stage
    );

    // WB stage
    WB_stage wb_stage (
        .clk(clk),                           // in: Clock signal
        .reset_n(reset_n),                   // in: Asynchronous reset (active low)
        .combined_stall(combined_stall),     // in: Combined stall signal
        .MEM_WB_PC(MEM_WB_PC),               // in: Program counter from MEM stage
        .MEM_WB_ReadData(MEM_WB_ReadData),   // in: Read data from MEM stage
        .MEM_WB_ALUResult(MEM_WB_ALUResult), // in: ALU result from MEM stage
        .MEM_WB_Rd(MEM_WB_Rd),               // in: Destination register from MEM stage
        .MEM_WB_RegWrite(MEM_WB_RegWrite),   // in: Register write enable from MEM stage
        .MEM_WB_MemToReg(MEM_WB_MemToReg),   // in: Memory to register signal from MEM stage
        .MEM_WB_enable_out(MEM_WB_enable_out), // in: Enable signal from MEM stage
        .WB_RegWrite(WB_RegWrite),           // out: Register write enable to register file
        .WB_WriteData(WB_WriteData),         // out: Write data to register file
        .WB_Rd(WB_Rd),                       // out: Destination register to register file
        .WB_PC(WB_PC)                        // out: Program counter to next stage
    );

    // Register file
    registerfile regfile (
        .clk(clk),                           // in: Clock signal
        .reset_n(reset_n),                   // in: Asynchronous reset (active low)
        .rs1(rs1),                           // in: Source register 1
        .rs2(rs2),                           // in: Source register 2
        .rd(WB_Rd),                          // in: Destination register
        .we(WB_RegWrite),                    // in: Write enable signal
        .wd(WB_WriteData),                   // in: Write data
        .rd1(ID_EX_ReadData1),               // out: Read data 1
        .rd2(ID_EX_ReadData2)                // out: Read data 2
    );

    // Hazard detection unit
    HazardDetectionUnit hazard_unit (
        .ID_EX_MemRead(ID_EX_MemRead),       // in: Memory read enable from EX stage
        .ID_EX_Rd(ID_EX_Rd),                 // in: Destination register from EX stage
        .IF_ID_Rs1(rs1),                     // in: Source register 1 from ID stage
        .IF_ID_Rs2(rs2),                     // in: Source register 2 from ID stage
        .hazard_detected(hazard_detected)    // out: Hazard detection signal
    );

    // Control logic
    assign fetch_enable = !combined_stall;   // out: Fetch enable signal
    assign combined_stall = hazard_detected; // out: Combined stall signal

    // Next PC logic
    wire [31:0] next_pc;                     // out: Next program counter value
    assign next_pc = EX_MEM_PC                  /* logic to determine the next PC value */;

endmodule