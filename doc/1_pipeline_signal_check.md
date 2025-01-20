
# list of pipeline signals 

|index|name|if|id|ex|mem|wb|usage|
|-|----|----|----|----|----|----|--|
|1|PC|S|T|T|M|T||
|2|Instruction|S|D|-|-|-||
|3|opcode|-|S/D|-|-|-||
|4|readdate1|-|S|D|-|-|rs1-read-value|
|5|readdate2|-|S|D|-|-|rs2-read-value|
|6|imm|-|S|D|-|-||
|7|rs1|-|S|T|T|D|hazard <br> forward|
|7|rs2|-|S|T|T|D|hazard <br> forward|
|7|rd|-|S|T|T|D|dst reg index|
|8|fun7|-|S|D|-|-||
|9|fun3|-|S|D|-|-||
|11|ALUSrc|-|S|D|-|-|ALU-B select: <br> register **or** imd|
|12|ALUOp|-|S|D|-|-|R/I/B inst decode|
|13|Branch|-|S|D|-|-|PC = PC + imd|
|14|MemRead|-|S|T|D|-|d-mem r-en|
|15|MemWrite|-|S|T|D|-|d-mem w-en|
|16|MemtoReg|-|S|T|T|D| wb date select: <br> mem-rd**or** ALU-result|
|17|RegWrite|-|S|T|T|D|reg-w en|
|9|ALUControl|-|-|S/D|-|-||
|18|-|-|-|-|-|-|-|
|9|-|-|-|-|-|-|-|
|9|-|-|-|-|-|-|-|
|9|-|-|-|-|-|-|-|
|9|-|-|-|-|-|-|-|
|9|-|-|-|-|-|-|-|
|9|-|-|-|-|-|-|-|
|9|-|-|-|-|-|-|-|

# check
## 
2025-01-20-15：47
ALUSrc not uesd.


