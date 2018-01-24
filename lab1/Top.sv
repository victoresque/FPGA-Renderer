module Top(
	input i_clk,
	input i_start,
	output [3:0] o_random_out
);
`ifdef FAST_SIM
	parameter FREQ_HZ = 1000;
`elsif
	parameter FREQ_HZ = 50000000;
`endif

localparam   init_time          = 10000;

localparam   interval_init      = FREQ_HZ/50;
logic [63:0] interval           = interval_init;
localparam   interval_increment = interval_init;
localparam   interval_threshold = FREQ_HZ/4;

logic [3:0]  state = 0;
logic [63:0] time_last_change = 0;
logic [3:0]  random_num = 0;
logic [63:0] random_state = 1;

logic [63:0] clock_counter = 0;

assign o_random_out = random_num;

always_ff @(posedge i_clk) begin
    clock_counter <= clock_counter+1;

    if(clock_counter <= init_time) begin
        state <= 0;
    end
    else begin
        if(state == 0) begin
            if(i_start == 1) begin
                state <= 1;
                // random_state <= clock_counter;
            end
        end
        else if(state == 1) begin
            if(i_start == 0) begin
                state            <= 2;
                interval         <= interval_init;
                time_last_change <= clock_counter;
            end
            else if(i_start == 1) begin
                if(interval >= interval_threshold) begin
                    state            <= 3;
                    time_last_change <= 0;
                    interval         <= interval_init;
                end 
                else if(clock_counter-time_last_change >= interval) begin
                    interval         <= interval + interval_increment;
                    random_num       <= random_state;
                    random_state     <= random_state * 48271 % 2147483647;
                    time_last_change <= clock_counter;
                end
            end
        end 
        else if(state == 2) begin
            ////interval <= interval_init;
            if(i_start == 1) begin
                state <= 1;
            end 
            else if(clock_counter-time_last_change >= interval) begin
                random_num       <= random_state;
                random_state     <= random_state * 48271 % 2147483647;
                time_last_change <= clock_counter;
            end
        end 
        else if(state == 3) begin
            if(i_start == 0) begin
                state <= 0;
            end
        end
    end
end

endmodule
