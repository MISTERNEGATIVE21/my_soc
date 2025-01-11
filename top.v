
`include "addrmap.v"


module my_soc (
    input clk,
    input reset_n,
    input apb_clk,
    input apb_resetn,
    input dma_start,
    input [31:0] dma_src_addr,
    input [31:0] dma_dest_addr,
    input [31:0] dma_transfer_size,
    output dma_done,
    // UART signals
    output uart_tx,
    input uart_rx,
    // JTAG signals
    input TCK,
    input TMS,
    input TDI,
    output TDO
);

    // AHB signals for CPU
    wire [31:0] HADDR_CPU;
    wire [2:0] HBURST_CPU;
    wire HMASTLOCK_CPU;
    wire [3:0] HPROT_CPU;
    wire [2:0] HSIZE_CPU;
    wire [1:0] HTRANS_CPU;
    wire [31:0] HWDATA_CPU;
    wire HWRITE_CPU;
    wire [31:0] HRDATA_CPU;
    wire HREADY_CPU;
    wire HRESP_CPU;

    // AHB signals for DMA
    wire [31:0] HADDR_DMA;
    wire [2:0] HBURST_DMA;
    wire HMASTLOCK_DMA;
    wire [3:0] HPROT_DMA;
    wire [2:0] HSIZE_DMA;
    wire [1:0] HTRANS_DMA;
    wire [31:0] HWDATA_DMA;
    wire HWRITE_DMA;
    wire [31:0] HRDATA_DMA;
    wire HREADY_DMA;
    wire HRESP_DMA;

    // Shared AHB signals
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

    // Address decoder signals
    wire ahb_rom_sel;
    wire ahb_sram_sel;
    wire apb_bridge_sel;
    wire apb_uart_sel;
    wire ahb_dma_sel;

    // Instantiate address decoder
    ahb_decoder decoder (
        .HADDR(HADDR),
        .ahb_rom_sel(ahb_rom_sel),
        .ahb_sram_sel(ahb_sram_sel),
        .apb_bridge_sel(apb_bridge_sel)
        .apb_uart_sel(apb_uart_sel)
        .ahb_dma_sel(ahb_dma_sel)      
    );

    // Instantiate arbiter
    arbiter arb (
        .HCLK(clk),
        .HRESETn(reset_n),
        .cpu_req(HTRANS_CPU[1]),  // CPU request signal
        .dma_req(HTRANS_DMA[1]),  // DMA request signal
        .cpu_grant(cpu_grant),
        .dma_grant(dma_grant)
    );

    // AHB Master Mux
    assign HADDR = cpu_grant ? HADDR_CPU : HADDR_DMA;
    assign HBURST = cpu_grant ? HBURST_CPU : HBURST_DMA;
    assign HMASTLOCK = cpu_grant ? HMASTLOCK_CPU : HMASTLOCK_DMA;
    assign HPROT = cpu_grant ? HPROT_CPU : HPROT_DMA;
    assign HSIZE = cpu_grant ? HSIZE_CPU : HSIZE_DMA;
    assign HTRANS = cpu_grant ? HTRANS_CPU : HTRANS_DMA;
    assign HWDATA = cpu_grant ? HWDATA_CPU : HWDATA_DMA;
    assign HWRITE = cpu_grant ? HWRITE_CPU : HWRITE_DMA;
    assign HRDATA_CPU = HRDATA;
    assign HRDATA_DMA = HRDATA;
    assign HREADY_CPU = HREADY;
    assign HREADY_DMA = HREADY;
    assign HRESP_CPU = HRESP;
    assign HRESP_DMA = HRESP;

    // Instantiate RV32I core with AHB master interface and I-Cache
    PipelineRV32ICore_AHB #(
        .ICACHE_SIZE(1024),
        .ICACHE_LINE_SIZE(32),
        .ICACHE_WAYS(1),
        .DCACHE_SIZE(1024),
        .DCACHE_LINE_SIZE(32),
        .DCACHE_WAYS(1),
        .DCACHE_WRITE_POLICY("WRITE_BACK")
    ) rv32i_core (
        .clk(clk),
        .reset_n(reset_n),
        .HADDR(HADDR_CPU),
        .HBURST(HBURST_CPU),
        .HMASTLOCK(HMASTLOCK_CPU),
        .HPROT(HPROT_CPU),
        .HSIZE(HSIZE_CPU),
        .HTRANS(HTRANS_CPU),
        .HWDATA(HWDATA_CPU),
        .HWRITE(HWRITE_CPU),
        .HRDATA(HRDATA),
        .HREADY(HREADY),
        .HRESP(HRESP),
        // JTAG Interface
        .TCK(TCK),
        .TMS(TMS),
        .TDI(TDI),
        .TDO(TDO)
    );

    // Instantiate ROM as AHB slave
    AHB_ROM_Slave #(
        .BASE_ADDR(32'ROM_START_ADDR), 
        .SIZE(ROM_SIZE/4)
    ) rom_slave (
        .HCLK(clk),
        .HRESETn(reset_n),
        .HADDR(HADDR),
        .HBURST(HBURST),
        .HMASTLOCK(HMASTLOCK),
        .HPROT(HPROT),
        .HSIZE(HSIZE),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HWDATA(HWDATA),
        .HRDATA(HRDATA_ROM),
        .HREADY(HREADY_ROM),
        .HRESP(HRESP_ROM)
    );

    // Instantiate SRAM as AHB slave
    AHB_SRAM_Slave  #(
        .BASE_ADDR(32'SRAM_START_ADDR), 
        .SIZE(SRAM_SIZE/4)
    ) sram_slave (
        .HCLK(clk),
        .HRESETn(reset_n),
        .HADDR(HADDR),
        .HBURST(HBURST),
        .HMASTLOCK(HMASTLOCK),
        .HPROT(HPROT),
        .HSIZE(HSIZE),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HWDATA(HWDATA),
        .HRDATA(HRDATA_SRAM),
        .HREADY(HREADY_SRAM),
        .HRESP(HRESP_SRAM)
    );

    // Instantiate AHB-to-APB Bridge as AHB slave and APB master
    AHB_to_APB_Bridge ahb_to_apb (
        .ahb_clk(clk),
        .ahb_resetn(reset_n),
        .HADDR(HADDR),
        .HBURST(HBURST),
        .HMASTLOCK(HMASTLOCK),
        .HPROT(HPROT),
        .HSIZE(HSIZE),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HWDATA(HWDATA),
        .HRDATA(HRDATA_APB),
        .HREADY(HREADY_APB),
        .HRESP(HRESP_APB),
        .apb_clk(apb_clk),
        .apb_resetn(apb_resetn),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)
    );

    // Instantiate UART as APB slave
    UART_APB uart (
        .PCLK(apb_clk),
        .PRESETn(apb_resetn),
        .PSEL(apb_uart_sel),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),
        .tx(uart_tx),
        .rx(uart_rx)
    );

    // Instantiate DMA as AHB master
    DMA_AHB_Master #(
        parameter ADDR_WIDTH = 32,
        parameter DATA_WIDTH = 32,
        parameter BASE_ADDR  = 32'h0020_0000
    ) dma (
        .HCLK(clk),
        .HRESETn(reset_n),
        .done(dma_done),
        .HADDR(HADDR_DMA),
        .HBURST(HBURST_DMA),
        .HMASTLOCK(HMASTLOCK_DMA),
        .HPROT(HPROT_DMA),
        .HSIZE(HSIZE_DMA),
        .HTRANS(HTRANS_DMA),
        .HWDATA(HWDATA_DMA),
        .HWRITE(HWRITE_DMA),
        .HRDATA(HRDATA_DMA),
        .HREADY(HREADY_DMA),
        .HRESP(HRESP_DMA)
    );

endmodule