Improving the FIFO's output by registering it can be beneficial in certain scenarios, such as:

Timing Closure: Adding registers to the output can help meet timing requirements by reducing the critical path.
Metastability: In asynchronous FIFO designs, registering outputs can help manage metastability issues.
Signal Stability: Registered outputs can provide more stable signals, especially when interfacing with other clock domains.
However, if your design does not have tight timing requirements or metastability concerns, you might not need to register the FIFO outputs.

When to Register FIFO Outputs
High-Frequency Designs: If your design operates at high frequencies, registering the outputs can help meet timing constraints.
Asynchronous Interfaces: When crossing clock domains, registering outputs helps ensure data integrity.
Noise and Stability: Registered outputs are generally more stable and less susceptible to glitches.