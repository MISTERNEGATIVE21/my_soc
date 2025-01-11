
/* 
Explanation:
Clock Domains: The AHB interface operates on ahb_clk, while the APB interface operates on apb_clk.
State Machine: The state machine controls the AHB-to-APB bridge logic, ensuring proper operation across clock domains.
Signal Synchronization: Signals from the AHB domain are synchronized to the APB domain using HADDR_sync, HWDATA_sync, and HWRITE_sync.
APB Interface Logic: The APB interface logic handles the transfer of data between AHB and APB domains, ensuring proper setup and access phases. 

*/
module AHB_to_APB_Bridge (
    // AHB Slave Interface
    input wire ahb_clk,
    input wire ahb_resetn,
    input wire [31:0] HADDR,
    input wire [2:0] HBURST,
    input wire HMASTLOCK,
    input wire [3:0] HPROT,
    input wire [2:0] HSIZE,
    input wire [1:0] HTRANS,
    input wire HWRITE,
    input wire [31:0] HWDATA,
    output reg [31:0] HRDATA,
    output reg HREADY,
    output reg HRESP,

    // APB Master Interface
    input wire apb_clk,
    input wire apb_resetn,
    output reg [31:0] PADDR,
    output reg PWRITE,
    output reg PSEL,
    output reg PENABLE,
    output reg [31:0] PWDATA,
    input wire [31:0] PRDATA,
    input wire PREADY,
    input wire PSLVERR
);

    // State machine states
    localparam [1:0]
        IDLE    = 2'b00,
        SETUP   = 2'b01,
        ACCESS  = 2'b10;

    reg [1:0] state, next_state;

    // Synchronize signals between clock domains
    reg [31:0] HADDR_sync, HWDATA_sync;
    reg HWRITE_sync, valid_sync;

    // State machine
    always @(posedge ahb_clk or negedge ahb_resetn) begin
        if (!ahb_resetn) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (HTRANS[1] && (HADDR >= 32'h0020_0000 && HADDR < 32'h0100_0000)) begin
                    next_state = SETUP;
                end else begin
                    next_state = IDLE;
                end
            end
            SETUP: begin
                next_state = ACCESS;
            end
            ACCESS: begin
                if (PREADY) begin
                    next_state = IDLE;
                end else begin
                    next_state = ACCESS;
                end
            end
            default: next_state = IDLE;
        endcase
    end

    // Output logic
    always @(posedge ahb_clk or negedge ahb_resetn) begin
        if (!ahb_resetn) begin
            HREADY <= 1'b1;
            HRESP <= 1'b0;
            valid_sync <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (HTRANS[1] && (HADDR >= 32'h0020_0000 && HADDR < 32'h0100_0000)) begin
                        HADDR_sync <= HADDR;
                        HWDATA_sync <= HWDATA;
                        HWRITE_sync <= HWRITE;
                        valid_sync <= 1'b1;
                        HREADY <= 1'b0;
                    end else begin
                        valid_sync <= 1'b0;
                        HREADY <= 1'b1;
                    end
                end
                SETUP: begin
                    // No operation in SETUP state
                end
                ACCESS: begin
                    if (PREADY) begin
                        HRDATA <= PRDATA;
                        HRESP <= PSLVERR;
                        HREADY <= 1'b1;
                        valid_sync <= 1'b0;
                    end else begin
                        HREADY <= 1'b0;
                    end
                end
            endcase
        end
    end

    // APB interface logic
    always @(posedge apb_clk or negedge apb_resetn) begin
        if (!apb_resetn) begin
            PSEL <= 1'b0;
            PENABLE <= 1'b0;
        end else begin
            if (valid_sync) begin
                PADDR <= HADDR_sync;
                PWRITE <= HWRITE_sync;
                PWDATA <= HWDATA_sync;
                PSEL <= 1'b1;
                PENABLE <= 1'b1;
            end else if (PREADY) begin
                PSEL <= 1'b0;
                PENABLE <= 1'b0;
            end
        end
    end

endmodule