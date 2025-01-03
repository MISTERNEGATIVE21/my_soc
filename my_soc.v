module my_soc (
    input clk,
    input reset,
    input tck,    // JTAG clock
    input tms,    // JTAG mode select
    input tdi,    // JTAG data in
    output tdo    // JTAG data out
);

    // Internal wires for interconnecting the components
    wire [31:0] pc;
    wire [31:0] instruction;
    wire [31:0] alu_result;
    wire [31:0] rs1_data, rs2_data, imm;
    wire [4:0] rd;
    wire [6:0] opcode, funct7;
    wire [2:0] funct3;
    wire [31:0] read_data;
    wire mem_read, mem_write;

    wire [31:0] haddr;
    wire [31:0] hwdata;
    wire hwrite;
    wire [31:0] hrdata;
    wire hready;
    wire hresp;

    wire [31:0] rom_rdata;
    wire [31:0] sram_rdata;

    wire [3:0] jtag_state;
    wire [31:0] debug_reg;

    wire [31:0] dbg_address;
    wire dbg_read_enable;
    wire dbg_write_enable;
    wire [31:0] dbg_write_data;
    wire halt;
    wire step;

    // Instantiate the RISC-V Core
    rv32i_core core (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction),
        .alu_result(alu_result),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm(imm),
        .rd(rd),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .read_data(read_data),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .halt(halt),        // Connect halt signal
        .step(step)         // Connect step signal
    );

    // Instantiate the AHB-Lite Bus Interface
    ahb_lite_interface bus (
        .HCLK(clk),
        .HRESETn(~reset),
        .HSEL(1'b1),
        .HADDR(haddr),
        .HSIZE(3'b010), // 32-bit
        .HTRANS(2'b10), // Non-sequential
        .HWRITE(hwrite),
        .HWDATA(hwdata),
        .HRDATA(hrdata),
        .HREADY(hready),
        .HRESP(hresp)
    );

    // Instantiate the SRAM with configurable size
    parameter MEM_SIZE_SRAM = 32 * 1024; // Example: 32KB memory size
    parameter SRAM_START_ADDR = 32'h0010_0000; // SRAM start address
    sram #(.MEM_SIZE(MEM_SIZE_SRAM)) memory (
        .clk(clk),
        .addr(haddr - SRAM_START_ADDR), // Adjust address for SRAM base
        .wdata(hwdata),
        .write_enable(hwrite),
        .rdata(sram_rdata)
    );

    // Instantiate the ROM with 32KB size
    parameter MEM_SIZE_ROM = 32 * 1024; // 32KB memory size
    rom #(.MEM_SIZE(MEM_SIZE_ROM)) rom_memory (
        .clk(clk),
        .addr(haddr),
        .rdata(rom_rdata)
    );

    // Address decode logic for ROM and SRAM
    always @(*) begin
        if (haddr < MEM_SIZE_ROM) begin
            hrdata = rom_rdata;
        end else if (haddr >= SRAM_START_ADDR && haddr < SRAM_START_ADDR + MEM_SIZE_SRAM) begin
            hrdata = sram_rdata;
        end else begin
            hrdata = 32'h00000000; // Default value (optional, handle invalid addresses)
        end
    end

    // Instantiate the JTAG TAP controller
    jtag_tap jtag (
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(tdo),
        .state(jtag_state)
    );

    // Instantiate the Debug Module
    debug_module debug (
        .clk(clk),
        .reset(reset),
        .jtag_state(jtag_state),
        .tdi(tdi),
        .tdo(tdo),
        .read_data(hrdata),
        .address(dbg_address),
        .read_enable(dbg_read_enable),
        .write_enable(dbg_write_enable),
        .write_data(dbg_write_data),
        .halt(halt),
        .step(step)
    );

    // Connect debug module to memory interface
    assign haddr = dbg_address;
    assign hwrite = dbg_write_enable;
    assign hwdata = dbg_write_data;

endmodule