
/* 
Explanation:
Address Decoding: The ahb_decoder module checks the address (HADDR) and sets the appropriate select signal (ahb_rom_sel, ahb_sram_sel, apb_bridge_sel) based on the address range. 
*/

module ahb_decoder(
    input wire [31:0] HADDR,
    output reg ahb_rom_sel,
    output reg ahb_sram_sel,
    output reg apb_bridge_sel,
    output reg apb_uart_sel, 
    output reg ahb_dma_sel  // DMA select signal
);

    always @(*) begin
        // Default all select signals to 0
        ahb_rom_sel = 0;
        ahb_sram_sel = 0;
        apb_bridge_sel = 0;
        apb_uart_sel = 0;
        ahb_dma_sel = 0;  // Initialize DMA select signal to 0

        // Address decoding
        if (HADDR >= `ROM_START_ADDR && HADDR < (`ROM_START_ADDR + `ROM_SIZE)) begin
            ahb_rom_sel = 1;
        end else if (HADDR >= `SRAM_START_ADDR && HADDR < (`SRAM_START_ADDR + `SRAM_SIZE)) begin
            ahb_sram_sel = 1;
        end else if (HADDR >= `DMA_START_ADDR && HADDR < (`DMA_START_ADDR + `DMA_SIZE)) begin
            ahb_dma_sel = 1;
        end else if (HADDR >= `BRIDGE_START_ADDR && HADDR < (`BRIDGE_START_ADDR + `BRIDGE_SIZE)) begin
            apb_bridge_sel = 1;
            if (HADDR >= `UART_START_ADDR && HADDR < (`UART_START_ADDR + `UART_SIZE)) begin
                apb_uart_sel = 1;
            end 
        end
    end

endmodule