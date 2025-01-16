module APB_Slave_UART #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,   
    parameter BASE_ADDR = 32'h1000_0000,
    parameter FIFO_DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
) (
    // APB 接口
    input wire PCLK,
    input wire PRESETn,
    input wire [31:0] PADDR,
    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,
    input wire [31:0] PWDATA,
    output reg [31:0] PRDATA,
    // UART 接口
    input wire RX,
    output wire TX,
    // UART 时钟
    input wire uart_clk   // Added uart_clk signal
);

    // 内部寄存器定义
    reg [31:0] control_reg;
    reg [31:0] clk_div_reg; // 新增 clk_div 寄存器
    reg [31:0] tx_fifo_ctrl_reg;
    reg [31:0] rx_fifo_ctrl_reg;        
    reg [31:0] tx_status_reg;
    reg [31:0] rx_status_reg;
    reg [31:0] tx_data_reg; // 发送数据寄存器 just a copy of PWDATA when writing to tx-fifo
    reg [31:0] rx_data_reg; // 接收数据寄存器 just a copy of PRDATA when reading from rx-fifo

    // Synchronized registers : these registers are synchronized to uart_clk domain
    reg [31:0] control_reg_sync;
    reg [31:0] clk_div_reg_sync;
    reg [31:0] tx_fifo_ctrl_reg_sync;
    reg [31:0] rx_fifo_ctrl_reg_sync;
    reg [31:0] tx_status_reg_sync;
    reg [31:0] rx_status_reg_sync;

    // Register offset definitions
    localparam CONTROL_REG_OFFSET      = 32'h00;
    localparam CLK_DIV_REG_OFFSET      = 32'h04;   
    localparam TX_FIFO_CTLR_REG_OFFSET = 32'h20;
    localparam RX_FIFO_CTLR_REG_OFFSET = 32'h24;
    localparam TX_STATUS_REG_OFFSET    = 32'h40;
    localparam RX_STATUS_REG_OFFSET    = 32'h44;
    localparam TX_DATA_REG_OFFSET      = 32'h80;
    localparam RX_DATA_REG_OFFSET      = 32'h84;

    // Control register bit positions
    localparam TX_EN_BIT   = 0;
    localparam RX_EN_BIT   = 1;
    localparam CONTROL_REG_DEFAULT_VALUE      = 0 << TX_EN_BIT + 0 << RX_EN_BIT;

    // Clock division register bit positions
    localparam CLK_DIV_FRAC_BIT   = 0;     
    localparam CLK_DIV_FRAC_WIDTH = 4;        
    localparam CLK_DIV_INT_BIT    = 16;
    localparam CLK_DIV_INT_WIDTH  = 16;
    localparam CLK_DIV_REG_DEFAULT_VALUE      = 5 << CLK_DIV_FRAC_BIT + 208 << CLK_DIV_INT_BIT;
 
    // FIFO control register bit positions
    localparam TX_FIFO_WATERMARK_TH_BIT   = 0;
    localparam TX_FIFO_RESET_BIT   = 31;  
    localparam TX_FIFO_CTLR_REG_DEFAULT_VALUE = 8 << TX_FIFO_WATERMARK_TH_BIT + 1 << TX_FIFO_RESET_BIT;

    localparam RX_FIFO_WATERMARK_TH_BIT = 0;
    localparam RX_FIFO_FLOWCTRL_TH_BIT  = 8;   
    localparam RX_FIFO_RESET_BIT   = 31;  
    localparam RX_FIFO_CTLR_REG_DEFAULT_VALUE = 8 << RX_FIFO_WATERMARK_TH_BIT + (FIFO_DEPTH - 2) << RX_FIFO_FLOWCTRL_TH_BIT  + 1 << RX_FIFO_RESET_BIT;

    // Status register bit positions
    localparam TX_FIFO_FILL_BIT         = 0;
    localparam TX_FIFO_EMPTY_BIT        = 8;
    localparam TX_FIFO_FULL_BIT         = 9;
    localparam TX_FIFO_WATERMARK_BIT    = 10;    
    localparam TX_FIFO_UNDERFLOW_BIT    = 11;
    localparam TX_FIFO_OVERFLOW_BIT    = 12;   
    localparam TX_SHIFT_IDLE_BIT        = 16;

    localparam RX_FIFO_FILL_BIT         = 0;    
    localparam RX_FIFO_EMPTY_BIT        = 8;
    localparam RX_FIFO_FULL_BIT         = 9;
    localparam RX_FIFO_WATERMARK_BIT    = 10;    
    localparam RX_FIFO_UNDERFLOW_BIT    = 11;
    localparam RX_FIFO_OVERFLOW_BIT    = 12;       
    localparam RX_SHIFT_FULL_BIT        = 16;
    localparam RX_SHIFT_ERR_BREAK_BIT   = 20;

    // Register default value definitions

    // Translate from FIFO depth to FIFO address width    
    localparam FIFO_ADDR_WIDTH = $clog2(FIFO_DEPTH);

    // 发送 FIFO 实例化
    AsyncFIFO #(
    .DATA_WIDTH(FIFO_DATA_WIDTH),
    .ADDR_WIDTH(FIFO_ADDR_WIDTH)
    ) tx_fifo (
    .wr_clk(PCLK),          // Write clock is PCLK
    .rd_clk(uart_clk),      // Read clock is uart_clk
    .global_reset_n(PRESETn), // Global reset signal
    .local_reset_n(tx_fifo_resetn), // Local reset signal from UART register
    .wr_en(tx_wr_en),
    .rd_en(tx_rd_en),
    .wr_data(tx_wr_data),
    .rd_data(tx_rd_data),
    .full(tx_full),
    .empty(tx_empty),
    .fifo_fill_cnt(tx_fifo_fill_cnt),
    .fifo_overflow(tx_fifo_overflow),
    .fifo_underflow(tx_fifo_underflow)     
    );

// RX FIFO
    AsyncFIFO #(
    .DATA_WIDTH(FIFO_DATA_WIDTH),
    .ADDR_WIDTH(FIFO_ADDR_WIDTH)
    ) rx_fifo (
    .wr_clk(uart_clk),      // Write clock is uart_clk
    .rd_clk(PCLK),          // Read clock is PCLK
    .global_reset_n(PRESETn), // Global reset signal
    .local_reset_n(rx_fifo_resetn), // Local reset signal from UART register
    .wr_en(rx_wr_en),
    .rd_en(rx_rd_en),
    .wr_data(rx_wr_data),
    .rd_data(rx_rd_data),
    .full(rx_full),
    .empty(rx_empty),
    .fifo_fill_cnt(rx_fifo_fill_cnt),
    .fifo_overflow(rx_fifo_overflow),
    .fifo_underflow(rx_fifo_underflow)
    );

    // 内部信号定义
    wire tx_wr_en;
    wire tx_rd_en;
    wire tx_fifo_resetn;
    wire [FIFO_DATA_WIDTH-1:0] tx_wr_data;
    wire [FIFO_DATA_WIDTH-1:0] tx_rd_data;
    wire tx_full;
    wire tx_empty;
    wire [FIFO_ADDR_WIDTH:0] tx_fifo_fill_cnt;
    wire [FIFO_ADDR_WIDTH:0] tx_flow_ctrl_th;
    wire tx_flow_ctrl_rts_n;
    wire [FIFO_ADDR_WIDTH:0] tx_water_mark_th;
    wire tx_water_mark;
    wire tx_fifo_overflow;
    wire tx_fifo_underflow;

    wire rx_wr_en;
    wire rx_rd_en;
    wire rx_fifo_resetn;
    wire [FIFO_DATA_WIDTH-1:0] rx_wr_data;
    wire [FIFO_DATA_WIDTH-1:0] rx_rd_data;
    wire rx_full;
    wire rx_empty;
    wire [FIFO_ADDR_WIDTH:0] rx_fifo_fill_cnt;
    wire [FIFO_ADDR_WIDTH:0] rx_flow_ctrl_th;
    wire rx_flow_ctrl_rts_n;
    wire [FIFO_ADDR_WIDTH:0] rx_water_mark_th;
    wire rx_water_mark;
    wire rx_fifo_overflow;
    wire rx_fifo_underflow;   

    wire [15:0] int_div;
    wire [3:0] frac_div;
    wire [31:0] div_value;

    reg uart_bit_clk_x16;
    reg uart_bit_clk;

    // 提取 int_div 和 frac_div
    assign frac_div = clk_div_reg_sync[CLK_DIV_FRAC_BIT + CLK_DIV_FRAC_WIDTH - 1 : CLK_DIV_FRAC_BIT];
    assign int_div = clk_div_reg_sync[CLK_DIV_INT_BIT + CLK_DIV_INT_WIDTH - 1 : CLK_DIV_INT_BIT];
    assign div_value = (int_div * 16) + frac_div;

    // 生成 uart_bit_clk_x16 和 uart_bit_clk 时钟信号
    always @(posedge uart_clk or negedge PRESETn) begin
        if (!PRESETn) begin
            uart_bit_clk_x16 <= 1'b0;
            uart_bit_clk <= 1'b0;
        end else begin
            uart_bit_clk_x16 <= (div_value == 0) ? 1'b0 : (uart_clk % div_value == 0);
            uart_bit_clk <= (div_value == 0) ? 1'b0 : (uart_clk % (div_value * 16) == 0);
        end
    end

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

    // 新增信号用于指示 tx_shift 和 rx_shift 的状态
    wire tx_shift_idle; // tx_shift 处于空闲状态
    wire rx_shift_full; // rx_shift 已接收完整一帧数据

    // Instantiate the tx_shift module
    tx_shift tx_inst (
        .reset_n(PRESETn),
        .uart_clk(uart_clk),
        .uart_bit_clk(uart_bit_clk),
        .data_in(tx_rd_data),
        .start(tx_rd_en),
        .tx(tx),
        .busy(tx_busy_internal)
    );

    // Instantiate the rx_shift module
    rx_shift rx_inst (
        .reset_n(PRESETn),
        .uart_clk(uart_clk),
        .uart_bit_clk_x16(uart_bit_clk_x16),
        .rx(rx),
        .data_out(rx_wr_data),
        .full(rx_shift_full),
        .err_break(rx_shift_err_break)
    );   

    // UART fifo access 
    // write to tx-fifo: from APB write operation to tx-fifo
    assign tx_wr_en = PSEL && PENABLE && PWRITE && (PADDR == BASE_ADDR + TX_DATA_REG_OFFSET );
    always @(posedge PCLK) begin
        if (tx_wr_en) begin
           tx_wr_data <= PWDATA[FIFO_DATA_WIDTH-1:0];
           tx_data_reg <= PWDATA;
       end    
   end

    // read from tx-fifo: from tx-fifo to tx-shift
    assign tx_shift_idle = !tx_busy_internal
    assign tx_rd_en = (tx_shift_idle && !tx_empty); //当tx_shift空闲且tx_fifo不空时，从 tx_fifo 读取; 具体读取动作，由tx—shift模块完成

    //write to rx-fifo: from rx-shift to rx-fifo
    assign rx_wr_en = rx_shift_full; // 当 rx_shift 接收完整一帧数据时，写入 rx_fifo; 具体写入动作，由 rx_shift 模块完成

    // read from rx-fifo: from rx-fifo to APB read operation
    assign rx_rd_en = PSEL && PENABLE && PWRITE && (PADDR == BASE_ADDR + RX_DATA_REG_OFFSET ); // APB 访问 rx-data register
    always @(posedge PCLK) begin
        if (rx_rd_en) begin
            PRDATA[FIFO_DATA_WIDTH-1:0] <= rx_rd_data;
            rx_data_reg <= rx_rd_data;
        end
    end

    // APB 写操作
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            control_reg <= CONTROL_REG_DEFAULT_VALUE;
            clk_div_reg <= CLK_DIV_REG_DEFAULT_VALUE; // 复位 clk_div 寄存器
            tx_fifo_ctrl_reg <= TX_FIFO_CTLR_REG_DEFAULT_VALUE;   
            rx_fifo_ctrl_reg <= RX_FIFO_CTLR_REG_DEFAULT_VALUE;      
            tx_data_reg <= 32'b0;        
        end else if (PSEL && PENABLE && PWRITE) begin
            case (PADDR)
                BASE_ADDR + CONTROL_REG_OFFSET: control_reg <= PWDATA; // 控制寄存器
                BASE_ADDR + CLK_DIV_REG_OFFSET: clk_div_reg <= PWDATA; // 发送数据寄存器
                BASE_ADDR + TX_FIFO_CTLR_REG_OFFSET: tx_fifo_ctrl_reg <= PWDATA; // tx-fifo ctrl 寄存器
                BASE_ADDR + RX_FIFO_CTLR_REG_OFFSET: rx_fifo_ctrl_reg <= PWDATA; // rx-fifo ctrl 寄存器    
                // BASE_ADDR + TX_DATA_REG_OFFSET: tx_data_reg <= PWDATA; // data has been written to tx_fifo                             
                // 可以添加更多寄存器的写操作
                default: ;
            endcase
        end
    end

    // APB 读操作
    always @(*) begin
        if (PSEL && PENABLE && !PWRITE) begin
            case (PADDR)
                BASE_ADDR + CONTROL_REG_OFFSET: PRDATA = control_reg; // 控制寄存器
                BASE_ADDR + CLK_DIV_REG_OFFSET: PRDATA = clk_div_reg;
                BASE_ADDR + TX_FIFO_CTLR_REG_OFFSET: PRDATA = tx_fifo_ctrl_reg;
                BASE_ADDR + RX_FIFO_CTLR_REG_OFFSET: PRDATA = rx_fifo_ctrl_reg; 
                BASE_ADDR + TX_STATUS_REG_OFFSET: PRDATA = tx_status_reg; // 发送状态寄存器
                BASE_ADDR + RX_STATUS_REG_OFFSET: PRDATA = rx_status_reg; // 接收状态寄存器
                // BASE_ADDR + RX_DATA_REG_OFFSET: PRDATA = rx_data_reg; // data has loaded from rx_fifo
                default: PRDATA = 32'b0;
            endcase
        end else begin
            PRDATA = 32'b0;
        end
    end

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

endmodule