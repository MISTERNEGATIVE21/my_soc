module RegisterFile(
    input clk,
    input reset,
    input RegWrite,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] WriteData,
    output reg [31:0] ReadData1,
    output reg [31:0] ReadData2
);
    reg [31:0] registers [0:31];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ReadData1 <= 0;
            ReadData2 <= 0;
        end else begin
            if (RegWrite) begin
                registers[rd] <= WriteData;
            end
            ReadData1 <= registers[rs1];
            ReadData2 <= registers[rs2];
        end
    end
endmodule