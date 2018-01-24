module LCD(
	output  [7:0] LCD_DATA,
	output LCD_EN,
	output LCD_ON,
	output LCD_RW,
	output LCD_RS,
	output LCD_BLON,

	output BUSY,
	input START,
	input CLEAR,

	input [7:0] CHARACTER,
	input [7:0] ADDRESS,
	input  i_rst,
	input  i_clk
);

enum{
	WAIT,
	INIT,
	SET_ADRR,
	SET_WORD,
	IDLE
}states;

localparam WAIT_CLOCK = 1500000;
localparam CLEAR_INTERVAL = 80000;
localparam ENABLE_INTERVAL = 30;
localparam ADDRESS_SETUP_INTERVAL = 4;
localparam INIT_INTERVAL = 2000;
localparam PROCESS_INTERVAL = 22000;

reg [2:0]  state;
reg [39:0] clock_counter;
reg [39:0] last_clock;
reg [1:0]  init_setup;
reg [7:0] data;
reg [7:0] address;
reg [7:0] character;
reg rs;
reg rw;
reg en;

reg busy;

assign LCD_DATA = data;
assign LCD_RS = rs;
assign LCD_RW = rw;
assign LCD_EN = en;
assign BUSY = busy;

assign LCD_ON = 1;
assign LCD_BLON = 1;

always_ff @(posedge i_clk or posedge i_rst) begin
	if (i_rst) begin
		state <= WAIT;
		clock_counter <= 40'b0;
		last_clock <= 40'b0;
		init_setup <= 2'b0;
		rs <= 0;
		rw <= 0;
		en <= 1;
		busy <= 1;
		data <= 8'b00111111;
		address <= 8'b0;
		character <= 8'b0;
	end
	else if (state == WAIT) begin
		if (clock_counter >= WAIT_CLOCK) begin
			state <= INIT;
			last_clock <= clock_counter;
			rs <= 0;
			rw <= 0;
		end
		clock_counter <= clock_counter + 1;
	end
	else if (state == INIT) begin
		if (init_setup == 0) begin
			rs <= 0;
			rw <= 0;
			data <= 8'b00111000;
			clock_counter <= clock_counter + 1;
			if (clock_counter >= PROCESS_INTERVAL + ENABLE_INTERVAL + ADDRESS_SETUP_INTERVAL + last_clock) begin
				init_setup <= 1;
				rs <= 0;
				rw <= 1;
				last_clock <= clock_counter + 1;
			end
			else if (clock_counter >= ENABLE_INTERVAL + ADDRESS_SETUP_INTERVAL + last_clock) begin
				en <= 0;				
			end
			else if (clock_counter >= ADDRESS_SETUP_INTERVAL + last_clock) begin
				en <= 1;
			end
		end
		else if (init_setup == 1) begin
			rs <= 0;
			rw <= 0;
			data <= 8'b00001100;
			clock_counter <= clock_counter + 1;
			if (clock_counter >= PROCESS_INTERVAL + ENABLE_INTERVAL + ADDRESS_SETUP_INTERVAL + last_clock) begin
				init_setup <= 2;
				rs <= 0;
				rw <= 1;
				last_clock <= clock_counter + 1;
			end
			else if (clock_counter >= ENABLE_INTERVAL + ADDRESS_SETUP_INTERVAL + last_clock) begin
				en <= 0;				
			end
			else if (clock_counter >= ADDRESS_SETUP_INTERVAL + last_clock) begin
				en <= 1;
			end
		end
		else if (init_setup == 2) begin
			rs <= 0;
			rw <= 0;
			data <= 8'b00000001;
			clock_counter <= clock_counter + 1;
			if (clock_counter >= WAIT_CLOCK + last_clock) begin
				init_setup <= 3;
				rs <= 0;
				rw <= 1;
				last_clock <= clock_counter + 1;
			end
			else if (clock_counter >= ENABLE_INTERVAL + ADDRESS_SETUP_INTERVAL + last_clock) begin
				en <= 0;				
			end
			else if (clock_counter >= ADDRESS_SETUP_INTERVAL + last_clock) begin
				en <= 1;
			end
		end
		else if (init_setup == 3) begin
			rs <= 0;
			rw <= 0;
			data <= 8'b00000110;
			clock_counter <= clock_counter + 1;
			if (clock_counter >= PROCESS_INTERVAL + ENABLE_INTERVAL + ADDRESS_SETUP_INTERVAL + last_clock) begin
				init_setup <= 0;
				state <= IDLE;
				busy <= 0;
				rs <= 0;
				rw <= 1;
				last_clock <= clock_counter + 1;
			end
			else if (clock_counter >= ENABLE_INTERVAL + ADDRESS_SETUP_INTERVAL + last_clock) begin
				en <= 0;				
			end
			else if (clock_counter >= ADDRESS_SETUP_INTERVAL + last_clock) begin
				en <= 1;
			end
		end
	end
	else if (state == SET_ADRR) begin
		rs <= 0;
		rw <= 0;
		data <= {1'b1,address[6:0]};
		clock_counter <= clock_counter + 1;
		if (clock_counter >= PROCESS_INTERVAL + ENABLE_INTERVAL + ADDRESS_SETUP_INTERVAL + last_clock) begin
			state <= SET_WORD;
			rs <= 0;
			rw <= 1;
			last_clock <= clock_counter + 1;
		end
		else if (clock_counter >= ENABLE_INTERVAL + ADDRESS_SETUP_INTERVAL + last_clock) begin
			en <= 0;				
		end
		else if (clock_counter >= ADDRESS_SETUP_INTERVAL + last_clock) begin
			en <= 1;
		end
	end
	else if (state == SET_WORD) begin
		rs <= 1;
		rw <= 0;
		data <= character;
		clock_counter <= clock_counter + 1;
		if (clock_counter >= PROCESS_INTERVAL + ENABLE_INTERVAL + ADDRESS_SETUP_INTERVAL + last_clock) begin
			state <= IDLE;
			busy <= 0;
			rs <= 0;
			rw <= 1;
			last_clock <= clock_counter + 1;
		end
		else if (clock_counter >= ENABLE_INTERVAL + ADDRESS_SETUP_INTERVAL + last_clock) begin
			en <= 0;				
		end
		else if (clock_counter >= ADDRESS_SETUP_INTERVAL + last_clock) begin
			en <= 1;
		end
	end
	else if ((state == IDLE) & START) begin
		busy <= 1;
		state <= SET_ADRR;
		address <= ADDRESS;
		character <= CHARACTER;
	end
end

endmodule