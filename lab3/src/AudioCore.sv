`include "include/RecorderDefine.vh"

module AudioCore(
    input           i_clk,
    input           i_rst,
    // Recorder Core
    input   [15:0]  i_event,               // 4code,2speed,4param,1inter,5reserved
    output  [63:0]  o_time,                 // 12current,12total
    // Audio CODEC
    input           AUD_BCLK,
    input           AUD_ADCLRCK,
    input           AUD_ADCDAT,
    input           AUD_DACLRCK,
    output          AUD_DACDAT,
    // Audio Buffer
    output          o_buf_reload,
    output          o_buf_read,
    output          o_buf_write,
    output  [3:0]   o_buf_increment,
    inout   [15:0]  io_buf_data,
    input           i_buf_done,
    output  [31:0]  o_buf_reload_addr,
    // Output Signal
    output          o_stop_signal,
    // Fancy
    output  [15:0]  o_fancy
);
    assign o_fancy = r_dacdat;

    reg         r_buf_reload;
    reg         r_buf_read;
    reg         r_buf_write;
    reg         r_buf_oe;
    reg  [3:0]  r_buf_increment;
    reg  [15:0] r_buf_data;
    reg  [31:0] r_buf_reload_addr;
    assign o_buf_reload      = r_buf_reload;
    assign o_buf_read        = r_buf_read;
    assign o_buf_write       = r_buf_write;
    assign o_buf_increment   = r_buf_increment;
    assign io_buf_data       = r_buf_oe?r_buf_data:16'hzzzz;
    assign o_buf_reload_addr = r_buf_reload_addr;
    
    wire [15:0] w_adcdat;
    reg  [15:0] r_dacdat;

    AudioCoreADC adc_i2s (
        .i_rst(i_rst),
        .o_data(w_adcdat),
        .AUD_BCLK(AUD_BCLK),
        .AUD_ADCLRCK(AUD_ADCLRCK),
        .AUD_ADCDAT(AUD_ADCDAT)
    );
    AudioCoreDAC dac_i2s (
        .i_rst(i_rst),
        .i_data(r_dacdat),
        .AUD_BCLK(AUD_BCLK),
        .AUD_DACLRCK(AUD_DACLRCK),
        .AUD_DACDAT(AUD_DACDAT)
    );
    
    wire [3:0] w_control_code;
    wire [1:0] w_control_speed;
    wire [3:0] w_control_mult;
    wire       w_control_interpol;
    assign w_control_code     = i_event[15:12];
    assign w_control_speed    = i_event[11:10];
    assign w_control_mult     = i_event[9:6];
    assign w_control_interpol = i_event[5];
    
    enum {
        S_IDLE,
		S_PAUSE,
        S_RELOAD,
        S_REC,
        S_REC_WRITE_TIME,
        S_PLAY_READ_TIME,
        S_PLAY
    } STATES;
    reg [2:0] STATE;
    reg [2:0] STATE_AFTER_RELOAD;

    reg r_ADCLRCK;
    reg r_DACLRCK;
    reg [3:0]  r_slow_mult;
    reg [31:0] r_slow_counter;
    reg [15:0] r_dacdatL, r_dacdatL_prev;
    reg [15:0] r_dacdatR, r_dacdatR_prev;
    wire [15:0] w_interpolL, w_interpolR;
    reg        r_readL;
    reg        r_readR;
    
    AudioCoreInterpolation interpolL(
        .i_data_prev(r_dacdatL_prev),
        .i_data(r_dacdatL),
        .i_divisor(r_slow_mult),
        .o_quotient(w_interpolL)
    );
    AudioCoreInterpolation interpolR(
        .i_data_prev(r_dacdatR_prev),
        .i_data(r_dacdatR),
        .i_divisor(r_slow_mult),
        .o_quotient(w_interpolR)
    );
    
    reg  [31:0] r_time_counter;
    reg         r_rwtime_counter;
    reg  [31:0] r_length;
    reg  [31:0] r_current;
    assign o_time = {r_current>>1,r_length>>1};
    
    reg         r_stop_signal;
    assign o_stop_signal = r_stop_signal;

    always_ff @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            r_buf_read <= 0;
            r_buf_write <= 0;
            r_buf_oe <= 0;
            r_buf_increment <= 1;
            r_buf_data <= 0;
            r_dacdat <= 0;
            r_ADCLRCK <= 0;
            r_DACLRCK <= 0;
            r_slow_mult <= 1;
            r_slow_counter <= 1;
            r_dacdatL <= 0;
            r_dacdatL_prev <= 0;
            r_dacdatR <= 0;
            r_dacdatR_prev <= 0;
            r_readL <= 0;
            r_readR <= 0;
            
            r_time_counter <= 0;
            r_rwtime_counter <= 0;
            r_length <= 0;
            r_stop_signal <= 0;
            
            r_buf_reload <= 1;
            r_buf_reload_addr <= 2;
            STATE <= S_RELOAD;
            STATE_AFTER_RELOAD <= S_IDLE;
        end
        else begin
            if(STATE == S_IDLE) begin
                r_buf_read <= 0;
                r_buf_write <= 0;
                if(w_control_code == REC_PLAY) begin
                    r_readL <= 0;
                    r_readR <= 0;
                    r_dacdatL <= 0;
                    r_dacdatL_prev <= 0;
                    r_dacdatR <= 0;
                    r_dacdatR_prev <= 0;
                    r_slow_counter <= 1;
                    r_current <= 0;
                    r_rwtime_counter <= 0;
                    
                    r_buf_read <= 1;
                    //STATE <= S_PLAY_READ_TIME;
                    
                    r_buf_reload <= 1;
                    r_buf_reload_addr <= 0;
                    STATE <= S_RELOAD;
                    STATE_AFTER_RELOAD <= S_PLAY_READ_TIME;
                end
                else if(w_control_code == REC_RECORD) begin
                    r_buf_oe <= 1;
                    r_time_counter <= 0;
                    //STATE <= S_REC;
                    
                    r_buf_reload <= 1;
                    r_buf_reload_addr <= 2;
                    STATE <= S_RELOAD;
                    STATE_AFTER_RELOAD <= S_REC;
                end
            end
            if(STATE == S_RELOAD) begin
                r_buf_reload <= 0;
                r_stop_signal <= 0;
                if(i_buf_done) begin
                    if(STATE_AFTER_RELOAD == S_REC_WRITE_TIME) begin
                        r_rwtime_counter <= 0;
                        r_buf_write <= 1;
                        r_buf_data <= r_time_counter[31:16];
                    end
                    STATE <= STATE_AFTER_RELOAD;
                end
            end
            else if(STATE == S_REC) begin
                r_buf_write <= 0;
                if(w_control_code == REC_STOP) begin
                    r_buf_reload <= 1;
                    r_buf_reload_addr <= 0;
                    STATE <= S_RELOAD;
                    STATE_AFTER_RELOAD <= S_REC_WRITE_TIME;
                end
                else begin
                    if(   (r_ADCLRCK & ~AUD_ADCLRCK)
                        | (~r_ADCLRCK & AUD_ADCLRCK) ) begin
                        r_buf_write <= 1;
                        r_time_counter <= r_time_counter + 1;
                        r_length <= r_time_counter;
                        r_current <= r_time_counter;
                        r_buf_data <= w_adcdat;
                    end
                end
            end
            else if(STATE == S_REC_WRITE_TIME) begin
                r_buf_write <= 0;
                if(r_rwtime_counter == 0) begin
                    if(i_buf_done) begin
                        r_rwtime_counter <= 1;
                        r_buf_write <= 1;
                        r_buf_data <= r_time_counter[15:0];
                    end
                end
                else if(r_rwtime_counter == 1) begin
                    if(i_buf_done) begin
                        r_buf_oe <= 0;
                        r_buf_reload <= 1;
                        r_buf_reload_addr <= 0;
                        STATE <= S_RELOAD;
                        STATE_AFTER_RELOAD <= S_IDLE;
                    end
                end
            end
            else if(STATE == S_PLAY_READ_TIME) begin
                r_buf_read <= 0;
                if(r_rwtime_counter == 0) begin
                    if(i_buf_done) begin
                        r_length <= (r_length<<16) | io_buf_data;
                        r_rwtime_counter <= 1;
                        r_buf_read <= 1;
                    end
                end
                else if(r_rwtime_counter == 1) begin
                    if(i_buf_done) begin
                        r_length <= (r_length<<16) | io_buf_data;
                        STATE  <= S_PLAY;
                    end
                end
            end
				else if(STATE == S_PAUSE) begin
				    if(w_control_code == REC_PLAY) begin
					     STATE <= S_PLAY;
					 end
					 else if(w_control_code == REC_STOP) begin
					     r_current <= r_length;
					     STATE <= S_PLAY;
					 end
				end
            else if(STATE == S_PLAY) begin
                r_buf_read <= 0;
                if(w_control_code == REC_PAUSE) begin
                    STATE <= S_PAUSE;
                end
                else if(w_control_code == REC_STOP
                    ||  r_current >= r_length ) begin
                    r_buf_reload <= 1;
                    r_buf_reload_addr <= 0;
                    r_dacdat <= 0;
                    r_current <= 0;
                    r_stop_signal <= 1;
                    STATE <= S_RELOAD;
                    STATE_AFTER_RELOAD <= S_IDLE;
                end
                else begin
                    r_buf_increment <= (w_control_speed==REC_FAST)?w_control_mult:1;
                    r_slow_mult     <= (w_control_speed==REC_SLOW)?w_control_mult:1;
                    
                    if(r_slow_counter == r_slow_mult) begin
                        if(r_DACLRCK & ~AUD_DACLRCK) begin
                            r_buf_read <= 1;
                            r_readL <= 1;
                            r_dacdat <= r_dacdatL_prev;
                        end
                        if(~r_DACLRCK & AUD_DACLRCK) begin
                            r_buf_read <= 1;
                            r_readR <= 1;
                            r_dacdat <= r_dacdatR_prev;
                            r_slow_counter <= 1;
                        end
                    end
                    else begin
                        if(r_DACLRCK & ~AUD_DACLRCK) begin
                            if(w_control_interpol) begin
                                r_dacdat <= r_dacdatL_prev + w_interpolL;
                            end
                            else begin
                                r_dacdat <= r_dacdatL_prev;
                            end
                        end
                        if(~r_DACLRCK & AUD_DACLRCK) begin
                            if(w_control_interpol) begin
                                r_dacdat <= r_dacdatR_prev + w_interpolR;
                            end
                            else begin
                                r_dacdat <= r_dacdatR_prev;
                            end
                            r_slow_counter <= r_slow_counter + 1;
                        end
                    end
                    
                    if(r_buf_read) begin
                        r_current <= r_current + r_buf_increment;
                    end
                    
                    if(r_slow_mult != w_control_mult) begin
                        r_slow_counter <= 1;
                    end
                    
                    if(i_buf_done) begin
                        if(r_readL) begin
                            r_dacdatL_prev <= r_dacdatL;
                            r_dacdatL <= io_buf_data;
                            r_readL <= 0;
                        end
                        else if(r_readR) begin
                            r_dacdatR_prev <= r_dacdatR;
                            r_dacdatR <= io_buf_data;
                            r_readR <= 0;
                        end
                    end
                end
            end
            r_ADCLRCK <= AUD_ADCLRCK;
            r_DACLRCK <= AUD_DACLRCK;
        end
    end

endmodule