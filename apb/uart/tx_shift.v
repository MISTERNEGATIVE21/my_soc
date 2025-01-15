/*
Module Overview
The tx_shift module has the following inputs and outputs:

Inputs:
reset_n: Active-low reset signal.
uart_clk: The main system clock.
uart_bit_clk: The UART bit clock, defining the baud rate for transmission.
data_in: The 8-bit data to be transmitted.
start: Signal to initiate the transmission.

Outputs:
tx: The transmitted serial data.
busy: Indicates if the module is currently transmitting data.
Registers and Signals
shift_reg: Holds the data to be transmitted, including start and stop bits.
bit_index: Keeps track of the current bit being transmitted.
tx_state: The state machine that controls the transmission process.
stop_bit_count: Counter to ensure two stop bits are transmitted.

State Machine
The state machine (tx_state) transitions through the following states:

Idle State (3'b000):
Waits for the start_sync2 signal to initiate transmission.
Loads data_in_sync2 into shift_reg.
Sets busy to 1.

Start Bit (3'b001):
Transmits the start bit (0).

Data Bits (3'b010):
Transmits each bit from shift_reg.
Shifts shift_reg right, inserting 1 (stop bit) at the MSB.
Increments bit_index to keep track of the transmitted bits.

Stop Bits (3'b011):
Transmits two stop bits (1) using stop_bit_count.

End of Frame (3'b100):
Resets busy to 0.
Returns to the idle state.

Explanation of Synchronization Stages:
start_sync1: Captures the start signal in the uart_bit_clk domain.
start_sync2: Ensures the start signal is stable and reduces metastability risks.
start_sync3: Provides an additional stage to further stabilize the signal.
Typical Usage:
Two Stages (start_sync1 and start_sync2): 
This is often sufficient for most designs. The first stage captures the signal, and the second stage ensures it is stable.
Three Stages (start_sync1, start_sync2, and start_sync3): 
This provides an extra layer of safety, especially in high-speed designs or when the clocks are significantly out of phase.

*/

module tx_shift (
    input wire reset_n,
    input wire uart_clk,
    input wire uart_bit_clk,
    input wire [7:0] data_in,
    input wire start,
    output reg tx,
    output reg busy
);
    reg [7:0] shift_reg;
    reg [3:0] bit_index;
    reg [2:0] tx_state;
    reg [1:0] stop_bit_count;

    // Intermediate signal for data synchronization
    reg [7:0] data_in_sync1, data_in_sync2;
    reg start_sync1, start_sync2;

    // Synchronize data_in and start into uart_bit_clk domain
    always @(posedge uart_bit_clk or negedge reset_n) begin
        if (!reset_n) begin
            data_in_sync1 <= 8'b0;
            data_in_sync2 <= 8'b0;
            start_sync1 <= 1'b0;
            start_sync2 <= 1'b0;
        end else begin
            data_in_sync1 <= data_in;
            data_in_sync2 <= data_in_sync1;
            start_sync1 <= start;
            start_sync2 <= start_sync1;
        end
    end

    always @(posedge uart_bit_clk or negedge reset_n) begin
        if (!reset_n) begin
            shift_reg <= 8'b11111111; // Idle state
            bit_index <= 4'b0;
            tx_state <= 3'b000;
            tx <= 1'b1; // Idle state
            busy <= 1'b0;
            stop_bit_count <= 2'b0;
        end else begin
            case (tx_state)
                3'b000: begin // Idle state
                    if (start_sync2) begin
                        shift_reg <= data_in_sync2;
                        bit_index <= 4'b0;
                        tx_state <= 3'b001;
                        busy <= 1'b1;
                    end
                end
                3'b001: begin // Start bit
                    tx <= 1'b0;
                    tx_state <= 3'b010;
                end
                3'b010: begin // Data bits
                    tx <= shift_reg[0];
                    shift_reg <= {1'b1, shift_reg[7:1]}; // Shift right with stop bit (1) as MSB
                    bit_index <= bit_index + 1;
                    if (bit_index == 4'b0111) begin
                        tx_state <= 3'b011;
                    end
                end
                3'b011: begin // Stop bits
                    tx <= 1'b1;
                    stop_bit_count <= stop_bit_count + 1;
                    if (stop_bit_count == 2'b10) begin
                    tx_state <= 3'b100;
                    end
                end
                3'b100: begin // End of frame
                    busy <= 1'b0;
                    stop_bit_count <= 2'b0;
                    tx_state <= 3'b000;
                end
                default: tx_state <= 3'b000;
            endcase
        end
    end
endmodule