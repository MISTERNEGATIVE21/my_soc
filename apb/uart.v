module UART_APB (
    input wire PCLK,
    input wire PRESETn,
    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,
    input wire [31:0] PADDR,
    input wire [31:0] PWDATA,
    output reg [31:0] PRDATA,
    output reg PREADY,
    output reg PSLVERR,

    // UART signals
    output reg tx,
    input wire rx
);

    // UART registers
    reg [7:0] tx_data;
    reg [7:0] rx_data;
    reg tx_ready;
    reg rx_ready;

    // UART state machine states
    localparam [1:0]
        IDLE   = 2'b00,
        WRITE  = 2'b01,
        READ   = 2'b10;

    reg [1:0] state;

    // UART transmission and reception logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state <= IDLE;
            PREADY <= 1'b0;
            PSLVERR <= 1'b0;
            tx <= 1'b1; // UART line is idle high
            tx_ready <= 1'b0;
            rx_ready <= 1'b0;
            PRDATA <= 32'b0;
        end else if (PSEL && PENABLE) begin
            case (state)
                IDLE: begin
                    if (PWRITE) begin
                        state <= WRITE;
                        PREADY <= 1'b0;
                        PSLVERR <= 1'b0;
                    end else begin
                        state <= READ;
                        PREADY <= 1'b0;
                        PSLVERR <= 1'b0;
                    end
                end
                WRITE: begin
                    if (PADDR == 32'h0020_0000) begin
                        tx_data <= PWDATA[7:0];
                        tx_ready <= 1'b1;
                        PREADY <= 1'b1;
                    end else begin
                        PSLVERR <= 1'b1;
                        PREADY <= 1'b1;
                    end
                    state <= IDLE;
                end
                READ: begin
                    if (PADDR == 32'h0020_0004) begin
                        PRDATA <= {24'b0, rx_data};
                        rx_ready <= 1'b0;
                        PREADY <= 1'b1;
                    end else begin
                        PSLVERR <= 1'b1;
                        PREADY <= 1'b1;
                    end
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end else begin
            PREADY <= 1'b0;
        end
    end

    // UART transmission logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            tx <= 1'b1;
            tx_ready <= 1'b0;
        end else if (tx_ready) begin
            // Simplified transmission logic
            tx <= tx_data[0];
            tx_ready <= 1'b0;
        end
    end

    // UART reception logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            rx_data <= 8'b0;
            rx_ready <= 1'b0;
        end else if (!rx_ready) begin
            // Simplified reception logic
            rx_data <= {rx_data[6:0], rx};
            rx_ready <= 1'b1;
        end
    end

endmodule