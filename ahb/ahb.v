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



