
# Entity: ALUControlUnit 
- **File**: ALU.v

## Diagram
![Diagram](ALUControlUnit.svg "Diagram")
## Ports

| Port name  | Direction | Type  | Description |
| ---------- | --------- | ----- | ----------- |
| ALUOp      | input     | [1:0] |             |
| Funct7     | input     | [6:0] |             |
| Funct3     | input     | [2:0] |             |
| ALUControl | output    | [3:0] |             |

## Processes
- unnamed: ( @(*) )
  - **Type:** always
