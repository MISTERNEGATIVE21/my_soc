


module DMA_AHB_Master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BASE_ADDR  = 32'h0020_0000
)(
    input wire HCLK,
    input wire HRESETn,
    // AHB Interface for control registers
    input wire [ADDR_WIDTH-1:0] HADDR,
    input wire [1:0] HTRANS,
    input wire HWRITE,
    input wire [DATA_WIDTH-1:0] HWDATA,
    output reg [DATA_WIDTH-1:0] HRDATA,
    // AHB Master Interface for DMA transfer
    output reg [ADDR_WIDTH-1:0] master_HADDR,
    output reg [2:0] master_HBURST,
    output reg master_HMASTLOCK,
    output reg [3:0] master_HPROT,
    output reg [2:0] master_HSIZE,
    output reg [1:0] master_HTRANS,
    output reg [DATA_WIDTH-1:0] master_HWDATA,
    output reg master_HWRITE,
    input wire [DATA_WIDTH-1:0] master_HRDATA,
    input wire master_HREADY,
    input wire master_HRESP,
    output reg done
);

    // Control registers
    reg start;
    reg [ADDR_WIDTH-1:0] src_addr;
    reg [ADDR_WIDTH-1:0] dest_addr;
    reg [31:0] transfer_size;

    // Register addresses (offsets from BASE_ADDR)
    localparam START_ADDR        = BASE_ADDR;
    localparam SRC_ADDR_ADDR     = BASE_ADDR + 4;
    localparam DEST_ADDR_ADDR    = BASE_ADDR + 8;
    localparam TRANSFER_SIZE_ADDR = BASE_ADDR + 12;

    // FSM states
    localparam [1:0]
        IDLE  = 2'b00,
        READ  = 2'b01,
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
                if (master_HREADY) begin
                    next_state = WRITE;
                end
            end
            WRITE: begin
                if (master_HREADY) begin
                    if (count >= transfer_size) begin
                        next_state = IDLE;
                    end else begin
                        next_state = READ;
                    end
                end
            end
            default: next_state = IDLE; // Default state
        endcase
    end

    // Output logic
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            master_HADDR <= 0;
            master_HBURST <= 3'b000; // Single transfer
            master_HMASTLOCK <= 0;
            master_HPROT <= 4'b0000;
            master_HSIZE <= 3'b010; // 4 bytes
            master_HTRANS <= 2'b00; // Idle
            master_HWDATA <= 0;
            master_HWRITE <= 0;
            count <= 0;
            done <= 0;
            start <= 0;
            src_addr <= 0;
            dest_addr <= 0;
            transfer_size <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        master_HADDR <= src_addr;
                        master_HTRANS <= 2'b10; // Non-sequential
                        master_HWRITE <= 0; // Read
                        count <= 0;
                        done <= 0;
                    end
                end
                READ: begin
                    if (master_HREADY) begin
                        master_HADDR <= dest_addr;
                        master_HWDATA <= master_HRDATA;
                        master_HTRANS <= 2'b10; // Non-sequential
                        master_HWRITE <= 1; // Write
                    end
                end
                WRITE: begin
                    if (master_HREADY) begin
                        count <= count + (DATA_WIDTH / 8); // Increment by data width in bytes
                        if (count < transfer_size) begin
                            master_HADDR <= src_addr + count;
                            master_HTRANS <= 2'b10; // Non-sequential
                            master_HWRITE <= 0; // Read
                        end else begin
                            master_HTRANS <= 2'b00; // Idle
                            done <= 1;
                            start <= 0; // Clear start signal
                        end
                    end
                end
                default: begin
                    master_HTRANS <= 2'b00; // Idle
                    done <= 0;
                end
            endcase

            // Handle AHB writes to control registers
            if (HTRANS[1] && HWRITE) begin
                case (HADDR)
                    START_ADDR:        start <= HWDATA[0];
                    SRC_ADDR_ADDR:     src_addr <= HWDATA;
                    DEST_ADDR_ADDR:    dest_addr <= HWDATA;
                    TRANSFER_SIZE_ADDR: transfer_size <= HWDATA;
                endcase
            end

            // Handle AHB reads from control registers
            if (HTRANS[1] && !HWRITE) begin
                case (HADDR)
                    START_ADDR:        HRDATA <= {31'b0, start};
                    SRC_ADDR_ADDR:     HRDATA <= src_addr;
                    DEST_ADDR_ADDR:    HRDATA <= dest_addr;
                    TRANSFER_SIZE_ADDR: HRDATA <= transfer_size;
                    default:           HRDATA <= 32'b0;
                endcase
            end
        end
    end

endmodule