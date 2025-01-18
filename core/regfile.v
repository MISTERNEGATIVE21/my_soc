/* 
Explanation:
This module simulates the behavior of a register file, which includes reading and writing registers.

Inputs:
clk: The clock signal.
RegWrite: A control signal indicating whether a write operation should be performed.
rs1: The address of the first source register.
rs2: The address of the second source register.
rd: The address of the destination register.
WriteData: The data to be written to the destination register.

Outputs:
ReadData1: The data read from the first source register.
ReadData2: The data read from the second source register.
Register File Array:

An array of 32 registers, each 32 bits wide, to store the data.
Read Operations:

The read operations are asynchronous, meaning the data is available as soon as the register addresses are provided.
If the source register address (rs1 or rs2) is 0, the output data is always 0 because register x0 is hardwired to 0.
Write Operation:

The write operation is synchronous, meaning it occurs on the rising edge of the clock signal.
The write operation is performed only if RegWrite is high and the destination register address (rd) is not 0 (to avoid writing to register x0).
This implementation ensures that the RegisterFile module correctly handles reading from and writing to the registers based on the control signals and addresses provided. 
*/

module RegisterFile (
    input wire clk,
    input wire RegWrite,
    input wire [4:0] rs1, // Source register 1
    input wire [4:0] rs2, // Source register 2
    input wire [4:0] rd,  // Destination register
    input wire [31:0] WriteData, // Data to be written to the destination register
    output wire [31:0] ReadData1, // Data read from source register 1
    output wire [31:0] ReadData2  // Data read from source register 2
);

    // Register file array of 32 registers, each 32-bit wide
    reg [31:0] regfile [31:0];

    // Read operations (asynchronous)
    assign ReadData1 = (rs1 != 0) ? regfile[rs1] : 32'b0; // Register x0 is always 0
    assign ReadData2 = (rs2 != 0) ? regfile[rs2] : 32'b0; // Register x0 is always 0

    // Write operation (synchronous)
    always @(posedge clk) begin
        if (RegWrite && rd != 0) begin
            regfile[rd] <= WriteData;
        end
    end

endmodule