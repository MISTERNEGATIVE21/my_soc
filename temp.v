always @(posedge clk or posedge reset) begin
    if (reset) begin
        ready <= 0;
        hit <= 0;
    end else if (valid) begin
        // Check for cache hit
        hit <= 0;
        for (way = 0; way < WAYS; way = way + 1) begin
            if (valid_array[index][way] && tag_array[index][way] == tag) begin
                hit <= 1;
                hit_way <= way;
                break;
            end
        end

        if (hit) begin
            // Cache hit
            if (r_w) begin
                // Write operation
                data_array[index][hit_way][offset/4] <= wdata;
                if (WRITE_POLICY == "WRITE_THROUGH") begin
                    // Write-through: write to memory immediately
                    write_to_memory(addr, wdata);
                end else if (WRITE_POLICY == "WRITE_BACK") begin
                    // Write-back: mark the line as dirty
                    dirty_array[index][hit_way] <= 1;
                end
            end else begin
                // Read operation
                rdata <= data_array[index][hit_way][offset/4];
            end
            ready <= 1; // Data is ready if hit
        end else begin
            // Cache miss
            ready <= 0; // Data is not ready if miss
            if (r_w) begin
                // Write miss: handle accordingly based on policy
                handle_write_miss(addr, wdata);
            end else begin
                // Read miss: handle read miss
                handle_read_miss(addr);
            end
        end
    end else begin
        ready <= 0;
    end
end

// Task for handling write miss using AHB bus with burst transfers
task handle_write_miss(input [31:0] addr, input [31:0] data);
    integer i;
    begin
        // Check alignment with the cache line size
        if (addr[OFFSET_BITS-1:0] == 0) begin
            // Aligned address, use incrementing burst
            HADDR <= addr;
            HBURST <= 3'b011;       // 4-beat incrementing burst
        end else begin
            // Unaligned address, use wrapping burst
            HADDR <= addr & ~(LINE_SIZE - 1);
            HBURST <= 3'b100;       // 4-beat wrapping burst
        end

        HMASTLOCK <= 1'b0;          // Not using locked transfer
        HPROT <= 4'b0011;           // Data access, non-cacheable, privileged, bufferable
        HSIZE <= 3'b010;            // 32-bit word transfer
        HTRANS <= 2'b10;            // Non-sequential transfer
        HWRITE <= 1'b1;             // Write operation
        
        // Wait for the AHB transfer to complete for each word in the burst
        for (i = 0; i < LINE_SIZE/4; i = i + 1) begin
            HWDATA <= data_array[index][way][i]; // Write the current data to AHB bus
            @(posedge clk);
            while (!HREADY) begin
                @(posedge clk);
            end
        end

        // Update the tag and valid bits
        tag_array[index][way] <= tag;
        valid_array[index][way] <= 1;
        dirty_array[index][way] <= 0;

        // Clear AHB signals after the transfer
        HTRANS <= 2'b00;        // Idle transfer
        HWRITE <= 1'b0;         // Clear write signal
        
        // Indicate the operation is ready
        ready <= 1;
    end
endtask

// Task for handling read miss using AHB bus with burst transfers
task handle_read_miss(input [31:0] addr);
    integer i;
    begin
        // Check alignment with the cache line size
        if (addr[OFFSET_BITS-1:0] == 0) begin
            // Aligned address, use incrementing burst
            HADDR <= addr;
            HBURST <= 3'b011;       // 4-beat incrementing burst
        end else begin
            // Unaligned address, use wrapping burst
            HADDR <= addr & ~(LINE_SIZE - 1);
            HBURST <= 3'b100;       // 4-beat wrapping burst
        end

        HMASTLOCK <= 1'b0;          // Not using locked transfer
        HPROT <= 4'b0011;           // Data access, non-cacheable, privileged, bufferable
        HSIZE <= 3'b010;            // 32-bit word transfer
        HTRANS <= 2'b10;            // Non-sequential transfer
        HWRITE <= 1'b0;             // Read operation
        
        // Wait for the AHB transfer to complete for each word in the burst
        for (i = 0; i < LINE_SIZE/4; i = i + 1) begin
            @(posedge clk);
            while (!HREADY) begin
                @(posedge clk);
            end
            // Store the fetched data in the cache line
            data_array[index][way][i] <= HRDATA;
        end

        // Update the tag and valid bits
        tag_array[index][way] <= tag;
        valid_array[index][way] <= 1;
        dirty_array[index][way] <= 0;

        // If this was a read operation, provide the data
        rdata <= data_array[index][way][offset/4];

        // Clear AHB signals after the transfer
        HTRANS <= 2'b00;        // Idle transfer
        
        // Indicate the operation is ready
        ready <= 1;
    end
endtask