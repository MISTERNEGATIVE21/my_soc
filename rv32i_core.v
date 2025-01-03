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