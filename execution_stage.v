module execution_stage (
    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input [31:0] ex_mem_data,
    input [31:0] mem_wb_data,
    input [1:0] forward_a,
    input [1:0] forward_b,
    output reg [31:0] alu_input_a,
    output reg [31:0] alu_input_b
);

    always @(*) begin
        // Select ALU input A
        case (forward_a)
            2'b00: alu_input_a = rs1_data; // No forwarding
            2'b01: alu_input_a = mem_wb_data; // Forward from MEM/WB stage
            2'b10: alu_input_a = ex_mem_data; // Forward from EX/MEM stage
            default: alu_input_a = rs1_data;
        endcase

        // Select ALU input B
        case (forward_b)
            2'b00: alu_input_b = rs2_data; // No forwarding
            2'b01: alu_input_b = mem_wb_data; // Forward from MEM/WB stage
            2'b10: alu_input_b = ex_mem_data; // Forward from EX/MEM stage
            default: alu_input_b = rs2_data;
        endcase
    end
endmodule