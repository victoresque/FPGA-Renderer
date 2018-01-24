
module SRAMController(
    input           i_clk,
    input           i_rst,
    // Interface
    input           i_read,
    input           i_write,
    input   [31:0]  i_addr,
    inout   [15:0]  io_data,
    output          o_done,
    // SRAM
    output          SRAM_WE_N,
    output  [19:0]  SRAM_ADDR,
    inout   [15:0]  SRAM_DQ
);

    reg r_we_n;
    assign SRAM_WE_N = r_we_n;
    reg [31:0] r_addr;
    assign SRAM_ADDR = r_addr[19:0];

    reg [15:0] r_io_data;
    reg [15:0] r_SRAM_DQ;

    reg oe_data;
    // read from sram : write to sram
    assign SRAM_DQ = r_we_n?16'hzzzz:r_SRAM_DQ;
    assign io_data = oe_data?r_io_data:16'hzzzz;

    reg r_done;
    assign o_done = r_done;

    enum {
        S_WAIT, // WE=H
        S_READ, // WE=H
        S_WRITE // WE=L
    } STATES;
    reg [2:0] STATE;

    always_ff @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            r_we_n <= 1;
            oe_data <= 0;
            r_addr <= 0;
            r_SRAM_DQ <= 0;
            r_io_data <= 0;
            r_done <= 0;
            STATE <= S_WAIT;
        end
        else begin
            if(STATE == S_WAIT) begin
                r_done <= 0;
                oe_data <= 0;
                if(i_read & ~i_write) begin
                    r_we_n <= 1;
                    r_addr <= i_addr;
                    STATE <= S_READ;
                end
                else if(i_write & ~i_read) begin
                    r_we_n <= 0;
                    r_addr <= i_addr;
                    r_io_data <= io_data;
                    STATE <= S_WRITE;
                end
                else begin
                    r_we_n <= 1;
                end
            end
            else if(STATE == S_READ) begin
                r_we_n <= 1;
                oe_data <= 1;
                r_io_data <= SRAM_DQ;
                r_done <= 1;
                STATE <= S_WAIT;
            end
            else if(STATE == S_WRITE) begin
                r_SRAM_DQ <= r_io_data;
                r_done <= 1;
                STATE <= S_WAIT;
            end
        end
    end

endmodule