module debug_module (
    input wire clk,
    input wire reset,
    input wire [3:0] jtag_state,
    input wire tdi,
    output reg tdo,
    input wire [31:0] read_data, // Data read from memory or register
    output reg [31:0] address,   // Address to read or write
    output reg read_enable,      // Enable read operation
    output reg write_enable,     // Enable write operation
    output reg [31:0] write_data,// Data to write
    output reg halt,             // Halt signal for the core
    output reg step              // Single-step signal for the core
);

    reg [31:0] shift_reg;        // Shift register for data transfer
    reg [3:0] instruction;       // Instruction register
    reg [31:0] instruction_address;

    // Define JTAG instructions
    localparam READ_MEM = 4'b0001;
    localparam WRITE_MEM = 4'b0010;
    localparam SET_ADDR = 4'b0011;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            address <= 32'b0;
            read_enable <= 1'b0;
            write_enable <= 1'b0;
            write_data <= 32'b0;
            tdo <= 1'b0;
            halt <= 1'b0;
            step <= 1'b0;
            shift_reg <= 32'b0;
            instruction <= 4'b0;
            instruction_address <= 32'b0;
        end else begin
            case (jtag_state)
                4'b0100: begin // CAPTURE_DR state
                    tdo <= read_data[0];
                end
                4'b0010: begin // SHIFT_DR state
                    shift_reg <= {tdi, shift_reg[31:1]};
                    tdo <= shift_reg[0];
                end
                4'b0101: begin // UPDATE_DR state
                    case (instruction)
                        READ_MEM: begin
                            read_enable <= 1'b1;
                        end
                        WRITE_MEM: begin
                            write_enable <= 1'b1;
                            write_data <= shift_reg;
                        end
                        SET_ADDR: begin
                            address <= shift_reg;
                        end
                        default: begin
                            read_enable <= 1'b0;
                            write_enable <= 1'b0;
                        end
                    endcase
                end
                default: begin
                    read_enable <= 1'b0;
                    write_enable <= 1'b0;
                end
            endcase
            
            // Check if the current instruction address matches the breakpoint address
            if (instruction_address == address) begin
                halt <= 1'b1; // Halt the core
            end

            if (step) begin
                halt <= 1'b0; // Release halt for single-step
                step <= 1'b0; // Clear step after single-step
            end
        end
    end

    // Additional logic to handle setting breakpoints and single-stepping via JTAG
    always @(posedge clk) begin
        if (jtag_state == SHIFT_IR) begin
            // Shift in the instruction register (IR)
            instruction <= {tdi, instruction[3:1]};
        end
    end
endmodule