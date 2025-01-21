module BranchPredictionUnit (
    input wire clk,
    input wire reset_n,
    input wire branch_instruction,
    input wire branch_outcome, // 1: taken, 0: not taken
    output reg prediction
);
    reg [1:0] state; // 2-bit saturating counter

    // State encoding
    localparam STRONGLY_NOT_TAKEN = 2'b00;
    localparam WEAKLY_NOT_TAKEN   = 2'b01;
    localparam WEAKLY_TAKEN       = 2'b10;
    localparam STRONGLY_TAKEN     = 2'b11;

    // Initialization
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= WEAKLY_TAKEN; // Initial state
        end else if (branch_instruction) begin
            // Update state based on actual branch outcome
            case (state)
                STRONGLY_NOT_TAKEN: state <= branch_outcome ? WEAKLY_NOT_TAKEN : STRONGLY_NOT_TAKEN;
                WEAKLY_NOT_TAKEN: state <= branch_outcome ? WEAKLY_TAKEN : STRONGLY_NOT_TAKEN;
                WEAKLY_TAKEN: state <= branch_outcome ? STRONGLY_TAKEN : WEAKLY_NOT_TAKEN;
                STRONGLY_TAKEN: state <= branch_outcome ? STRONGLY_TAKEN : WEAKLY_TAKEN;
            endcase
        end
    end

    // Output prediction based on current state
    always @(*) begin
        case (state)
            STRONGLY_NOT_TAKEN, WEAKLY_NOT_TAKEN: prediction = 0;
            WEAKLY_TAKEN, STRONGLY_TAKEN: prediction = 1;
        endcase
    end
endmodule