
module AudioBuffer(
    input           i_clk,
    input           i_rst,
    // Audio Core
    input           i_reload,
    input   [31:0]  i_reload_addr,
    input           i_read,
    input   [3:0]   i_increment,
    input           i_write,
    inout   [15:0]  io_data,
    output          o_done,
    // SRAM controller
    output          o_mem_read,
    output          o_mem_write,
    output  [31:0]  o_mem_addr,
    inout   [15:0]  io_mem_data,
    input           i_mem_done
);

    reg r_done;
    assign o_done = r_done;
    
    reg          oe_data;
    reg  [REC_BUFSIZE*16-1:0] r_rbuf0, r_rbuf1; // 0 to audio core, 1 to mem
    reg  [REC_BUFSIZE*16-1:0] r_wbuf0, r_wbuf1;
    reg          r_addr_reload;
    reg          r_rbuf_reload;
    reg          r_wbuf_reload;
    reg          r_reload_done;
    reg  [31:0]  r_reload_addr;
    
    assign io_data = oe_data?r_rbuf0[(REC_BUFSIZE*16-1)-:16]:16'hzzzz;
    
    enum {
        S_IDLE,
        S_RELOAD,
        S_RELOAD_DONE,
        S_FLUSH,
        S_READ,
        S_WRITE
    } STATES;
    reg [2:0] STATE;
    
    reg [31:0] r_read_counter;
    reg [31:0] r_write_counter;
    reg [31:0] r_wbuf_reload_counter;
    
    always_ff @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            r_done <= 0;
            oe_data <= 0;
            r_rbuf0 <= 0;
            r_wbuf0 <= 0;
            r_read_counter <= 0;
            r_write_counter <= 0;
            
            r_rbuf_reload <= 0;
            r_wbuf_reload <= 0;
            r_addr_reload <= 0;
            r_reload_addr <= 0;
            STATE <= S_IDLE;
        end
        else begin
            if(STATE == S_IDLE) begin
                r_done <= 0;
                r_rbuf_reload <= 0;
                r_wbuf_reload <= 0;
                if(i_reload) begin
                    r_rbuf0 <= 0;
                    oe_data <= 0;
                    r_read_counter <= 0;
                    r_addr_reload <= 1;
                    r_rbuf_reload <= 1;
                    r_reload_addr <= i_reload_addr;
                    STATE <= S_RELOAD;
                end
                else if(i_read & ~i_write) begin
                    r_read_counter <= r_read_counter + 1;
                    r_done <= 1;
                    oe_data <= 1;
                    STATE <= S_READ;
                end
                else if(i_write & ~i_read) begin
                    r_write_counter <= r_write_counter + 1;
                    r_wbuf0 <= (r_wbuf0<<16) | io_data;
                    r_done <= 1;
                    STATE <= S_WRITE;
                end
            end
            else if(STATE == S_RELOAD) begin
                r_addr_reload <= 0;
                r_rbuf_reload <= 0;
                if(r_reload_done) begin
                    r_rbuf0 <= r_rbuf1;
                    r_rbuf_reload <= 1;
                    STATE <= S_RELOAD_DONE;
                end
            end
            else if(STATE == S_RELOAD_DONE) begin
                r_rbuf_reload <= 0;
                if(r_reload_done) begin
                    r_wbuf_reload_counter <= r_write_counter;
                    STATE <= S_FLUSH;
                end
            end
            else if(STATE == S_FLUSH) begin
                r_wbuf_reload <= 0;
                if(r_write_counter == 0) begin
                    r_done <= 1;
                    STATE <= S_IDLE;
                end
                else if(r_write_counter != REC_BUFSIZE) begin
                    r_write_counter <= r_write_counter + 1;
                    r_wbuf0 <= (r_wbuf0<<16);
                end
                else if(r_write_counter == REC_BUFSIZE) begin
                    r_write_counter <= 0;
                    r_wbuf_reload <= 1;
                end
                if(r_reload_done) begin
                    r_done <= 1;
                    STATE <= S_IDLE;
                end
            end
            else if(STATE == S_READ) begin
                if(r_read_counter == REC_BUFSIZE) begin
                    r_rbuf0 <= r_rbuf1;
                    r_rbuf_reload <= 1;
                    r_read_counter <= 0;
                end
                else begin
                    r_rbuf0 <= r_rbuf0<<16;
                end
                oe_data <= 0;
                r_done <= 0;
                STATE <= S_IDLE;
            end
            else if(STATE == S_WRITE) begin
                if(r_write_counter == REC_BUFSIZE) begin
                    r_wbuf_reload <= 1;
                    r_wbuf_reload_counter <= REC_BUFSIZE;
                    r_write_counter <= 0;
                end
                r_done <= 0;
                STATE <= S_IDLE;
            end
        end
    end
    

    enum {
        RS_IDLE,
        RS_RELOAD_ADDR,
        RS_RELOAD_RBUF,
        RS_RELOAD_RBUF_WAIT,
        RS_RELOAD_WBUF,
        RS_RELOAD_WBUF_WAIT
    } RELOAD_STATES;
    reg  [2:0]  RELOAD_STATE;
    reg         r_rbuf_reload_schedule;
    reg         r_wbuf_reload_schedule;
    reg         r_addr_reload_schedule;
    wire        w_noschedule;
    assign w_noschedule = ~r_rbuf_reload_schedule 
                        & ~r_wbuf_reload_schedule 
                        & ~r_addr_reload_schedule;
    
    reg  [31:0] r_reload_counter;
    
    reg r_mem_read;
    reg r_mem_write;
    assign o_mem_read = r_mem_read;
    assign o_mem_write = r_mem_write;
    reg          oe_mem_data;
    reg  [15:0]  r_mem_data;
    
    reg  [31:0]  r_raddr;
    reg  [31:0]  r_waddr;
    reg          r_LRcounter; // Left:1, Right:0
    
    assign io_mem_data  = oe_mem_data?r_mem_data:16'hzzzz;
    assign o_mem_addr   = oe_mem_data?r_waddr:r_raddr;
    
    wire [31:0]  w_mem_increment_a = {28'h0000000,i_increment}<<1;
    wire [31:0]  w_mem_increment_b = 1;
    wire [31:0]  w_mem_increment = w_mem_increment_a + 32'b1 + ~w_mem_increment_b;
    
    always_ff @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            r_rbuf_reload_schedule <= 0;
            r_wbuf_reload_schedule <= 0;
            r_addr_reload_schedule <= 0;
            r_reload_counter <= 0;
            
            r_mem_read <= 0;
            r_mem_write <= 0;
            oe_mem_data <= 0;
            
            r_raddr <= 0;
            r_waddr <= 0;
            r_LRcounter <= 1;
            
            r_mem_data <= 0;
            r_reload_done <= 0;
            RELOAD_STATE <= RS_IDLE;
        end
        else begin
            if(r_addr_reload) begin
                r_addr_reload_schedule <= 1;
            end
            if(r_rbuf_reload) begin
                r_rbuf_reload_schedule <= 1;
            end
            if(r_wbuf_reload) begin
                r_wbuf_reload_schedule <= 1;
                r_wbuf1 <= r_wbuf0;
            end
            
            r_reload_done <= 0;
            if(RELOAD_STATE == RS_IDLE) begin
                if(r_addr_reload_schedule) begin
                    r_addr_reload_schedule <= 0;
                    r_raddr <= r_reload_addr;
                    r_waddr <= r_reload_addr;
                    RELOAD_STATE <= RS_RELOAD_ADDR;
                end
                else if(r_rbuf_reload_schedule) begin
                    r_reload_counter <= 0;
                    r_rbuf_reload_schedule <= 0;
                    r_LRcounter <= 1;
                    RELOAD_STATE <= RS_RELOAD_RBUF;
                end
                else if(r_wbuf_reload_schedule) begin
                    r_reload_counter <= 0;
                    r_wbuf_reload_schedule <= 0;
                    oe_mem_data <= 1;
                    RELOAD_STATE <= RS_RELOAD_WBUF;
                end
            end
            else if(RELOAD_STATE == RS_RELOAD_ADDR) begin
                r_reload_done <= w_noschedule;
                RELOAD_STATE <= RS_IDLE;
            end
            else if(RELOAD_STATE == RS_RELOAD_RBUF) begin 
                if(r_reload_counter == REC_BUFSIZE) begin
                    r_reload_done <= w_noschedule;
                    RELOAD_STATE <= RS_IDLE;
                end
                else begin
                    r_mem_read <= 1;
                    RELOAD_STATE <= RS_RELOAD_RBUF_WAIT;
                end
            end
            else if(RELOAD_STATE == RS_RELOAD_RBUF_WAIT) begin
                r_mem_read <= 0; 
                if(i_mem_done) begin
                    r_rbuf1 <= (r_rbuf1<<16) | io_mem_data;
                    r_reload_counter <= r_reload_counter + 1;
                    if(r_LRcounter) begin
                        r_raddr <= r_raddr + 1;
                    end
                    else begin
                        r_raddr <= r_raddr + w_mem_increment;
                    end
                    r_LRcounter <= ~r_LRcounter;

                    RELOAD_STATE <= RS_RELOAD_RBUF;
                end
            end
            else if(RELOAD_STATE == RS_RELOAD_WBUF) begin
                if(r_reload_counter == r_wbuf_reload_counter) begin
                    oe_mem_data <= 0;
                    RELOAD_STATE <= RS_IDLE;
                end
                else begin
                    r_mem_write <= 1;
                    r_mem_data <= r_wbuf1[(REC_BUFSIZE*16-1)-:16];
                    r_wbuf1 <= r_wbuf1<<16;
                    RELOAD_STATE <= RS_RELOAD_WBUF_WAIT;
                end
            end
            else if(RELOAD_STATE == RS_RELOAD_WBUF_WAIT) begin
                r_mem_write <= 0;
                if(i_mem_done) begin
                    r_reload_counter <= r_reload_counter + 1;
                    r_waddr <= r_waddr + 1;
                    RELOAD_STATE <= RS_RELOAD_WBUF;
                end
            end
        end
    end
    
endmodule