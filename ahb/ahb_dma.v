module DMA_AHB_Master (
    input wire HCLK,
    input wire HRESETn,
    // Control signals
    input wire start,
    input wire [31:0] src_addr,
    input wire [31:0] dest_addr,
    input wire [31:0] transfer_size,
    output reg done,
    // AHB Interface
    output reg [31:0] HADDR,
    output reg [2:0] HBURST,
    output reg HMASTLOCK,
    output reg [3:0] HPROT,
    output reg [2:0] HSIZE,
    output reg [1:0] HTRANS,
    output reg [31:0] HWDATA,
    output reg HWRITE,
    input wire [31:0] HRDATA,
    input wire HREADY,
    input wire HRESP
);

    // FSM states
    localparam [1:0]
        IDLE = 2'b00,
        READ = 2'b01,
        WRITE = 2'b10;

    reg [1:0] state, next_state;
    reg [31:0] count;

    // State machine
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = READ;
                end
            end
            READ: begin
                if (HREADY) begin
                    next_state = WRITE;
                end
            end
            WRITE: begin
                if (HREADY) begin
                    if (count >= transfer_size) begin
                        next_state = IDLE;
                    end else begin
                        next_state = READ;
                    end
                end
            end
        endcase
    end

    // Output logic
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HADDR <= 0;
            HBURST <= 3'b000; // Single transfer
            HMASTLOCK <= 0;
            HPROT <= 4'b0000;
            HSIZE <= 3'b010; // 4 bytes
            HTRANS <= 2'b00; // Idle
            HWDATA <= 0;
            HWRITE <= 0;
            count <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        HADDR <= src_addr;
                        HTRANS <= 2'b10; // Non-sequential
                        HWRITE <= 0; // Read
                        count <= 0;
                        done <= 0;
                    end
                end
                READ: begin
                    if (HREADY) begin
                        HADDR <= dest_addr;
                        HWDATA <= HRDATA;
                        HTRANS <= 2'b10; // Non-sequential
                        HWRITE <= 1; // Write
                    end
                end
                WRITE: begin
                    if (HREADY) begin
                        count <= count + 4;
                        if (count < transfer_size) begin
                            HADDR <= src_addr + count;
                            HTRANS <= 2'b10; // Non-sequential
                            HWRITE <= 0; // Read
                        end else begin
                            HTRANS <= 2'b00; // Idle
                            done <= 1;
                        end
                    end
                end
            endcase
        end
    end

endmodule