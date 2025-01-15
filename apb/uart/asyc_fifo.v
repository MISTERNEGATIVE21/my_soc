module AsyncFIFO #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
) (
    input wire wr_clk,
    input wire rd_clk,
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] wr_data,
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire full,
    output wire empty,
    output wire [ADDR_WIDTH:0] fifo_fill_cnt,
    input wire [ADDR_WIDTH:0] flow_ctrl_th,
    output wire flow_ctrl_rts_n,
    input wire [ADDR_WIDTH:0] water_mark_th,
    output wire water_mark_status
);

    // 定义内部存储数组
    reg [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0];

    // 写指针和读指针
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;

    // 二进制转格雷码
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        begin
            bin2gray = (bin >> 1) ^ bin;
        end
    endfunction

    // 格雷码转二进制
    function [ADDR_WIDTH:0] gray2bin;
        input [ADDR_WIDTH:0] gray;
        reg [ADDR_WIDTH:0] bin;
        integer i;
        begin
            bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
            for (i = ADDR_WIDTH-1; i >= 0; i = i - 1) begin
                bin[i] = bin[i+1] ^ gray[i];
            end
            gray2bin = bin;
        end
    endfunction

    // 写操作
    always @(posedge wr_clk) begin
        if (wr_en &&!full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // 读操作
    always @(posedge rd_clk) begin
        if (rd_en &&!empty) begin
            rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
            rd_ptr <= rd_ptr + 1;
        end
    end

    // 生成 full 信号
    wire [ADDR_WIDTH:0] wr_ptr_gray = bin2gray(wr_ptr);
    wire [ADDR_WIDTH:0] rd_ptr_gray_sync;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync_r1, rd_ptr_gray_sync_r2;
    always @(posedge wr_clk) begin
        rd_ptr_gray_sync_r1 <= bin2gray(rd_ptr);
        rd_ptr_gray_sync_r2 <= rd_ptr_gray_sync_r1;
    end
    assign full = (wr_ptr_gray == {~rd_ptr_gray_sync_r2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync_r2[ADDR_WIDTH-2:0]});

    // 生成 empty 信号
    wire [ADDR_WIDTH:0] rd_ptr_gray = bin2gray(rd_ptr);
    wire [ADDR_WIDTH:0] wr_ptr_gray_sync;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync_r1, wr_ptr_gray_sync_r2;
    always @(posedge rd_clk) begin
        wr_ptr_gray_sync_r1 <= bin2gray(wr_ptr);
        wr_ptr_gray_sync_r2 <= wr_ptr_gray_sync_r1;
    end
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync_r2);

    // 计算 fifo_fill_cnt
    assign fifo_fill_cnt = wr_ptr - rd_ptr;

    // 生成 flow_ctrl_rts_n 信号
    assign flow_ctrl_rts_n = (fifo_fill_cnt < flow_ctrl_th);

    // 生成 water_mark_status 信号
    assign water_mark_status = (fifo_fill_cnt >= water_mark_th);

endmodule