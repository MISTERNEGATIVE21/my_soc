module JTAG_Interface (
    input wire TCK,
    input wire TMS,
    input wire TDI,
    output wire TDO,
    output reg [31:0] address,
    output reg [31:0] data_out,
    input wire [31:0] data_in,
    output reg rd_wr,
    output reg enable,
    output reg step,
    output reg run
);
    // TAP state machine states
    localparam [3:0]
        TEST_LOGIC_RESET = 4'hF,
        RUN_TEST_IDLE = 4'hC,
        SELECT_DR_SCAN = 4'h7,
        CAPTURE_DR = 4'h6,
        SHIFT_DR = 4'h2,
        EXIT1_DR = 4'h1,
        PAUSE_DR = 4'h3,
        EXIT2_DR = 4'h0,
        UPDATE_DR = 4'h5,
        SELECT_IR_SCAN = 4'h4,
        CAPTURE_IR = 4'hE,
        SHIFT_IR = 4'hA,
        EXIT1_IR = 4'h9,
        PAUSE_IR = 4'hB,
        EXIT2_IR = 4'h8,
        UPDATE_IR = 4'hD;

    reg [3:0] state, next_state;
    reg [4:0] instruction;
    reg [31:0] shift_register;

    // TAP state machine
    always @(posedge TCK or posedge TMS) begin
        if (TMS) begin
            state <= next_state;
        end else begin
            case (state)
                TEST_LOGIC_RESET: state <= RUN_TEST_IDLE;
                RUN_TEST_IDLE: state <= RUN_TEST_IDLE;
                SELECT_DR_SCAN: state <= CAPTURE_DR;
                CAPTURE_DR: state <= SHIFT_DR;
                SHIFT_DR: state <= SHIFT_DR;
                EXIT1_DR: state <= PAUSE_DR;
                PAUSE_DR: state <= EXIT2_DR;
                EXIT2_DR: state <= SHIFT_DR;
                UPDATE_DR: state <= RUN_TEST_IDLE;
                SELECT_IR_SCAN: state <= CAPTURE_IR;
                CAPTURE_IR: state <= SHIFT_IR;
                SHIFT_IR: state <= SHIFT_IR;
                EXIT1_IR: state <= PAUSE_IR;
                PAUSE_IR: state <= EXIT2_IR;
                EXIT2_IR: state <= SHIFT_IR;
                UPDATE_IR: state <= RUN_TEST_IDLE;
                default: state <= TEST_LOGIC_RESET;
            endcase
        end
    end

    // Shift register logic
    always @(posedge TCK) begin
        if (state == SHIFT_DR || state == SHIFT_IR) begin
            shift_register <= {TDI, shift_register[31:1]};
        end
    end

    // Update instruction and data
    always @(negedge TCK) begin
        if (state == UPDATE_IR) begin
            instruction <= shift_register[4:0];
        end
        if (state == UPDATE_DR) begin
            case (instruction)
                5'b00001: address <= shift_register; // Load address
                5'b00010: data_out <= shift_register; // Load data
                5'b00100: rd_wr <= shift_register[0]; // Set read/write
                5'b01000: enable <= shift_register[0]; // Enable memory access
                5'b10000: step <= shift_register[0]; // Step CPU
                5'b10001: run <= shift_register[0]; // Run CPU
                default: ;
            endcase
        end
    end

    // Output data
    assign TDO = shift_register[0];

endmodule