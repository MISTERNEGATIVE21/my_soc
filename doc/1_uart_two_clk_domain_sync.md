When the status register is updated by uart_clk and read by PCLK (APB clock), it can lead to synchronization issues because the two clocks are asynchronous. 
This means the status register updates might not be correctly captured by the APB interface, leading to potential metastability or incorrect readings.

To handle this, you can use synchronization techniques to safely transfer the status information between the two clock domains. 
One common approach is to use a double flip-flop synchronizer for each bit of the status register being transferred.

add sync 寄存器：

## 1. sync-1
apb-clk -> uart-clk
```v
    // 提取 FIFO  reset
    assign tx_fifo_resetn = tx_fifo_ctrl_reg_sync[TX_FIFO_RESET_BIT];
    assign rx_fifo_resetn = rx_fifo_ctrl_reg_sync[RX_FIFO_RESET_BIT]; 

    // 提取 FIFO 阈值
    assign tx_water_mark_th = tx_fifo_ctrl_reg_sync[TX_FIFO_WATERMARK_TH_BIT + FIFO_ADDR_WIDTH - 1 : TX_FIFO_WATERMARK_TH_BIT];
    assign rx_water_mark_th = rx_fifo_ctrl_reg_sync[RX_FIFO_WATERMARK_TH_BIT + FIFO_ADDR_WIDTH - 1 : RX_FIFO_WATERMARK_TH_BIT]; 
    assign rx_flow_ctrl_th = rx_fifo_ctrl_reg_sync[RX_FIFO_FLOWCTRL_TH_BIT + FIFO_ADDR_WIDTH - 1 : RX_FIFO_FLOWCTRL_TH_BIT];

    // Flow control logic
    assign tx_flow_ctrl_rts_n = (tx_fifo_fill_cnt < tx_flow_ctrl_th);
    assign rx_flow_ctrl_rts_n = (rx_fifo_fill_cnt < rx_flow_ctrl_th);

    // Watermark status logic
    assign tx_water_mark = (tx_fifo_fill_cnt >= tx_water_mark_th);
    assign rx_water_mark = (rx_fifo_fill_cnt >= rx_water_mark_th);

    // Synchronize control registers: Pclk to uart_clk domain
    always @(posedge uart_clk or negedge PRESETn) begin
        if (!PRESETn) begin
            control_reg_sync <= CONTROL_REG_DEFAULT_VALUE;
            clk_div_reg_sync <= CLK_DIV_REG_DEFAULT_VALUE;
            tx_fifo_ctrl_reg_sync <= TX_FIFO_CTLR_REG_DEFAULT_VALUE;
            rx_fifo_ctrl_reg_sync <= RX_FIFO_CTLR_DEFAULT_VALUE;
        end else begin
            control_reg_sync <= control_reg;
            clk_div_reg_sync <= clk_div_reg;
            tx_fifo_ctrl_reg_sync <= tx_fifo_ctrl_reg;
            rx_fifo_ctrl_reg_sync <= rx_fifo_ctrl_reg;
        end
    end
```

## 2. parameter get
```v
    // 提取 FIFO  reset
    assign tx_fifo_resetn = tx_fifo_ctrl_reg_sync[TX_FIFO_RESET_BIT];
    assign rx_fifo_resetn = rx_fifo_ctrl_reg_sync[RX_FIFO_RESET_BIT]; 

    // 提取 FIFO 阈值
    assign tx_water_mark_th = tx_fifo_ctrl_reg_sync[TX_FIFO_WATERMARK_TH_BIT + FIFO_ADDR_WIDTH - 1 : TX_FIFO_WATERMARK_TH_BIT];
    assign rx_water_mark_th = rx_fifo_ctrl_reg_sync[RX_FIFO_WATERMARK_TH_BIT + FIFO_ADDR_WIDTH - 1 : RX_FIFO_WATERMARK_TH_BIT]; 
    assign rx_flow_ctrl_th = rx_fifo_ctrl_reg_sync[RX_FIFO_FLOWCTRL_TH_BIT + FIFO_ADDR_WIDTH - 1 : RX_FIFO_FLOWCTRL_TH_BIT];

    // Flow control logic
    assign tx_flow_ctrl_rts_n = (tx_fifo_fill_cnt < tx_flow_ctrl_th);
    assign rx_flow_ctrl_rts_n = (rx_fifo_fill_cnt < rx_flow_ctrl_th);

    // Watermark status logic
    assign tx_water_mark = (tx_fifo_fill_cnt >= tx_water_mark_th);
    assign rx_water_mark = (rx_fifo_fill_cnt >= rx_water_mark_th);

```

## 3. update
```v
    // UART status-update : in uart_clk domain
    always @(posedge uart_clk or negedge PRESETn) begin
        if (!PRESETn) begin
                rx_status_reg_sync <= 32'b0;
                rx_status_reg_sync <= 32'b0;
            end else begin
                tx_status_reg_sync[TX_FIFO_FILL_BIT + FIFO_ADDR_WIDTH - 1 : TX_FIFO_FILL_BIT] <= tx_fifo_fill_cnt;
                tx_status_reg_sync[TX_FIFO_EMPTY_BIT] <= tx_empty;
                tx_status_reg_sync[TX_FIFO_FULL_BIT] <= tx_full;  
                tx_status_reg_sync[TX_FIFO_WATERMARK_BIT] <= tx_water_mark; 
                tx_status_reg_sync[TX_FIFO_UNDERFLOW_BIT] <= tx_fifo_underflow; 
                tx_status_reg_sync[TX_FIFO_OVERFLOW_BIT] <= tx_fifo_overflow;            
                tx_status_reg_sync[TX_SHIFT_IDLE_BIT] <= tx_shift_idle; 

                rx_status_reg_sync[RX_FIFO_FILL_BIT + FIFO_ADDR_WIDTH - 1 : RX_FIFO_FILL_BIT] <= rx_fifo_fill_cnt;
                rx_status_reg_sync[RX_FIFO_EMPTY_BIT] <= rx_empty; 
                rx_status_reg_sync[RX_FIFO_FULL_BIT] <= rx_full; 
                rx_status_reg_sync[RX_FIFO_WATERMARK_BIT] <= rx_water_mark; 
                rx_status_reg_sync[RX_FIFO_UNDERFLOW_BIT] <= rx_fifo_underflow; 
                rx_status_reg_sync[RX_FIFO_OVERFLOW_BIT] <= rx_fifo_overflow;   
                rx_status_reg_sync[RX_SHIFT_FULL_BIT] <= rx_shift_full;
                rx_status_reg_sync[RX_SHIFT_ERR_BREAK_BIT] <= rx_shift_err_break;           
        end
    end
```

## 4. sync-2
uart-clk to pclk

```v
    // Synchronize status registers : uart-clk to PCLK domain
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            tx_status_reg <= 32'b0;
            rx_status_reg <= 32'b0;
        end else begin
            tx_status_reg <= tx_status_reg_sync;
            rx_status_reg <= rx_status_reg_sync;
        end
    end
```



