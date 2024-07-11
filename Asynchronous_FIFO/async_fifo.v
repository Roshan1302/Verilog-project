`timescale 1ns / 1ps

module async_fifo #(parameter fd = 8, fw = 8, add_size = 3)
(
    input w_clk,
    input r_clk,
    input rst,
    input wr,
    input rd,
    input [fw-1:0] wdata,
    output reg [fw-1:0] rdata,
    output full,
    output empty,
    output reg overflow,
    output reg underflow
);
    reg [add_size:0] wptr, rptr;
    wire [add_size:0] c_wptr, c_rptr; // Gray coded output
    reg [add_size:0] c_wptr_q1, c_wptr_q2, c_rptr_q1, c_rptr_q2;
    reg [fw-1:0] mem[fd-1:0];

    // Writing data into FIFO
    always @(posedge w_clk) 
    begin
        if (rst) 
            wptr <= 0;
        else 
        begin
            if (wr && !full) 
            begin
                mem[wptr[add_size-1:0]] <= wdata; // Only use the lower bits for indexing
                wptr <= (wptr + 1);
            end
        end
    end

    // Read operation
    always @(posedge r_clk) 
    begin
        if (rst)
            rptr <= 0; 
        else 
        begin
            if (rd && !empty) 
            begin
                rdata <= mem[rptr[add_size-1:0]]; // Only use the lower bits for indexing
                rptr <= (rptr + 1);
            end
        end
    end

    // Write and read binary to gray
    assign c_wptr = wptr ^ (wptr >> 1);
    assign c_rptr = rptr ^ (rptr >> 1);

    // Two stage sync for write pointer
    always @(posedge r_clk) begin
        if (rst) begin
            c_wptr_q1 <= 0;
            c_wptr_q2 <= 0;
        end else begin
            c_wptr_q1 <= c_wptr;
            c_wptr_q2 <= c_wptr_q1;
        end
    end

    // Two stage sync for read pointer
    always @(posedge w_clk) begin
        if (rst) begin
            c_rptr_q1 <= 0;
            c_rptr_q2 <= 0;
        end else begin
            c_rptr_q1 <= c_rptr;
            c_rptr_q2 <= c_rptr_q1;
        end
    end

    // Empty and full condition
    assign empty = (rptr == wptr);
//    assign full = (~{wptr[add_size], wptr[add_size-1], wptr[add_size-2], wptr[add_size-3]} == rptr);
assign full = (wptr == {1'b1, {add_size{1'b0}}}) && (rptr == 0);

    // Overflow and underflow conditions
    always @(posedge w_clk) begin
        if (rst) begin
            overflow <= 0;
        end else begin
            overflow <= (full && wr);
        end
    end

    always @(posedge r_clk) begin
        if (rst) begin
            underflow <= 0;
        end else begin
            underflow <= (empty && rd);
        end
    end

endmodule
