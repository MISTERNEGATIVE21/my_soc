generate log
- generate a uart of apb slave
- add a uart_clk to it
- add a urrt_bit_clk to it , which freq is 1/16 of uart_clk
- add a 8bit*8 fifo which work in uart_clk & uart_bit_clk domain for both tx and rx data path.
- since i may change the fifo depth, so add a parameter for it.
- add a write-only tx_data to tx_path of apb_clk domain, every thin when write this register it will send data to tx-fifo;
- add a tx_fifo_status and rx_fifo_status register in apb_clk domain for cpu to CRS.
- add a fifo fill level register into tx_fifo_status or rx_fifo_status to indicate the current fifo fill condition