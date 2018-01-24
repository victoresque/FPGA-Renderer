`include "include/RecorderDefine.vh"

module Fancy(
	input 			i_clk,
	input 			i_rst,
	
	input 	[15:0]	i_event_hold,
	input	[15:0]	i_fancy_raw,
	
	output 	[15:0]	o_led,
	input           AUD_BCLK,
    input           AUD_ADCLRCK,
    input           AUD_ADCDAT
	
);
	wire [15:0] w_adcdat;
    wire [15:0] w_adcdat_absolute;
    assign w_adcdat_absolute = w_adcdat[15]?(16'b1+~w_adcdat):w_adcdat;
	
	reg  [15:0] r_fancy;
	assign o_led = r_fancy;
    
    wire [15:0] i_fancy_raw_absolute = i_fancy_raw[15]?(16'b1+~i_fancy_raw):i_fancy_raw;
	
	reg  [15:0] i_fancy;

	AudioCoreADC adc_i2s (
        .i_rst(i_rst),
        .o_data(w_adcdat),
        .AUD_BCLK(AUD_BCLK),
        .AUD_ADCLRCK(AUD_ADCLRCK),
        .AUD_ADCDAT(AUD_ADCDAT)
    );
    
    wire [15:0] fancy_dec;
    reg [15:0] fancy_counter [15:0];
    
    localparam FANCY_REDUCED = 0;
    localparam FANCY_HOLD = 2048;
    
    // 1/64
    always_comb begin
    	fancy_dec = (i_fancy>>1)+(i_fancy>>2);
    end
    
    always_ff @(posedge AUD_ADCLRCK or posedge i_rst) begin
    	if(i_rst) begin
    		i_fancy <= 0;
    		r_fancy <= 0;
            fancy_counter[15] <= 0;
            fancy_counter[14] <= 0;
            fancy_counter[13] <= 0;
            fancy_counter[12] <= 0;
            fancy_counter[11] <= 0;
            fancy_counter[10] <= 0;
            fancy_counter[9] <= 0;
            fancy_counter[8] <= 0;
            fancy_counter[7] <= 0;
            fancy_counter[6] <= 0;
            fancy_counter[5] <= 0;
            fancy_counter[4] <= 0;
            fancy_counter[3] <= 0;
            fancy_counter[2] <= 0;
            fancy_counter[1] <= 0;
            fancy_counter[0] <= 0;
    	end
    	else begin
    		if(i_event_hold[15:12]==REC_PLAY || i_event_hold[15:12]==REC_PAUSE) begin
    			i_fancy <= fancy_dec + (i_fancy_raw_absolute>>2);
    		end
    		else begin
    			i_fancy <= fancy_dec + (w_adcdat_absolute>>2);
    		end
    		
            fancy_counter[15] <= fancy_counter[15] - 1;
            fancy_counter[14] <= fancy_counter[14] - 1;
            fancy_counter[13] <= fancy_counter[13] - 1;
            fancy_counter[12] <= fancy_counter[12] - 1;
            fancy_counter[11] <= fancy_counter[11] - 1;
            fancy_counter[10] <= fancy_counter[10] - 1;
            fancy_counter[9] <= fancy_counter[9] - 1;
            fancy_counter[8] <= fancy_counter[8] - 1;
            fancy_counter[7] <= fancy_counter[7] - 1;
            fancy_counter[6] <= fancy_counter[6] - 1;
            fancy_counter[5] <= fancy_counter[5] - 1;
            fancy_counter[4] <= fancy_counter[4] - 1;
            fancy_counter[3] <= fancy_counter[3] - 1;
            fancy_counter[2] <= fancy_counter[2] - 1;
            fancy_counter[1] <= fancy_counter[1] - 1;
            fancy_counter[0] <= fancy_counter[0] - 1;
    		
    		if(i_fancy>=500-FANCY_REDUCED) 	begin r_fancy[15] <= 1; fancy_counter[15] <= FANCY_HOLD; end
			else if(fancy_counter[15]==0) 				begin r_fancy[15] <= 0; end
			if(i_fancy>=1000-FANCY_REDUCED) 	begin r_fancy[14] <= 1; fancy_counter[14] <= FANCY_HOLD; end
			else if(fancy_counter[14]==0) 				begin r_fancy[14] <= 0; end
			if(i_fancy>=1500-FANCY_REDUCED) 	begin r_fancy[13] <= 1; fancy_counter[13] <= FANCY_HOLD; end
			else if(fancy_counter[13]==0) 				begin r_fancy[13] <= 0; end
			if(i_fancy>=2000-FANCY_REDUCED) 	begin r_fancy[12] <= 1; fancy_counter[12] <= FANCY_HOLD; end
			else if(fancy_counter[12]==0) 			    begin r_fancy[12] <= 0; end
    		if(i_fancy>=3000-FANCY_REDUCED)  begin r_fancy[11] <= 1; fancy_counter[11] <= FANCY_HOLD; end
            else if(fancy_counter[11]==0)                begin r_fancy[11] <= 0; end
            if(i_fancy>=5000-FANCY_REDUCED)  begin r_fancy[10] <= 1; fancy_counter[10] <= FANCY_HOLD; end
            else if(fancy_counter[10]==0)                begin r_fancy[10] <= 0; end
            if(i_fancy>=8000-FANCY_REDUCED)  begin r_fancy[9] <= 1; fancy_counter[9] <= FANCY_HOLD; end
            else if(fancy_counter[9]==0)                begin r_fancy[9] <= 0; end
            if(i_fancy>=12000-FANCY_REDUCED)  begin r_fancy[8] <= 1; fancy_counter[8] <= FANCY_HOLD; end
            else if(fancy_counter[8]==0)                begin r_fancy[8] <= 0; end
            if(i_fancy>=16000-FANCY_REDUCED)  begin r_fancy[7] <= 1; fancy_counter[7] <= FANCY_HOLD; end
            else if(fancy_counter[7]==0)                begin r_fancy[7] <= 0; end
            if(i_fancy>=20000-FANCY_REDUCED)  begin r_fancy[6] <= 1; fancy_counter[6] <= FANCY_HOLD; end
            else if(fancy_counter[6]==0)                begin r_fancy[6] <= 0; end
            if(i_fancy>=22000-FANCY_REDUCED)  begin r_fancy[5] <= 1; fancy_counter[5] <= FANCY_HOLD; end
            else if(fancy_counter[5]==0)                begin r_fancy[5] <= 0; end
            if(i_fancy>=24000-FANCY_REDUCED)  begin r_fancy[4] <= 1; fancy_counter[4] <= FANCY_HOLD; end
            else if(fancy_counter[4]==0)                begin r_fancy[4] <= 0; end
            if(i_fancy>=26000-FANCY_REDUCED)  begin r_fancy[3] <= 1; fancy_counter[3] <= FANCY_HOLD; end
            else if(fancy_counter[3]==0)                begin r_fancy[3] <= 0; end
            if(i_fancy>=28000-FANCY_REDUCED)  begin r_fancy[2] <= 1; fancy_counter[2] <= FANCY_HOLD; end
            else if(fancy_counter[2]==0)                begin r_fancy[2] <= 0; end
            if(i_fancy>=30000-FANCY_REDUCED)  begin r_fancy[1] <= 1; fancy_counter[1] <= FANCY_HOLD; end
            else if(fancy_counter[1]==0)                begin r_fancy[1] <= 0; end
            if(i_fancy>=32000-FANCY_REDUCED)  begin r_fancy[0] <= 1; fancy_counter[0] <= FANCY_HOLD; end
            else if(fancy_counter[0]==0)                begin r_fancy[0] <= 0; end
    	end
    end

endmodule