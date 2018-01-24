`include "include/RecorderDefine.vh"

module InputController(
    input           i_clk,
    input           i_rst,
    // Raw Input
    input           i_btn_play,
    input           i_btn_pause,
    input           i_btn_stop,
    input           i_btn_record,
    input   [8:0]   i_sw_speed,
    input           i_sw_interpol,
    // Recorder Core
    output  [15:0]  o_input_event       // 4code,2speed,4param,1inter,5reserved
);
    wire w_btn_play;
    wire w_btn_pause;
    wire w_btn_stop;
    wire w_btn_record;

    Debounce dbPlay  (.i_in(i_btn_play),  .i_clk(i_clk),.o_pos(w_btn_play)  );
    Debounce dbPause (.i_in(i_btn_pause), .i_clk(i_clk),.o_pos(w_btn_pause) );
    Debounce dbStop  (.i_in(i_btn_stop),  .i_clk(i_clk),.o_pos(w_btn_stop)  );
    Debounce dbRecord(.i_in(i_btn_record),.i_clk(i_clk),.o_pos(w_btn_record));

    reg  [3:0] r_input_code;
    wire [1:0] w_input_speed;
    wire [3:0] w_input_mult;
    wire       w_input_interpol;
    assign o_input_event = {r_input_code, w_input_speed, w_input_mult, w_input_interpol, 5'd0};
    
    always_comb begin
        case (i_sw_speed[1:0])
            2'b10:      begin w_input_speed = REC_FAST;   end
            2'b01:      begin w_input_speed = REC_SLOW;   end
            default:    begin w_input_speed = REC_NORMAL; end
        endcase
        case (i_sw_speed[8:2])
            7'b1000000: begin w_input_mult = 4'd8; end
            7'b0100000: begin w_input_mult = 4'd7; end
            7'b0010000: begin w_input_mult = 4'd6; end
            7'b0001000: begin w_input_mult = 4'd5; end
            7'b0000100: begin w_input_mult = 4'd4; end
            7'b0000010: begin w_input_mult = 4'd3; end
            7'b0000001: begin w_input_mult = 4'd2; end
            default:    begin w_input_mult = 4'd1; end
        endcase
        
        w_input_interpol = i_sw_interpol;
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            r_input_code <= 0;
        end
        else begin
            if(w_btn_play)        begin r_input_code <= REC_PLAY;   end
            else if(w_btn_pause)  begin r_input_code <= REC_PAUSE;  end
            else if(w_btn_stop)   begin r_input_code <= REC_STOP;   end
            else if(w_btn_record) begin r_input_code <= REC_RECORD; end
            else                  begin r_input_code <= REC_NONE;   end
        end
    end

endmodule