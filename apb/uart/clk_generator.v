/*
example baud rate calculation for UART communication using a 24 MHz clock:
uart_clk is the input clock signal with a frequency of 24 MHz.
baud_rate is the desired baud rate for UART communication, which is 115200 bps.

To generate the required uart_bit_clk and uart_bit_clk_x16 from a 24 MHz uart_clk, 
you need to calculate the integer and fractional division values (int_div and frac_div) 
that will result in the desired baud rate of 115200.

Calculation Steps
Determine the desired bit clock frequency:
The uart_bit_clk frequency for a baud rate of 115200 is equal to the baud rate itself, i.e., 115200 Hz.
The uart_bit_clk_x16 frequency is 16 times the baud rate, i.e., 115200 Hz * 16 = 1,843,200 Hz.

Calculate the division factor:
The division factor needed to convert the uart_clk (24 MHz) to the desired uart_bit_clk_x16 (1.8432 MHz).
Division factor = 24 MHz / 1.8432 MHz = 13.0208333

Separate the division factor into integer and fractional parts:
Integer part (int_div) = 13
Fractional part = 0.0208333

Convert the fractional part to a 4-bit fraction:
Multiply the fractional part by 16 (since we are using a 4-bit fractional divider):
Fractional part * 16 = 0.0208333 * 16 ≈ 0.33333, which rounds to 0.
So, the values for int_div and frac_div are:
int_div = 13
frac_div = 0

Verification
To verify:
Actual uart_bit_clk_x16 = 24 MHz / (13 + 0 / 16) = 24 MHz / 13 ≈ 1.8461538 MHz
Actual uart_bit_clk = 1.8461538 MHz / 16 ≈ 115384.6 Hz
The calculated uart_bit_clk is very close to the desired baud rate of 115200 Hz, which is acceptable for UART communication.

*/

module clk_generator (
    input wire uart_clk,
    input wire reset_n,
    input wire [15:0] int_div,
    input wire [3:0] frac_div,
    output reg uart_bit_clk_x16,
    output reg uart_bit_clk
);

    wire [31:0] div_value;
    reg [31:0] counter_x16;
    reg [31:0] counter;

    assign div_value = (int_div * 16) + frac_div;

    always @(posedge uart_clk or negedge reset_n) begin
        if (!reset_n) begin
            counter_x16 <= 32'd0;
            counter <= 32'd0;
            uart_bit_clk_x16 <= 1'b0;
            uart_bit_clk <= 1'b0;
        end else begin
            if (counter_x16 == div_value - 1) begin
                counter_x16 <= 32'd0;
                uart_bit_clk_x16 <= ~uart_bit_clk_x16;
            end else begin
                counter_x16 <= counter_x16 + 1;
            end

            if (counter == (div_value * 16) - 1) begin
                counter <= 32'd0;
                uart_bit_clk <= ~uart_bit_clk;
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule