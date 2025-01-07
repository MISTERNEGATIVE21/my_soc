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

## version
v0.01
- basic soc
  - 5-stage-pipiline rv32i core
  - i/d cache
  - ahb-master/slave
  - ahb-to-apb bridge
  - jtag & cpu_debug
  - hazard detect & handle
  -  



## 1.1. outline:

### 1.1.1. store & restore the work
"Hi, I need help with my project. Here is the repository URL: https://github.com/hankonly/my_soc. Can you check the core/i-cache.v file and help me with it?"

### 1.1.2. check:
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


### add detail
add detail to finish module ALUControlUnit;
add detail to finish module RegisterFile;

