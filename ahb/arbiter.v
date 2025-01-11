
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