# data hazards
Data hazards occur in pipelined processors when instructions that are close together in the instruction stream (program order) depend on each other and their execution overlaps in the pipeline. There are three types of data hazards:

Read After Write (RAW): Also known as a true dependency, occurs when an instruction needs to read a register that a previous instruction is writing to.
Write After Read (WAR): Occurs when an instruction needs to write to a register that a previous instruction is reading from.
Write After Write (WAW): Occurs when two instructions are writing to the same register, and the order of writes must be preserved.
Example of a RAW Hazard
Consider the following sequence of instructions:

Assembly
1. ADD R1, R2, R3   # R1 = R2 + R3
2. SUB R4, R1, R5   # R4 = R1 - R5
The SUB instruction needs the result of the ADD instruction. If the ADD instruction has not completed its write-back stage before the SUB instruction reads R1, a RAW hazard occurs.

Handling Data Hazards
To handle data hazards, several techniques can be used:

Stalling: Pausing the pipeline until the hazard is resolved.
Forwarding (Bypassing): Passing the result directly from one pipeline stage to another without going through the register file.
Reordering Instructions: Changing the order of instructions to avoid the hazard.

# control hazards

Handling control hazards in a pipelined RISC-V core involves managing the uncertainties that arise from branch instructions. 
These hazards can be resolved using various techniques such as stalling, branch prediction, and delayed branching. Here are the common methods to handle control hazards:

1. Stalling (Bubble Insertion):
Introduce NOPs (No Operation) into the pipeline until the branch decision is resolved.
This is a simple but not very efficient method.
2. Branch Prediction:
Predict the outcome of a branch (taken or not taken) and continue executing instructions based on the prediction.
If the prediction is incorrect, flush the incorrect instructions and fetch the correct ones.
There are different branch prediction strategies, such as static prediction (always predict taken or not taken) and dynamic prediction (using hardware like branch history tables).
3. Delayed Branching:
Execute a fixed number of instructions following a branch instruction regardless of whether the branch is taken or not.
This requires careful scheduling of instructions by the compiler.
4. Branch Target Buffer (BTB):
A hardware mechanism that stores the target addresses of recently executed branch instructions.
Helps in quickly determining the next instruction to fetch if a branch is predicted taken.
Implementing Control Hazard Handling
