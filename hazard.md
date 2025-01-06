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
