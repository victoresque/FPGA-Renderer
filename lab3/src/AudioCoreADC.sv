
module AudioCoreADC(
    input           i_rst,
    // Data
    output  [REC_BITLEN-1:0]  o_data,
    // Audio CODEC
    input           AUD_BCLK,
    input           AUD_ADCLRCK,
    input           AUD_ADCDAT
);
    reg [REC_BITLEN-1:0] r_data;
    assign o_data = r_data;

    reg [REC_BITLOG:0] r_counter;

    enum {
        S_LWAIT,
        S_LEFT,
        S_RWAIT,
        S_RIGHT
    } STATES;
    reg [2:0] STATE;
    reg LRCK_val;

    always_ff @(posedge AUD_BCLK or posedge i_rst) begin
        if(i_rst) begin
            r_data <= 0;
            r_counter <= 1;
            LRCK_val <= 1;
            STATE <= S_LWAIT;
        end
        else begin
            if(STATE == S_LWAIT) begin
                if(LRCK_val & ~AUD_ADCLRCK) begin
                    r_counter <= 1;
                    STATE <= S_LEFT;
                end
            end
            else if(STATE == S_RWAIT) begin
                if(~LRCK_val & AUD_ADCLRCK) begin
                    r_counter <= 1;
                    STATE <= S_RIGHT;
                end
            end
            else if(STATE == S_LEFT || STATE == S_RIGHT) begin
                if(r_counter == 1) begin
                    r_data <= AUD_ADCDAT;
                    r_counter <= r_counter + 1;
                end
                else if(r_counter <= REC_BITLEN) begin
                    r_data <= (r_data<<1)|AUD_ADCDAT; 
                    r_counter <= r_counter + 1;
                end
                else begin
                    if(STATE == S_LEFT) begin STATE <= S_RWAIT; end
                    else                begin STATE <= S_LWAIT; end
                end
            end
            LRCK_val <= AUD_ADCLRCK;
        end
    end

endmodule