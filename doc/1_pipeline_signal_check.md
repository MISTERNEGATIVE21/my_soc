
# 1. list of pipeline signals 
<link rel="stylesheet" href="css/table_style.css">
<table id="pipeline-signal-table">

|index|name|if|id|ex|mem|wb|usage|
|-|----|----|----|----|----|----|--|
|1|PC|S|T|T|M|T||
|2|Instruction|S|D|-|-|-||
|2|branch-taken|S|T|D|-|-|indicate branch is taken|
|3|opcode|-|S/D|-|-|-||
|4|readdata1|-|S|D|-|-|rs1-read-value|
|5|readdata2|-|S|D|-|-|rs2-read-value|
|6|imm|-|S|D|-|-||
|10|fun7|-|S|D|-|-||
|11|fun3|-|S|D|-|-||
|12|ALUSrc|-|S|D|-|-|ALU-B select: <br> register **or** imd|
|13|ALUOp|-|S|D|-|-|R/I/B inst decode|
|14|Branch|-|S|D|-|-|PC = PC + imd if condition|
|15|Jump|-|S|D|-|-|PC = PC + imd, no condition|
|16|MemRead|-|S|T|D|-|d-mem r-en|
|17|MemWrite|-|S|T|D|-|d-mem w-en|
|7|rs1|-|S|T|T|D|hazard <br> forward|
|8|rs2|-|S|T|T|D|hazard <br> forward|
|9|rd|-|S|T|T|D|dst reg index|
|18|MemtoReg|-|S|T|T|D| wb date select: <br> mem-rd**or** ALU-result|
|19|RegWrite|-|S|T|T|D|reg-w en|
|20|ALUControl|-|-|S/D|-|-||

# 2. check
## 2.1. ALUSrc
2025-01-20-15：47
ALUSrc not uesd.

## 2.2. Jump
2025-01-20-18:00
jump is miss in contrl unit
- add EX_clear_IF_ID if branch or jume case.

## 2.3. fence/system not set signal
is ok, this two case has not involve alu/mem/reg operation

## flush_pipeline
当 control hazard 触发的时候，需要...




