/*
Q:
clog2 fun is use by multi modules , can i define it in a common file?

A:
you can define the clog2 function in a common file and then include this file in all the modules that require it. 
This approach promotes code reuse and ensures that the clog2 function is consistent across different modules.

Here’s how you can do it:
Create a Common File: 
Create a file, for example common.vh, where the clog2 function is defined.

Include the Common File: 
Include this common file in all the modules that need to use the clog2 function.

`include "common.vh"

*/

// common.vh
`ifndef COMMON_VH
`define COMMON_VH

// Function to calculate the ceiling of the log base 2
function integer clog2;
    input integer value;
    integer i;
    begin
        clog2 = 0;
        for (i = value - 1; i > 0; i = i >> 1) begin
            clog2 = clog2 + 1;
        end
    end
endfunction

`endif // COMMON_VH