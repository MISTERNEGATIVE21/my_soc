/* Summary of Changes:
 fetch inst from i_memory
*/
module IF_stage (
    //system signals
    input wire clk,               // Clock signal
    input wire reset_n,           // Asynchronous reset (active low)
    
    //golobal stall signal
    input wire combined_stall,    // Combined stall signal
    
    //enable signals from previous stage
    input wire fetch_enable,      // Fetch enable signal for hazard control
    input wire [31:0] next_pc,    // Next program counter value
    
    //output to next stage
    output reg [31:0] IF_ID_PC,   // Program counter to ID stage
    output reg [31:0] IF_ID_Instruction, // Instruction to ID stage
    output reg IF_ID_enable_out   // Enable signal for the next stage
);

    reg [31:0] pc; // Program counter register, internal signal;

    // Instantiate i_memory
    wire [31:0] i_memory_rdata;
    i_memory #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .MEM_DEPTH(1024)
    ) i_memory_inst (
        .clk(clk),
        .reset_n(reset_n),
        .addr(pc),
        .rdata(i_memory_rdata)
    );

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            pc <= 32'b0;
            IF_ID_PC <= 32'b0;
            IF_ID_Instruction <= 32'b0;
            IF_ID_enable_out <= 1'b0;
        end else if (combined_stall) begin
            IF_ID_PC <= 32'b0;
            IF_ID_Instruction <= 32'b0;
            IF_ID_enable_out <= 1'b0;
        end else if (fetch_enable) begin
            pc <= next_pc;
            IF_ID_PC <= pc;
            IF_ID_Instruction <= i_memory_rdata;
            IF_ID_enable_out <= 1'b1;
        end else begin
            IF_ID_enable_out <= 1'b0;
        end
    end

endmodule