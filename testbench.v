`timescale 1ns / 1ps

module testbench;

    // Declare inputs as regs and outputs as wires
    reg clk;
    reg reset_n;
    // Declare other necessary signals if required

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period (100MHz clock)
    end

    // Testbench initial block
    initial begin
        // Initialize inputs
        reset_n = 0;

        // Apply reset
        #10;
        reset_n = 1;

        // Add stimulus here
        // e.g., setting inputs, applying test vectors

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