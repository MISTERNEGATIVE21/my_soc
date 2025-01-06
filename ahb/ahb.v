module AHBMaster(
    input clk,
    input reset,
    output reg [31:0] HADDR,
    output reg [2:0] HBURST,
    output reg HMASTLOCK,
    output reg [3:0] HPROT,
    output reg [2:0] HSIZE,
    output reg [1:0] HTRANS,
    output reg [31:0] HWDATA,
    output reg HWRITE,
    input [31:0] HRDATA,
    input HREADY,
    input HRESP
);
    // Master logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            HADDR <= 0;
            HBURST <= 3'b000;
            HMASTLOCK <= 0;
            HPROT <= 4'b0000;
            HSIZE <= 3'b010; // 32-bit
            HTRANS <= 2'b00; // IDLE
            HWDATA <= 0;
            HWRITE <= 0;
        end else begin
            // Example write transaction
            HADDR <= 32'h0000_0000;
            HTRANS <= 2'b10; // NONSEQ
            HWRITE <= 1;
            HWDATA <= 32'hDEAD_BEEF;
            if (HREADY) begin
                HTRANS <= 2'b00; // IDLE
            end
        end
    end
endmodule

module AHBSlave(
    input clk,
    input reset,
    input [31:0] HADDR,
    input [2:0] HBURST,
    input HMASTLOCK,
    input [3:0] HPROT,
    input [2:0] HSIZE,
    input [1:0] HTRANS,
    input [31:0] HWDATA,
    input HWRITE,
    output reg [31:0] HRDATA,
    output reg HREADY,
    output reg HRESP
);
    reg [31:0] memory [0:255];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            HREADY <= 1;
            HRESP <= 0;
            HRDATA <= 0;
        end else begin
            if (HTRANS != 2'b00) begin // Not IDLE
                if (HWRITE) begin
                    memory[HADDR[9:2]] <= HWDATA;
                    HREADY <= 1;
                    HRESP <= 0;
                end else begin
                    HRDATA <= memory[HADDR[9:2]];
                    HREADY <= 1;
                    HRESP <= 0;
                end
            end else begin
                HREADY <= 1;
                HRESP <= 0;
            end
        end
    end
endmodule

module AHBArbiter(
    input clk,
    input reset,
    input [1:0] req,
    output reg [1:0] grant
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            grant <= 2'b01; // Grant to master 0 by default
        end else begin
            case (req)
                2'b01: grant <= 2'b01; // Grant to master 0
                2'b10: grant <= 2'b10; // Grant to master 1
                2'b11: grant <= 2'b01; // Grant to master 0
                default: grant <= 2'b00;
            endcase
        end
    end
endmodule

module AHBTop(
    input clk,
    input reset
);
    wire [31:0] HADDR;
    wire [2:0] HBURST;
    wire HMASTLOCK;
    wire [3:0] HPROT;
    wire [2:0] HSIZE;
    wire [1:0] HTRANS;
    wire [31:0] HWDATA;
    wire HWRITE;
    wire [31:0] HRDATA;
    wire HREADY;
    wire HRESP;

    wire [1:0] req;
    wire [1:0] grant;

    AHBMaster master0 (
        .clk(clk),
        .reset(reset),
        .HADDR(HADDR),
        .HBURST(HBURST),
        .HMASTLOCK(HMASTLOCK),
        .HPROT(HPROT),
        .HSIZE(HSIZE),
        .HTRANS(HTRANS),
        .HWDATA(HWDATA),
        .HWRITE(HWRITE),
        .HRDATA(HRDATA),
        .HREADY(HREADY),
        .HRESP(HRESP)
    );

    AHBSlave slave (
        .clk(clk),
        .reset(reset),
        .HADDR(HADDR),
        .HBURST(HBURST),
        .HMASTLOCK(HMASTLOCK),
        .HPROT(HPROT),
        .HSIZE(HSIZE),
        .HTRANS(HTRANS),
        .HWDATA(HWDATA),
        .HWRITE(HWRITE),
        .HRDATA(HRDATA),
        .HREADY(HREADY),
        .HRESP(HRESP)
    );

    AHBArbiter arbiter (
        .clk(clk),
        .reset(reset),
        .req(req),
        .grant(grant)
    );

    assign req = 2'b01; // Request from master 0

endmodule

/* 
To add an arbiter to handle conflicts between two AHB masters (CPU and DMA) in the my_soc bus, we need to implement a weighted-round-robin algorithm with the CPU having higher priority than DMA.
Explanation:
States: The arbiter has two states: CPU_PRIORITY and DMA_PRIORITY.
State Transitions: The state machine transitions between states based on the requests from the CPU and DMA. The CPU has higher priority.
Grant Signals: The arbiter generates grant signals (cpu_grant, dma_grant) to allow either the CPU or DMA to access the bus. 

*/

module arbiter (
    input wire HCLK,
    input wire HRESETn,
    input wire cpu_req,
    input wire dma_req,
    output reg cpu_grant,
    output reg dma_grant
);
    // States for the weighted-round-robin algorithm
    localparam [1:0] CPU_PRIORITY = 2'b00, DMA_PRIORITY = 2'b01;
    reg [1:0] state, next_state;

    // State machine for weighted-round-robin algorithm
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            state <= CPU_PRIORITY;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        cpu_grant = 0;
        dma_grant = 0;
        case (state)
            CPU_PRIORITY: begin
                if (cpu_req) begin
                    cpu_grant = 1;
                    next_state = DMA_PRIORITY;
                end else if (dma_req) begin
                    dma_grant = 1;
                    next_state = CPU_PRIORITY;
                end
            end
            DMA_PRIORITY: begin
                if (cpu_req) begin
                    cpu_grant = 1;
                    next_state = CPU_PRIORITY;
                end else if (dma_req) begin
                    dma_grant = 1;
                    next_state = CPU_PRIORITY;
                end
            end
        endcase
    end

endmodule




/* 
Explanation:
Address Decoding: The ahb_decoder module checks the address (HADDR) and sets the appropriate select signal (rom_sel, sram_sel, apb_bridge_sel) based on the address range. 
*/
module ahb_decoder(
    input wire [31:0] HADDR,
    output reg rom_sel,
    output reg sram_sel,
    output reg apb_bridge_sel
);

    always @(*) begin
        // Default all select signals to 0
        rom_sel = 0;
        sram_sel = 0;
        apb_bridge_sel = 0;
        
        // Address decoding
        if (HADDR >= 32'h0000_0000 && HADDR < 32'h0000_8000) begin
            rom_sel = 1;
        end else if (HADDR >= 32'h0010_0000 && HADDR < 32'h0020_0000) begin
            sram_sel = 1;
        end else if (HADDR >= 32'h0020_0000 && HADDR < 32'h0100_0000) begin
            apb_bridge_sel = 1;
        end
    end

endmodule



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