module sdram_avm_controller (
    input           clk,
    input           rst,
    // Interface
    input           i_read,
    input           i_write,
    input   [31:0]  i_addr,
    inout   [15:0]  io_data,
    output          o_done,
    // SDRAM Controller
    output  [24:0]  o_avm_address,
    output  [3:0]   o_avm_byteenable,
    output          o_avm_chipselect,
    output  [31:0]  o_avm_writedata,
    output          o_avm_read,
    output          o_avm_write,
    input   [31:0]  i_avm_readdata,
    input           i_avm_readdatavalid,
    input           i_avm_waitrequest
);
    assign o_avm_chipselect = 1'b1;
    
    reg [31:0] r_addr;
    assign o_avm_address = r_addr>>1;
    assign o_avm_byteenable = (r_addr&1)?4'b1100:4'b0011;
    
    reg        r_read;
    reg        r_write;
    assign o_avm_read = r_read;
    assign o_avm_write = r_write;
    
    reg [15:0] r_io_data;
    assign o_avm_writedata = (r_addr&1)?{r_io_data,16'b0}:{16'b0,r_io_data};
    
    reg        oe_data;
    assign io_data = oe_data?r_io_data:16'hzzzz;
    
    reg        r_done;
    assign o_done = r_done;

    enum {
        S_WAIT,
        S_READ,
        S_WRITE
    } STATES;
    reg [2:0] STATE;

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            oe_data <= 0;
            r_addr <= 0;
            r_io_data <= 0;
            r_done <= 0;
            STATE <= S_WAIT;
        end
        else begin
            if(STATE == S_WAIT) begin
                r_done <= 0;
                oe_data <= 0;
                if((i_read & ~i_write) | (r_read & ~r_write)) begin
                    r_read <= 1;
                    r_addr <= i_addr;
                    if(~i_avm_waitrequest) begin
                        STATE <= S_READ;
                    end
                end
                else if((i_write & ~i_read) | (r_write & ~r_read)) begin
                    r_write <= 1;
                    r_addr <= i_addr;
                    r_io_data <= io_data;
                    if(~i_avm_waitrequest) begin
                        STATE <= S_WRITE;
                    end
                end
            end
            else if(STATE == S_READ) begin
                r_read <= 0;
                if(i_avm_readdatavalid) begin
                    oe_data <= 1;
                    r_io_data <= ((r_addr&1)?i_avm_readdata[31:16]:i_avm_readdata[15:0]);
                    r_done <= 1;
                    STATE <= S_WAIT;
                end
            end
            else if(STATE == S_WRITE) begin
                r_write <= 0;
                if(~i_avm_waitrequest) begin
                    r_done <= 1;
                    STATE <= S_WAIT;
                end
            end
        end
    end

endmodule