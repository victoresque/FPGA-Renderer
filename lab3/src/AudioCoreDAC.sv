
module AudioCoreDAC(
    input           i_rst,
    // Data
    input   [REC_BITLEN-1:0]  i_data,
    // Audio CODEC
    input           AUD_BCLK,
    input           AUD_DACLRCK,
    output          AUD_DACDAT
);
    reg [REC_BITLEN-1:0] r_data;

    reg r_AUD_DACDAT; // change on negedge
    assign AUD_DACDAT = r_AUD_DACDAT;

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
            LRCK_val <= 1;
            STATE <= S_LWAIT;
        end
        else begin
            if(STATE == S_LWAIT) begin
                if(LRCK_val & ~AUD_DACLRCK) begin
                    r_data <= i_data;
                    STATE <= S_LEFT;
                end
            end
            else if(STATE == S_RWAIT) begin
                if(~LRCK_val & AUD_DACLRCK) begin
                    r_data <= i_data;
                    STATE <= S_RIGHT;
                end
            end
            else if(STATE == S_LEFT || STATE == S_RIGHT) begin
                if(r_counter == REC_BITLEN) begin
                    if(STATE == S_LEFT) begin STATE <= S_RWAIT; end
                    else                begin STATE <= S_LWAIT; end
                end
                else begin
                    r_data <= r_data << 1;
                end
            end
            LRCK_val <= AUD_DACLRCK;
        end
    end

    always_ff @(negedge AUD_BCLK or posedge i_rst) begin
        if(i_rst) begin
            r_AUD_DACDAT <= 0;
            r_counter <= 0;
        end
        else begin
            if(STATE == S_LWAIT) begin
                r_counter <= 0;
                r_AUD_DACDAT <= 0;
            end
            else if(STATE == S_RWAIT) begin
                r_counter <= 0;
                r_AUD_DACDAT <= 0;
            end
            else if(STATE == S_LEFT || STATE == S_RIGHT) begin
                r_AUD_DACDAT <= r_data[REC_BITLEN-1];
                r_counter <= r_counter + 1;
            end
        end
    end

endmodule