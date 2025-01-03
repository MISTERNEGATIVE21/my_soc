module forwarding_unit (
    input [4:0] rs1, // Source register 1
    input [4:0] rs2, // Source register 2
    input [4:0] ex_mem_rd, // Destination register in EX/MEM stage
    input [4:0] mem_wb_rd, // Destination register in MEM/WB stage
    input ex_mem_reg_write, // Register write signal in EX/MEM stage
    input mem_wb_reg_write, // Register write signal in MEM/WB stage
    output reg [1:0] forward_a, // Forwarding control for rs1
    output reg [1:0] forward_b // Forwarding control for rs2
);

    always @(*) begin
        // Default forwarding values
        forward_a = 2'b00;
        forward_b = 2'b00;

        // Forwarding for rs1
        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == rs1)) begin
            forward_a = 2'b10; // Forward from EX/MEM stage
        end else if (mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == rs1)) begin
            forward_a = 2'b01; // Forward from MEM/WB stage
        end

        // Forwarding for rs2
        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == rs2)) begin
            forward_b = 2'b10; // Forward from EX/MEM stage
        end else if (mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == rs2)) begin
            forward_b = 2'b01; // Forward from MEM/WB stage
        end
    end
endmodule