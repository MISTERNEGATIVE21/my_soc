`timescale 1ns / 1ps

module testbench;

    // Declare inputs as regs and outputs as wires
    reg clk;
    reg reset_n;
    reg apb_clk;
    reg apb_resetn;
    wire uart_tx;
    reg uart_rx;
    reg uart_clk;
    reg TCK;
    reg TMS;
    reg TDI;
    wire TDO;

    // Instantiate my_soc
    my_soc uut (
        .clk(clk),
        .reset_n(reset_n),
        
        .apb_clk(apb_clk),
        .apb_resetn(apb_resetn),

        // .TCK(TCK),
        // .TMS(TMS),
        // .TDI(TDI),
        // .TDO(TDO)

        .uart_clk(uart_clk),   
        .uart_tx(uart_tx),
        .uart_rx(uart_rx),
   
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period (100MHz clock)
    end

    // APB Clock generation
    initial begin
        apb_clk = 0;
        forever #10 apb_clk = ~apb_clk; // 20ns period (50MHz clock)
    end

    // uart Clock generation
    initial begin
        uart_clk = 0;
        forever #20 uart_clk = ~uart_clk; // 40ns period (24MHz clock)
    end

    // Testbench initial block
    initial begin
        // Initialize inputs
        reset_n = 0;
        apb_resetn = 0;
        uart_rx = 1;
        TCK = 0;
        TMS = 0;
        TDI = 0;

        // Apply reset
        #10;
        reset_n = 1;
        apb_resetn = 1;

        // Add more stimulus here if needed

        // Run the simulation for a specific time
        #1000;

        // Finish simulation
        $finish;
    end

    // Monitor outputs or internal signals for debugging
    initial begin
        $monitor("At time %t, clk = %b, reset_n = %b", $time, clk, reset_n);
        // You can add more signals to monitor as needed
    end

endmodule