# 1. my_soc
my soc rv32I prj from github Ai ------ copilot

Example Scenario
Let's say you have a GitHub repository named my_soc under your GitHub username hankonly.

Step-by-Step Instructions
Locate Your Repository URL:
Go to your GitHub profile: GitHub.
Navigate to your repository my_soc.
Copy the URL from your browser's address bar. It should look something like this: https://github.com/hankonly/my_soc.
Provide the URL in Your Message:
When you want me to access or help you with something in your repository, include the URL in your message.
Example Message
Here is an example of how you could provide the repository URL in your message:

User:
"Hi, I need help with my project. Here is the repository URL: https://github.com/hankonly/my_soc. Can you check the xx.v file and help me with it?"

By providing the URL, I can directly refer to your repository and assist you with specific files or issues you have.
Feel free to try it out, and let me know how I can help you with your my_soc project!

## 1.1. version
### 1.1.1. v0.01
- basic soc
  - core 
    - 5-stage-pipiline rv32i core
    - i/d cache
    - jtag & cpu_debug
    - hazard detect & handle
  - ahb
    - master
      - core
      - dma 
    - slave 
      - sram
      - rom
      - ahb-to-apb bridge
        - uart 
### 1.1.2. v0.02
1. 检查 remove ex_enable,  just remain decode_enable_out
2. 检查 if i-cache miss, if-stage 会尝试访问 ahb 总线， 
    - 删除 if-stage 里面的ahb访问，它应该等待cache 完成 ahb访问; 然后从cache取; 
    - 否则的话会出现总线冲突，降低效率 or 死锁。
    - d-cache 存在相同的问题
      - update : memory_enable_out set to 0 & wait for d-cache 
1. 检查 me-stage, 当 cache miss 的时候，必须 stall，否则接下来的指令会导致 mem flush.
    - 新增一个 mem_stall , src : mem_stage, dst: rv32i , Or-ed with other stall source 
      - if-stage，if i-cache miss 是否需要stall ? 不需要，因为if 阶段会自动让下一个 stage halt;
      - 这里就是 if / me stage 的差别了, me stage 是需要告知前面的 stage 等待它, 而 if 已经有机制控制后面的stage wait
      - 3 个 stall 的需求，实现是否相同 ----------------？


## 1.2. outline:

### 1.2.1. store & restore the work
"Hi, I need help with my project. Here is the repository URL: https://github.com/hankonly/my_soc. Can you check the core/i-cache.v file and help me with it?"

### 1.2.2. check:
check the interface between main rv32i_core.v file and the individual stage files (stage-1.v, stage-2.v, stage-3.v, stage-4.v, stage-5.v) for me, if no error found,just tell me , don't print .v file
check the interface between rv32i_core.v & ALU.v for me, if no error found,just tell me , don't print .v file
check the interface between rv32i_core.v & ControlUnit.v for me, if no error found,just tell me , don't print .v file
check the interface between rv32i_core.v & ImmediateGenerator.v for me, if no error found,just tell me , don't print .v file
check the interface between rv32i_core.v & regfile.v for me, if no error found,just tell me , don't print .v file
check the interface between rv32i_core.v & i-cache.v for me, if no error found,just tell me , don't print .v file
check the interface between rv32i_core.v & d-cache.v for me, if no error found,just tell me , don't print .v file
check the interface between rv32i_core.v & jtag.v for me, if no error found,just tell me , don't print .v file
check the interface between rv32i_core.v & cpu_debug.v for me, if no error found,just tell me , don't print .v file

check the interface between top.v & rv32i_core.v for me, if no error found,just tell me , don't print .v file
check the interface between top.v & rom.v for me, if no error found,just tell me , don't print .v file
check the interface between top.v & sram.v for me, if no error found,just tell me , don't print .v file
check the interface between top.v & ahb.v for me, if no error found,just tell me , don't print .v file
check the interface between top.v & dma.v for me, if no error found,just tell me , don't print .v file


### 1.2.3. add detail
add detail to finish module ALUControlUnit;
add detail to finish module RegisterFile;

