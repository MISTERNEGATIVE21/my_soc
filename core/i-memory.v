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
