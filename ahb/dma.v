/*
When designing a module like DMA that acts as both an AHB slave and an AHB master, 
there are several important considerations to ensure proper functionality and avoid conflicts. Here are some key points to take care of:

1. Separate AHB Interfaces
Ensure that the DMA has distinct and separate interfaces for its AHB slave and AHB master roles. 
This means having separate signals and logic for handling incoming requests (slave) and outgoing requests (master).

2. Address Decoding
Ensure proper address decoding for the DMA's control registers. 
As an AHB slave, the DMA needs to decode incoming addresses to determine if they are targeting its control registers.

3. Arbitration and Bus Control
When the DMA needs to act as an AHB master, it must request control of the bus. 
This typically involves an arbiter that grants bus access to one master at a time. Ensure that the arbiter correctly handles requests from both the CPU and the DMA.

4. State Management
Properly manage the state transitions within the DMA to handle both roles. 
For example, manage the transitions between idle, read, write, and complete states within the DMA logic.

5. Synchronization
Ensure proper synchronization between the AHB slave and master interfaces, 
especially if they operate on different clocks or have different timing constraints.

6. Handling Responses
As an AHB master, the DMA must handle responses from the slave devices it communicates with. 
This includes managing ready, response, and error signals.

7. Configuration and Control
Provide an interface for configuring and controlling the DMA operation through its AHB slave interface. 
This typically includes control registers for start, source address, destination address, transfer size, etc.

8. Error Handling
Implement error handling mechanisms to manage and respond to bus errors or invalid operations.

*/




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
    input wire master_HRESP
);

    // Control registers
    reg start;
    reg [ADDR_WIDTH-1:0] src_addr;
    reg [ADDR_WIDTH-1:0] dest_addr;
    reg [31:0] transfer_size;
    reg done;  // Internal register for done signal

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