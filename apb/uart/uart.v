module APB_Slave_UART #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter UART_REG_ADDR_WIDTH = 4,
    parameter BASE_ADDR = 32'h1000_0000
) (
    // APB 接口
    input wire PCLK,
    input wire PRESETn,
    input wire [31:0] PADDR,
    input wire PSEL,
    input wire PENABLE,
    input wire PWRITE,
    input wire [31:0] PWDATA,
    output wire [31:0] PRDATA,
    // UART 接口
    input wire RX,
    output wire TX
);

    // 内部寄存器定义
    reg [31:0] control_reg;
    reg [31:0] tx_status_reg;
    reg [31:0] rx_status_reg;
    reg [31:0] tx_data_reg;
    reg [31:0] rx_data_reg;

    // 发送 FIFO 实例化
    AsyncFIFO #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDR_WIDTH(ADDR_WIDTH)
    ) tx_fifo (
     .wr_clk(PCLK),
     .rd_clk(PCLK),
     .wr_en(tx_wr_en),
     .rd_en(tx_rd_en),
     .wr_data(tx_wr_data),
     .rd_data(tx_rd_data),
     .full(tx_full),
     .empty(tx_empty),
     .fifo_fill_cnt(tx_fifo_fill_cnt)
    );

    // 接收 FIFO 实例化
    AsyncFIFO #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDR_WIDTH(ADDR_WIDTH)
    ) rx_fifo (
     .wr_clk(PCLK),
     .rd_clk(PCLK),
     .wr_en(rx_wr_en),
     .rd_en(rx_rd_en),
     .wr_data(rx_wr_data),
     .rd_data(rx_rd_data),
     .full(rx_full),
     .empty(rx_empty),
     .fifo_fill_cnt(rx_fifo_fill_cnt)
    );

    // 内部信号定义
    wire tx_wr_en;
    wire tx_rd_en;
    wire [DATA_WIDTH-1:0] tx_wr_data;
    wire [DATA_WIDTH-1:0] tx_rd_data;
    wire tx_full;
    wire tx_empty;
    wire [ADDR_WIDTH:0] tx_fifo_fill_cnt;
    wire [ADDR_WIDTH:0] tx_flow_ctrl_th;
    wire tx_flow_ctrl_rts_n;
    wire [ADDR_WIDTH:0] tx_water_mark_th;
    wire tx_water_mark_status;

    wire rx_wr_en;
    wire rx_rd_en;
    wire [DATA_WIDTH-1:0] rx_wr_data;
    wire [DATA_WIDTH-1:0] rx_rd_data;
    wire rx_full;
    wire rx_empty;
    wire [ADDR_WIDTH:0] rx_fifo_fill_cnt;
    wire [ADDR_WIDTH:0] rx_flow_ctrl_th;
    wire rx_flow_ctrl_rts_n;
    wire [ADDR_WIDTH:0] rx_water_mark_th;
    wire rx_water_mark_status;

    // Flow control logic
    assign flow_ctrl_rts_n = (fifo_fill_cnt < flow_ctrl_th);

    // Watermark status logic
    assign water_mark_status = (fifo_fill_cnt >= water_mark_th);

    // APB 写操作
    assign tx_wr_en = PSEL && PENABLE && PWRITE && ((PADDR & ~(32'hF)) == BASE_ADDR) && (PADDR[3:0] == 4'h4);
    assign rx_wr_en = 1'b0; // 接收 FIFO 的写操作将由 UART 的 RX 逻辑控制
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            control_reg <= 32'b0;
            tx_data_reg <= 32'b0;
        end else if (PSEL && PENABLE && PWRITE) begin
            case (PADDR[3:0])
                4'h0: control_reg <= PWDATA; // 控制寄存器
                4'h4: tx_data_reg <= PWDATA; // 发送数据寄存器
                // 可以添加更多寄存器的写操作
                default: ;
            endcase
                    end
                end

    // APB 读操作
    always @(*) begin
        if (PSEL && PENABLE &&!PWRITE) begin
            case (PADDR[3:0])
                4'h0: PRDATA = control_reg; // 控制寄存器
                4'h4: PRDATA = rx_data_reg; // 接收数据寄存器
                default: PRDATA = 32'b0;
            endcase
        end else begin
            PRDATA = 32'b0;
        end
    end

    // UART 发送逻辑
    assign tx_wr_data = tx_data_reg[DATA_WIDTH-1:0];
    assign tx_rd_en = (/* 发送逻辑触发条件 */);
    always @(posedge PCLK) begin
        if (tx_wr_en &&!tx_full) begin
            // 将数据从发送数据寄存器写入发送 FIFO
        end
        if (tx_rd_en &&!tx_empty) begin
            // 从发送 FIFO 读取数据进行发送
        end
    end

    // UART 接收逻辑
    assign rx_wr_data = (/* 从 RX 引脚接收的数据 */);
    assign rx_rd_en = (/* 接收逻辑触发条件 */);
    always @(posedge PCLK) begin
        if (rx_wr_en &&!rx_full) begin
            // 将从 RX 引脚接收的数据写入接收 FIFO
        end
        if (rx_rd_en &&!rx_empty) begin
            // 从接收 FIFO 读取数据到接收数据寄存器
            rx_data_reg[DATA_WIDTH-1:0] <= rx_rd_data;
        end
    end

    // UART 状态更新
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            tx_status_reg <= 32'b0;
            rx_status_reg <= 32'b0;
            end else begin
            tx_status_reg[0] <= tx_empty; // 发送缓冲区空状态
            tx_status_reg[1] <= tx_full;  // 发送缓冲区满状态
            rx_status_reg[0] <= rx_empty; // 接收缓冲区空状态
            rx_status_reg[1] <= rx_full;  // 接收缓冲区满状态
            // 可以添加更多状态信息更新
        end
    end

    // UART 传输逻辑
    // 这里需要根据控制寄存器配置实现 UART 的发送和接收逻辑
    // 例如，使用状态机来实现 UART 的传输协议
    // 发送逻辑可以检查 FIFO 是否有数据并发送
    // 接收逻辑可以从 RX 引脚接收数据并存入 FIFO

endmodule