module Recorder (
    input           i_clk,
    input           i_rst,
    // Input
    input   [15:0]  i_input_event,
    // Output
    output  [15:0]  o_output_event,
	 output	[15:0]  o_event_hold,
    output  [63:0]  o_time,
    // Audio CODEC
    input           AUD_BCLK,
    input           AUD_ADCLRCK,
    input           AUD_ADCDAT,
    input           AUD_DACLRCK,
    output          AUD_DACDAT,
    // Mem Controller
    output          o_mem_read,
    output          o_mem_write,
    output  [31:0]  o_mem_addr,
    inout   [15:0]  io_mem_data,
    input           i_mem_done,
    // Fancy
    output  [15:0]  o_fancy
);

    wire w_aud_init_fin;
    assign w_aud_init_fin = 1;
    wire w_audio_core_stop_signal;
    
    RecorderCore recorderCore(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_input_event(i_input_event),
        .o_event(o_output_event),
		  .o_event_hold(o_event_hold),
        .o_aud_init_start(w_aud_init_start),
        .i_aud_init_fin(w_aud_init_fin),
        .i_stop(w_audio_core_stop_signal)
    );
    
    wire            w_buf_reload;
    wire            w_buf_read;
    wire            w_buf_write;
    wire    [3:0]   w_buf_increment;
    wire    [15:0]  w_buf_data;
    wire            w_buf_done;
    wire    [31:0]  w_buf_reload_addr;
    AudioCore audioCore(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_event(o_output_event),
        .o_time(o_time),
        .AUD_BCLK(AUD_BCLK),
        .AUD_ADCLRCK(AUD_ADCLRCK),
        .AUD_ADCDAT(AUD_ADCDAT),
        .AUD_DACLRCK(AUD_DACLRCK),
        .AUD_DACDAT(AUD_DACDAT),
        .o_buf_reload(w_buf_reload),
        .o_buf_read(w_buf_read),
        .o_buf_write(w_buf_write),
        .o_buf_increment(w_buf_increment),
        .io_buf_data(w_buf_data),
        .i_buf_done(w_buf_done),
        .o_buf_reload_addr(w_buf_reload_addr),
        .o_stop_signal(w_audio_core_stop_signal),
        .o_fancy(o_fancy)
    );
    
    AudioBuffer audioBuffer(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_reload(w_buf_reload),
        .i_reload_addr(w_buf_reload_addr),
        .i_read(w_buf_read),
        .i_write(w_buf_write),
        .i_increment(w_buf_increment),
        .io_data(w_buf_data),
        .o_done(w_buf_done),
        .o_mem_read(o_mem_read),
        .o_mem_write(o_mem_write),
        .o_mem_addr(o_mem_addr),
        .io_mem_data(io_mem_data),
        .i_mem_done(i_mem_done)
    );

endmodule