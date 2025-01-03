module ahb_lite_interface (
    input wire HCLK,        // AHB-Lite clock
    input wire HRESETn,     // AHB-Lite reset (active low)
    input wire HSEL,        // Slave select signal
    input wire [31:0] HADDR, // Address bus
    input wire [2:0] HSIZE, // Transfer size (byte, halfword, word)
    input wire [1:0] HTRANS, // Transfer type (NONSEQ, SEQ, IDLE)
    input wire HWRITE,      // Write enable
    input wire [31:0] HWDATA, // Write data bus
    output wire [31:0] HRDATA, // Read data bus
    output wire HREADY,     // Transfer done
    output wire HRESP       // Transfer response (0: OKAY, 1: ERROR)
);

    // Internal registers
    reg [31:0] reg_HRDATA;
    reg reg_HREADY;
    reg reg_HRESP;

    // Assign internal registers to outputs
    assign HRDATA = reg_HRDATA;
    assign HREADY = reg_HREADY;
    assign HRESP = reg_HRESP;

    // AHB-Lite slave state machine
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            reg_HRDATA <= 32'b0;
            reg_HREADY <= 1'b1;
            reg_HRESP <= 1'b0;
        end else if (HSEL && HTRANS[1]) begin
            // Transfer is valid
            if (HWRITE) begin
                // Write operation
                case (HSIZE)
                    3'b000: ; // Byte
                    3'b001: ; // Halfword
                    3'b010: ; // Word
                    default: ;
                endcase
                reg_HREADY <= 1'b1;
                reg_HRESP <= 1'b0; // OKAY response
            end else begin
                // Read operation
                case (HSIZE)
                    3'b000: reg_HRDATA <= 32'hXXXXXXXX; // Byte
                    3'b001: reg_HRDATA <= 32'hXXXXXXXX; // Halfword
                    3'b010: reg_HRDATA <= 32'hXXXXXXXX; // Word
                    default: reg_HRDATA <= 32'hXXXXXXXX;
                endcase
                reg_HREADY <= 1'b1;
                reg_HRESP <= 1'b0; // OKAY response
            end
        end else begin
            // No valid transfer
            reg_HREADY <= 1'b1;
            reg_HRESP <= 1'b0; // OKAY response
        end
    end

endmodule