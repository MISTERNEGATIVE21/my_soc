`ifndef ADDRMAP_V
`define ADDRMAP_V

// Address Map Definitions

// ROM Module
`define ROM_START_ADDR      32'h0000_0000
`define ROM_SIZE            32'h0000_8000  // 32 KB

// SRAM Module
`define SRAM_START_ADDR     32'h0001_0000
`define SRAM_SIZE           32'h0001_0000  // 64 KB

//-----------------------------apb device -----------------------------------
// AHB-to-APB Bridge
`define BRIDGE_START_ADDR   32'h0002_0000
`define BRIDGE_SIZE         (DMA_START_ADDR - BRIDGE_START_ADDR)  

// UART Module
`define UART_START_ADDR     32'h0002_0000
`define UART_SIZE           32'h0000_1000  // 4 KB

//-----------------------------ahb device -----------------------------------
// DMA Control Registers
`define DMA_START_ADDR      32'h0010_0000
`define DMA_SIZE            32'h0000_1000  // 4 KB



`endif // ADDRMAP_V