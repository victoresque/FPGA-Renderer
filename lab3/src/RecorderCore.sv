`include "include/RecorderDefine.vh"

module RecorderCore(
    input           i_clk,
    input           i_rst,
    // Input Controller
    input   [15:0]  i_input_event,          // 4code,2speed,4param,1inter,5reserved
    // Audio Core
    output  [15:0]  o_event,
	 // Output Controller
	 output  [15:0]  o_event_hold,
    // Audio Init 
    output          o_aud_init_start,
    input           i_aud_init_fin,
    // Stop
    input           i_stop
);
    
    wire [3:0] w_input_code;
    wire [1:0] w_input_speed;
    wire [3:0] w_input_mult;
    wire       w_input_interpol;
    assign w_input_code     = i_input_event[15:12];
    assign w_input_speed    = i_input_event[11:10];
    assign w_input_mult     = i_input_event[9:6];
    assign w_input_interpol = i_input_event[5];

    reg [3:0] r_status_code;
    reg [1:0] r_status_speed;
    reg [3:0] r_status_mult;
    reg       r_status_interpol;
    assign o_event = {r_status_code, r_status_speed, r_status_mult, r_status_interpol, 5'd0};
	 
	 reg [3:0] r_status_hold;
	 assign o_event_hold = {r_status_hold, r_status_speed, r_status_mult, r_status_interpol, 5'd0};

    enum {
        S_PREPARE,
        S_IDLE,
        S_REC,
        S_PLAY,
        S_PAUSE
    } STATES;
    reg [2:0] STATE;

    always_ff @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            r_status_code <= REC_NONE;
				r_status_hold <= REC_NONE;
            r_status_speed <= REC_NORMAL;
            r_status_mult <= 1;
            STATE <= S_PREPARE;
        end
        else begin
            r_status_speed <= w_input_speed;
            r_status_mult <= w_input_mult;
            r_status_interpol <= w_input_interpol;

            if(STATE == S_PREPARE) begin
                o_aud_init_start <= 1;
                if(i_aud_init_fin) begin
                    o_aud_init_start <= 0;
                    STATE <= S_IDLE;
                end
            end
            else if(STATE == S_IDLE) begin
                r_status_code <= REC_NONE;
                if(w_input_code == REC_RECORD) begin
                    r_status_code <= REC_RECORD;
						  r_status_hold <= REC_RECORD;
                    STATE <= S_REC;
                end
                else if(w_input_code == REC_PLAY) begin
                    r_status_code <= REC_PLAY;
						  r_status_hold <= REC_PLAY;
                    STATE <= S_PLAY;
                end
            end
            else if(STATE == S_REC) begin
                r_status_code <= REC_NONE;
                if(w_input_code == REC_STOP) begin
                    r_status_code <= REC_STOP;
						  r_status_hold <= REC_STOP;
                    STATE <= S_IDLE;
                end
            end
            else if(STATE == S_PLAY) begin
                r_status_code <= REC_NONE;
                if(w_input_code == REC_PAUSE) begin
                    r_status_code <= REC_PAUSE;
						  r_status_hold <= REC_PAUSE;
                    STATE <= S_PAUSE;
                end
                else if(w_input_code == REC_STOP || i_stop) begin
                    r_status_code <= REC_STOP;
						  r_status_hold <= REC_STOP;
                    STATE <= S_IDLE;
                end
                else if(w_input_code == REC_PLAY) begin
                    r_status_code <= REC_PLAY;
						  r_status_hold <= REC_PLAY;
                end
            end
            else if(STATE == S_PAUSE) begin
                r_status_code <= REC_NONE;
                if(w_input_code == REC_PLAY) begin
                    r_status_code <= REC_PLAY;
						  r_status_hold <= REC_PLAY;
                    STATE <= S_PLAY;
                end
            end
        end
    end


endmodule