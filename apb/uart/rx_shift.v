/*

Summary of Changes:
Always-sensitive List: Changed the always block to be sensitive to the rising edge of uart_bit_clk_x16 instead of uart_clk.
Clock Domain: The logic now runs on the uart_bit_clk_x16 clock domain, ensuring that sampling happens at 16x the baud rate for accurate detection.

Explanation:
Start Bit Detection: The RX line is sampled on the rising edge of uart_bit_clk_x16 to detect the start bit.
Data Bits Sampling: Each data bit is sampled at the middle of its bit period using uart_bit_clk_x16.
Stop Bits Detection: The stop bits are checked using uart_bit_clk_x16 to ensure correct UART frame reception.

synchronizing data_out into the uart_clk domain is a good idea if uart_clk is used elsewhere in your system and you need 
to ensure the data is stable and coherent when accessed from that domain. 
This is especially important when dealing with different clock domains to avoid metastability issues.

To handle both 1-bit and 2-bit stop conditions as valid in the rx_shift module, we need to modify the state machine to accommodate both scenarios. 
This means that after receiving the data bits, the module will check for at least one stop bit and then validate whether there is an optional second stop bit if present.

*/

module rx_shift (
    input wire reset_n,
    input wire uart_clk,
    input wire uart_bit_clk_x16,
    input wire rx,
    output reg [7:0] data_out,
    output reg full,
    output reg err_break
);
    reg [7:0] shift_reg;
    reg [3:0] bit_index;
    reg [3:0] sample_count;
    reg [2:0] sample_state;
    reg [1:0] stop_bit_count;

    // Intermediate signal for data synchronization
    reg [7:0] data_out_sync;
    reg data_out_sync_valid;

    always @(posedge uart_bit_clk_x16 or negedge reset_n) begin
        if (!reset_n) begin
            shift_reg <= 8'b0;
            bit_index <= 4'b0;
            sample_count <= 4'b0;
            sample_state <= 3'b000;
            data_out_sync <= 8'b0;
            data_out_sync_valid <= 1'b0;
            err_break <= 1'b0;
            stop_bit_count <= 2'b0;
        end else begin
            case (sample_state)
                3'b000: begin // Looking for start bit
                    if (rx == 1'b0) begin
                        sample_count <= sample_count + 1;
                            if (sample_count == 4'b0111) begin // Middle of the bit period
                            sample_state <= 3'b001;
                            sample_count <= 4'b0;
                        end
                    end else begin
                        sample_count <= 4'b0;
                end
                end
                3'b001: begin // Receiving data bits
                        sample_count <= sample_count + 1;
                        if (sample_count == 4'b1111) begin
                            sample_count <= 4'b0;
                            shift_reg[bit_index] <= rx;
                            bit_index <= bit_index + 1;
                            if (bit_index == 4'b0111) begin
                                sample_state <= 3'b010;
                                bit_index <= 4'b0;
                        end
                    end
                end
                3'b010: begin // Checking stop bits
                        sample_count <= sample_count + 1;
                        if (sample_count == 4'b1111) begin
                            sample_count <= 4'b0;
                            stop_bit_count <= stop_bit_count + 1;
                        if (stop_bit_count == 2'b00) begin
                            if (rx == 1'b1) begin
                                data_out_sync <= shift_reg;
                                data_out_sync_valid <= 1'b1;
                                    err_break <= 1'b0;
                                sample_state <= 3'b000;
                            end else begin
                                err_break <= 1'b1;
                                sample_state <= 3'b000;
                            end
                        end else if (stop_bit_count == 2'b01) begin
                            if (rx == 1'b1) begin
                                data_out_sync <= shift_reg;
                                data_out_sync_valid <= 1'b1;
                                err_break <= 1'b0;
                            sample_state <= 3'b000;
                            end else begin
                                err_break <= 1'b1;
                                sample_state <= 3'b000;
                            end
                        end
                    end
                end
                default: sample_state <= 3'b000;
            endcase
        end
    end

    // Synchronize data_out into uart_clk domain
    always @(posedge uart_clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out <= 8'b0;
            full <= 1'b0;
        end else begin
            if (data_out_sync_valid) begin
                data_out <= data_out_sync;
                full <= 1'b1;
                data_out_sync_valid <= 1'b0;
            end else begin
                full <= 1'b0;
            end
        end
    end
endmodule