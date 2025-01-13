module UART_APB #(
    parameter FIFO_DEPTH = 8,
    parameter BASE_ADDR = 32'h00000000
)(
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
    input wire rx,

    // UART clock
    input wire uart_clk
);

    // UART registers
    reg [7:0] tx_data;
    reg [7:0] rx_data;
    reg rx_ready;

    // UART state machine states
    localparam [1:0]
        IDLE   = 2'b00,
        WRITE  = 2'b01,
        READ   = 2'b10;

    reg [1:0] state;

    // UART bit clock generation (1/16 of uart_clk)
    reg [3:0] bit_clk_divider;
    reg uart_bit_clk;

    always @(posedge uart_clk or negedge PRESETn) begin
        if (!PRESETn) begin
            bit_clk_divider <= 4'b0;
            uart_bit_clk <= 1'b0;
        end else begin
            if (bit_clk_divider == 4'd15) begin
                bit_clk_divider <= 4'b0;
                uart_bit_clk <= ~uart_bit_clk;
            end else begin
                bit_clk_divider <= bit_clk_divider + 1;
            end
        end
    end

    // FIFO for TX and RX data paths
    reg [7:0] tx_fifo [FIFO_DEPTH-1:0];
    reg [7:0] rx_fifo [FIFO_DEPTH-1:0];
    reg [$clog2(FIFO_DEPTH)-1:0] tx_fifo_wr_ptr;
    reg [$clog2(FIFO_DEPTH)-1:0] tx_fifo_rd_ptr;
    reg [$clog2(FIFO_DEPTH)-1:0] rx_fifo_wr_ptr;
    reg [$clog2(FIFO_DEPTH)-1:0] rx_fifo_rd_ptr;
    reg rx_fifo_full;
    reg rx_fifo_empty;

    // FIFO status registers
    reg [31:0] tx_fifo_status;
    reg [31:0] rx_fifo_status;

    // FIFO write logic for TX path
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            tx_fifo_wr_ptr <= 0;
            tx_fifo_status <= 32'b0;
        end else if (PSEL && PENABLE && PWRITE && (PADDR == BASE_ADDR) && !tx_fifo_status[31]) begin
            tx_fifo[tx_fifo_wr_ptr] <= PWDATA[7:0];
            tx_fifo_wr_ptr <= tx_fifo_wr_ptr + 1;
            tx_fifo_status <= {1'b0, tx_fifo_status[30:0] + 1};
            if (tx_fifo_wr_ptr == FIFO_DEPTH-1) begin
                tx_fifo_status[31] <= 1'b1; // Set full flag
            end
            PREADY <= 1'b1;
        end else begin
            PREADY <= 1'b0;
        end
    end

    // FIFO read logic for TX path
    always @(posedge uart_bit_clk or negedge PRESETn) begin
        if (!PRESETn) begin
            tx_fifo_rd_ptr <= 0;
            tx_fifo_status[30] <= 1'b1; // Set empty flag
        end else if (!tx_fifo_status[30]) begin
            tx <= tx_fifo[tx_fifo_rd_ptr];
            tx_fifo_rd_ptr <= tx_fifo_rd_ptr + 1;
            tx_fifo_status <= {tx_fifo_status[31], tx_fifo_status[30:0] - 1};
            if (tx_fifo_rd_ptr == tx_fifo_wr_ptr) begin
                tx_fifo_status[30] <= 1'b1; // Set empty flag
            end
        end
    end

    // RX FIFO write logic
    always @(posedge uart_bit_clk or negedge PRESETn) begin
        if (!PRESETn) begin
            rx_fifo_wr_ptr <= 0;
            rx_fifo_full <= 1'b0;
        end else if (rx_ready && !rx_fifo_full) begin
            rx_fifo[rx_fifo_wr_ptr] <= rx_data;
            rx_fifo_wr_ptr <= rx_fifo_wr_ptr + 1;
            if (rx_fifo_wr_ptr == FIFO_DEPTH-1) begin
                rx_fifo_full <= 1'b1;
            end
        end
    end

    // RX FIFO read logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            rx_fifo_rd_ptr <= 0;
            rx_fifo_empty <= 1'b1;
            rx_fifo_status <= 32'b0;
        end else if (PSEL && PENABLE && !PWRITE && (PADDR == BASE_ADDR + 4) && !rx_fifo_empty) begin
            PRDATA <= {24'b0, rx_fifo[rx_fifo_rd_ptr]};
            rx_fifo_rd_ptr <= rx_fifo_rd_ptr + 1;
            rx_fifo_status <= {30'b0, rx_fifo_empty, rx_fifo_rd_ptr};
            if (rx_fifo_rd_ptr == rx_fifo_wr_ptr) begin
                rx_fifo_empty <= 1'b1;
            end
            PREADY <= 1'b1;
        end else begin
            PREADY <= 1'b0;
        end
    end

    // UART transmission and reception logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state <= IDLE;
            PREADY <= 1'b0;
            PSLVERR <= 1'b0;
            tx <= 1'b1; // UART line is idle high
            rx_ready <= 1'b0;
            PRDATA <= 32'b0;
        end else if (PSEL && PENABLE) begin
            case (state)
                IDLE: begin
                    if (PWRITE) begin
                        state <= WRITE;
                        PREADY <= 1'b0;
                    end else begin
                        state <= READ;
                        PREADY <= 1'b0;
                    end
                end
                WRITE: begin
                    if (PADDR == BASE_ADDR) begin
                        tx_data <= PWDATA[7:0];
                        tx_fifo_status[29] <= 1'b1; // Set tx_ready flag
                        PREADY <= 1'b1;
                        state <= IDLE;
                    end else begin
                        PSLVERR <= 1'b1;
                        PREADY <= 1'b1;
                        state <= IDLE;
                    end
                end
                READ: begin
                    if (PADDR == BASE_ADDR + 4) begin
                        PRDATA <= {24'b0, rx_data};
                        PREADY <= 1'b1;
                        state <= IDLE;
                    end else begin
                        PSLVERR <= 1'b1;
                        PREADY <= 1'b1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    // UART receive logic
    always @(posedge uart_bit_clk or negedge PRESETn) begin
        if (!PRESETn) begin
            rx_data <= 8'b0;
            rx_ready <= 1'b0;
        end else if (rx_ready) begin
            rx_data <= rx; // Assuming rx is a serial input, this should be more complex in a real design
            rx_ready <= 1'b0;
        end
    end

    // UART transmit logic
    always @(posedge uart_bit_clk or negedge PRESETn) begin
        if (!PRESETn) begin
            tx <= 1'b1; // UART line is idle high
            tx_fifo_status[29] <= 1'b0; // Clear tx_ready flag
        end else if (tx_fifo_status[29]) begin
            tx <= tx_data; // Assuming tx is a serial output, this should be more complex in a real design
            tx_fifo_status[29] <= 1'b0; // Clear tx_ready flag
        end
    end

endmodule