
module CPU_Debug (
    input wire clk,
    input wire reset_n,     // Active-low reset
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
    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
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