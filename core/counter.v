module clk_counter (
    input wire clk,       // Clock input
    input wire reset_n,   // Active-low reset
    output reg [63:0] counter // 64-bit counter output
);

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            counter <= 64'b0; // Reset counter to 0 on active-low reset
        end else begin
            counter <= counter + 1; // Increment counter by 1 on every clock cycle
        end
    end

endmodule

module pc_counter (
    input wire clk,       // Clock input
    input wire reset_n,   // Active-low reset
    input wire pc_changed, // Signal indicating PC has changed
    output reg [63:0] counter // 64-bit counter output
);

    always @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            counter <= 64'b0; // Reset counter to 0 on active-low reset
        end else if (pc_changed) begin
            counter <= counter + 1; // Increment counter by 1 when PC changes
        end
    end

endmodule