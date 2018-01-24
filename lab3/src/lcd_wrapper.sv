module LCD_wrapper(
	output reg [7:0] CHARACTER,
	output reg [7:0] ADDRESS,

	output reg START,
	output CLEAR,
	input BUSY,

	input i_clk,
	input i_rst,
	input [15:0] STATUS,
	input [63:0] TIME
);

enum{
	PLAY,
	S_PLAY,
	PAUSE,
	S_PAUSE,
	STOP,
	S_STOP,
	RECORD,
	S_RECORD,
	IDLE
}states;

localparam REC_NONE = 0;
localparam REC_PLAY = 1;
localparam REC_PAUSE = 2;
localparam REC_STOP = 3;
localparam REC_RECORD = 4;

reg [4:0] state;

reg start;
reg clear;

reg [15:0] mode;
reg [63:0] timeline;

reg [5:0] t_sec;
reg [5:0] c_sec;
reg [3:0] t_min;
reg [5:0] c_min;

reg [63:0] clock_counter;
reg [63:0] last_clock;

reg [7:0] address;

task convert2sec;
	input [31:0] in;
	output [5:0] out;
	begin
		 out = ((in>>15)%60);
	end
endtask

task convert2min;
	input [31:0] in;
	output [3:0] out;
	begin
		 out = (in>>15)/60;
	end
endtask

//localparam total_time = 32'd320000;
wire [31:0] total_time;
assign total_time = timeline[31:0];

always_ff @(posedge i_clk or posedge i_rst) begin
	if (i_rst) begin
		state <= IDLE;
		mode <= 16'b0;
		timeline <= 64'b0;
		start <= 0;
		clear <= 0;
		address <= 8'b0;
		clock_counter <= 64'b0;
		last_clock <= 64'b0;
	end
	else begin
		//convert2min(clock_counter[40:9], c_min);
		//convert2sec(clock_counter[40:9], c_sec);
		//convert2min(total_time, t_min);
		//convert2sec(total_time, t_sec);
		convert2min(timeline[63:32], c_min);
		convert2sec(timeline[63:32], c_sec);
		convert2min(total_time, t_min);
		convert2sec(total_time, t_sec);
		clock_counter <= clock_counter + 1;
		//if ((STATUS == mode) & (TIME == timeline)) begin
		//end
		//else begin
			if (state == IDLE) begin
				mode <= STATUS;
				timeline <= TIME;
				if (STATUS[15:12] == REC_NONE) begin
				end
				else if (STATUS[15:12] == REC_PLAY) begin
					state <= PLAY;
				end
				else if (STATUS[15:12] == REC_PAUSE) begin
					state <= PAUSE;
				end
				else if (STATUS[15:12] == REC_STOP) begin
					state <= STOP;
				end
				else if (STATUS[15:12] == REC_RECORD) begin
					state <= RECORD;
				end
			end
			else if (state == PLAY) begin
				START <= 0;
				last_clock <= clock_counter;
				if (STATUS[15:12] == REC_NONE) begin
					state <= IDLE;
				end
				else if (STATUS[15:12] == REC_PLAY) begin
					state <= S_PLAY;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
				else if (STATUS[15:12] == REC_PAUSE) begin
					state <= S_PAUSE;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
				else if (STATUS[15:12] == REC_STOP) begin
					state <= S_STOP;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
				else if (STATUS[15:12] == REC_RECORD) begin
					state <= S_RECORD;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
			end
			else if (state == S_PLAY) begin
				if (clock_counter > last_clock + 10) begin
					last_clock <= clock_counter;
					case (address)
						8'h00 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h00;
										CHARACTER <= 8'h50; // P
										address <= 8'h01;
									end
									else begin
										START <= 0;
									end
								end
						8'h01 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h01;
										CHARACTER <= 8'h4C; // L
										address <= 8'h02;
									end
									else begin
										START <= 0;
									end
								end
						8'h02 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h02;
										CHARACTER <= 8'h41; // A
										address <= 8'h03;
									end
									else begin
										START <= 0;
									end
								end
						8'h03 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h03;
										CHARACTER <= 8'h59; // Y
										address <= 8'h04;
									end
									else begin
										START <= 0;
									end
								end
						8'h04 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h04;
										CHARACTER <= 8'h20; // _
										address <= 8'h05;
									end
									else begin
										START <= 0;
									end
								end
						8'h05 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h05;
										CHARACTER <= 8'h20; // _
										address <= 8'h07;
									end
									else begin
										START <= 0;
									end
								end				
						8'h07 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h07;
										case (c_min)
											4'b0000 : CHARACTER <= 8'h30; // 0
											4'b0001 : CHARACTER <= 8'h31; // 1
											4'b0010 : CHARACTER <= 8'h32; // 2
											4'b0011 : CHARACTER <= 8'h33; // 3
											4'b0100 : CHARACTER <= 8'h34; // 4
											4'b0101 : CHARACTER <= 8'h35; // 5
											4'b0110 : CHARACTER <= 8'h36; // 6
											4'b0111 : CHARACTER <= 8'h37; // 7
											4'b1000 : CHARACTER <= 8'h38; // 8
											4'b1001 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h08;
									end
									else begin
										START <= 0;
									end
								end
						8'h08 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h08;
										CHARACTER <= 8'h3A; // :
										address <= 8'h09;
									end
									else begin
										START <= 0;
									end
								end
						8'h09 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h09;
										case (c_sec)
											6'd10 ,6'd11 ,6'd12 ,6'd13 ,6'd14 ,6'd15 ,6'd16 ,6'd17 ,6'd18 ,6'd19 : CHARACTER <= 8'h31; // 1
											6'd20 ,6'd21 ,6'd22 ,6'd23 ,6'd24 ,6'd25 ,6'd26 ,6'd27 ,6'd28 ,6'd29 : CHARACTER <= 8'h32; // 2
											6'd30 ,6'd31 ,6'd32 ,6'd33 ,6'd34 ,6'd35 ,6'd36 ,6'd37 ,6'd38 ,6'd39 : CHARACTER <= 8'h33; // 3
											6'd40 ,6'd41 ,6'd42 ,6'd43 ,6'd44 ,6'd45 ,6'd46 ,6'd47 ,6'd48 ,6'd49 : CHARACTER <= 8'h34; // 4
											6'd50 ,6'd51 ,6'd52 ,6'd53 ,6'd54 ,6'd55 ,6'd56 ,6'd57 ,6'd58 ,6'd59 : CHARACTER <= 8'h35; // 5
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0A;
									end
									else begin
										START <= 0;
									end
								end
						8'h0A : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0A;
										case (c_sec)
											6'd0, 6'd10 ,6'd20 ,6'd30 ,6'd40 ,6'd50 : CHARACTER <= 8'h30; // 0
											6'd1, 6'd11 ,6'd21 ,6'd31 ,6'd41 ,6'd51 : CHARACTER <= 8'h31; // 1
											6'd2, 6'd12 ,6'd22 ,6'd32 ,6'd42 ,6'd52 : CHARACTER <= 8'h32; // 2
											6'd3, 6'd13 ,6'd23 ,6'd33 ,6'd43 ,6'd53 : CHARACTER <= 8'h33; // 3
											6'd4, 6'd14 ,6'd24 ,6'd34 ,6'd44 ,6'd54 : CHARACTER <= 8'h34; // 4
											6'd5, 6'd15 ,6'd25 ,6'd35 ,6'd45 ,6'd55 : CHARACTER <= 8'h35; // 5
											6'd6, 6'd16 ,6'd26 ,6'd36 ,6'd46 ,6'd56 : CHARACTER <= 8'h36; // 6
											6'd7, 6'd17 ,6'd27 ,6'd37 ,6'd47 ,6'd57 : CHARACTER <= 8'h37; // 7
											6'd8, 6'd18 ,6'd28 ,6'd38 ,6'd48 ,6'd58 : CHARACTER <= 8'h38; // 8
											6'd9, 6'd19 ,6'd29 ,6'd39 ,6'd49 ,6'd59 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0B;
									end
									else begin
										START <= 0;
									end
								end
						8'h0B : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0B;
										CHARACTER <= 8'h2F; // /
										address <= 8'h0C;
									end
									else begin
										START <= 0;
									end
								end
						8'h0C : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0C;
										case (t_min)
											4'b0000 : CHARACTER <= 8'h30; // 0
											4'b0001 : CHARACTER <= 8'h31; // 1
											4'b0010 : CHARACTER <= 8'h32; // 2
											4'b0011 : CHARACTER <= 8'h33; // 3
											4'b0100 : CHARACTER <= 8'h34; // 4
											4'b0101 : CHARACTER <= 8'h35; // 5
											4'b0110 : CHARACTER <= 8'h36; // 6
											4'b0111 : CHARACTER <= 8'h37; // 7
											4'b1000 : CHARACTER <= 8'h38; // 8
											4'b1001 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0D;
									end
									else begin
										START <= 0;
									end
								end
						8'h0D : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0D;
										CHARACTER <= 8'h3A; // :
										address <= 8'h0E;
									end
									else begin
										START <= 0;
									end
								end
						8'h0E : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0E;
										case (t_sec)
											6'd10 ,6'd11 ,6'd12 ,6'd13 ,6'd14 ,6'd15 ,6'd16 ,6'd17 ,6'd18 ,6'd19 : CHARACTER <= 8'h31; // 1
											6'd20 ,6'd21 ,6'd22 ,6'd23 ,6'd24 ,6'd25 ,6'd26 ,6'd27 ,6'd28 ,6'd29 : CHARACTER <= 8'h32; // 2
											6'd30 ,6'd31 ,6'd32 ,6'd33 ,6'd34 ,6'd35 ,6'd36 ,6'd37 ,6'd38 ,6'd39 : CHARACTER <= 8'h33; // 3
											6'd40 ,6'd41 ,6'd42 ,6'd43 ,6'd44 ,6'd45 ,6'd46 ,6'd47 ,6'd48 ,6'd49 : CHARACTER <= 8'h34; // 4
											6'd50 ,6'd51 ,6'd52 ,6'd53 ,6'd54 ,6'd55 ,6'd56 ,6'd57 ,6'd58 ,6'd59 : CHARACTER <= 8'h35; // 5
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0F;
									end
									else begin
										START <= 0;
									end
								end
						8'h0F : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0F;
										case (t_sec)
											6'd0, 6'd10 ,6'd20 ,6'd30 ,6'd40 ,6'd50 : CHARACTER <= 8'h30; // 0
											6'd1, 6'd11 ,6'd21 ,6'd31 ,6'd41 ,6'd51 : CHARACTER <= 8'h31; // 1
											6'd2, 6'd12 ,6'd22 ,6'd32 ,6'd42 ,6'd52 : CHARACTER <= 8'h32; // 2
											6'd3, 6'd13 ,6'd23 ,6'd33 ,6'd43 ,6'd53 : CHARACTER <= 8'h33; // 3
											6'd4, 6'd14 ,6'd24 ,6'd34 ,6'd44 ,6'd54 : CHARACTER <= 8'h34; // 4
											6'd5, 6'd15 ,6'd25 ,6'd35 ,6'd45 ,6'd55 : CHARACTER <= 8'h35; // 5
											6'd6, 6'd16 ,6'd26 ,6'd36 ,6'd46 ,6'd56 : CHARACTER <= 8'h36; // 6
											6'd7, 6'd17 ,6'd27 ,6'd37 ,6'd47 ,6'd57 : CHARACTER <= 8'h37; // 7
											6'd8, 6'd18 ,6'd28 ,6'd38 ,6'd48 ,6'd58 : CHARACTER <= 8'h38; // 8
											6'd9, 6'd19 ,6'd29 ,6'd39 ,6'd49 ,6'd59 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h40;
									end
									else begin
										START <= 0;
									end
								end
						8'h40 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h40;
										CHARACTER <= mode[5]?8'h31:8'h30; // intepol 0 or 1
										address <= 8'h41;
									end
									else begin
										START <= 0;
									end
								end
						8'h41 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h41;
										CHARACTER <= 8'h69; // i
										address <= 8'h42;
									end
									else begin
										START <= 0;
									end
								end
						8'h42 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h42;
										CHARACTER <= mode[10]?8'h31:8'h20; // 1 or _
										address <= 8'h43;
									end
									else begin
										START <= 0;
									end
								end
						8'h43 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h43;
										CHARACTER <= mode[10]?8'h2F:8'h20; // / or _
										address <= 8'h44;
									end
									else begin
										START <= 0;
									end
								end
						8'h44 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h44;
										if (mode[11:10] == 2'b0) begin
											CHARACTER <= 8'h31; // 1
										end
										else begin
											case (mode[9:6])
												4'b0010 : CHARACTER <= 8'h32; // 2
												4'b0011 : CHARACTER <= 8'h33; // 3
												4'b0100 : CHARACTER <= 8'h34; // 4
												4'b0101 : CHARACTER <= 8'h35; // 5
												4'b0110 : CHARACTER <= 8'h36; // 6
												4'b0111 : CHARACTER <= 8'h37; // 7
												4'b1000 : CHARACTER <= 8'h38; // 8
												default : CHARACTER <= 8'h31; // 1
											endcase
										end
										address <= 8'h45;
									end
									else begin
										START <= 0;
									end
								end
						8'h45 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h45;
										CHARACTER <= 8'h78; // x
										address <= 8'h47;
									end
									else begin
										START <= 0;
									end
								end				
						8'h47 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h47;
										CHARACTER <= 8'h20; // _
										address <= 8'h48;
									end
									else begin
										START <= 0;
									end
								end
						8'h48 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h48;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time/8)?8'hFF:8'h20; // cube
										address <= 8'h49;
									end
									else begin
										START <= 0;
									end
								end
						8'h49 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h49;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time/8*2)?8'hFF:8'h20; // cube
										address <= 8'h4A;
									end
									else begin
										START <= 0;
									end
								end
						8'h4A : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4A;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time/8*3)?8'hFF:8'h20; // cube
										address <= 8'h4B;
									end
									else begin
										START <= 0;
									end
								end
						8'h4B : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4B;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time/8*4)?8'hFF:8'h20; // cube
										address <= 8'h4C;
									end
									else begin
										START <= 0;
									end
								end
						8'h4C : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4C;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time/8*5)?8'hFF:8'h20; // cube
										address <= 8'h4D;
									end
									else begin
										START <= 0;
									end
								end
						8'h4D : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4D;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time/8*6)?8'hFF:8'h20; // cube
										address <= 8'h4E;
									end
									else begin
										START <= 0;
									end
								end
						8'h4E : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4E;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time/8*7)?8'hFF:8'h20; // cube
										address <= 8'h4F;
									end
									else begin
										START <= 0;
									end
								end
						8'h4F : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4F;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time)?8'hFF:8'h20; // cube
										state <= PLAY;
									end
									else begin
										START <= 0;
									end
								end
						default : state <= PLAY;
					endcase
				end
			end
			else if (state == PAUSE) begin
				START <= 0;
				last_clock <= clock_counter;
				if (STATUS[15:12] == REC_NONE) begin
					state <= IDLE;
				end
				else if (STATUS[15:12] == REC_PLAY) begin
					state <= S_PLAY;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
				else if (STATUS[15:12] == REC_PAUSE) begin
					state <= S_PAUSE;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
				else if (STATUS[15:12] == REC_STOP) begin
					state <= S_STOP;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
				else if (STATUS[15:12] == REC_RECORD) begin
					state <= S_RECORD;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
			end
			else if (state == S_PAUSE) begin
				if (clock_counter > last_clock + 10) begin
					last_clock <= clock_counter;
					case (address)
						8'h00 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h00;
										CHARACTER <= 8'h50; // P
										address <= 8'h01;
									end
									else begin
										START <= 0;
									end
								end
						8'h01 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h01;
										CHARACTER <= 8'h41; // A
										address <= 8'h02;
									end
									else begin
										START <= 0;
									end
								end
						8'h02 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h02;
										CHARACTER <= 8'h55; // U
										address <= 8'h03;
									end
									else begin
										START <= 0;
									end
								end
						8'h03 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h03;
										CHARACTER <= 8'h53; // S
										address <= 8'h04;
									end
									else begin
										START <= 0;
									end
								end
						8'h04 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h04;
										CHARACTER <= 8'h45; // E
										address <= 8'h05;
									end
									else begin
										START <= 0;
									end
								end
						8'h05 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h05;
										CHARACTER <= 8'h20; // _
										address <= 8'h07;
									end
									else begin
										START <= 0;
									end
								end				
						8'h07 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h07;
										case (c_min)
											4'b0000 : CHARACTER <= 8'h30; // 0
											4'b0001 : CHARACTER <= 8'h31; // 1
											4'b0010 : CHARACTER <= 8'h32; // 2
											4'b0011 : CHARACTER <= 8'h33; // 3
											4'b0100 : CHARACTER <= 8'h34; // 4
											4'b0101 : CHARACTER <= 8'h35; // 5
											4'b0110 : CHARACTER <= 8'h36; // 6
											4'b0111 : CHARACTER <= 8'h37; // 7
											4'b1000 : CHARACTER <= 8'h38; // 8
											4'b1001 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h08;
									end
									else begin
										START <= 0;
									end
								end
						8'h08 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h08;
										CHARACTER <= 8'h3A; // :
										address <= 8'h09;
									end
									else begin
										START <= 0;
									end
								end
						8'h09 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h09;
										case (c_sec)
											6'd10 ,6'd11 ,6'd12 ,6'd13 ,6'd14 ,6'd15 ,6'd16 ,6'd17 ,6'd18 ,6'd19 : CHARACTER <= 8'h31; // 1
											6'd20 ,6'd21 ,6'd22 ,6'd23 ,6'd24 ,6'd25 ,6'd26 ,6'd27 ,6'd28 ,6'd29 : CHARACTER <= 8'h32; // 2
											6'd30 ,6'd31 ,6'd32 ,6'd33 ,6'd34 ,6'd35 ,6'd36 ,6'd37 ,6'd38 ,6'd39 : CHARACTER <= 8'h33; // 3
											6'd40 ,6'd41 ,6'd42 ,6'd43 ,6'd44 ,6'd45 ,6'd46 ,6'd47 ,6'd48 ,6'd49 : CHARACTER <= 8'h34; // 4
											6'd50 ,6'd51 ,6'd52 ,6'd53 ,6'd54 ,6'd55 ,6'd56 ,6'd57 ,6'd58 ,6'd59 : CHARACTER <= 8'h35; // 5
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0A;
									end
									else begin
										START <= 0;
									end
								end
						8'h0A : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0A;
										case (c_sec)
											6'd0, 6'd10 ,6'd20 ,6'd30 ,6'd40 ,6'd50 : CHARACTER <= 8'h30; // 0
											6'd1, 6'd11 ,6'd21 ,6'd31 ,6'd41 ,6'd51 : CHARACTER <= 8'h31; // 1
											6'd2, 6'd12 ,6'd22 ,6'd32 ,6'd42 ,6'd52 : CHARACTER <= 8'h32; // 2
											6'd3, 6'd13 ,6'd23 ,6'd33 ,6'd43 ,6'd53 : CHARACTER <= 8'h33; // 3
											6'd4, 6'd14 ,6'd24 ,6'd34 ,6'd44 ,6'd54 : CHARACTER <= 8'h34; // 4
											6'd5, 6'd15 ,6'd25 ,6'd35 ,6'd45 ,6'd55 : CHARACTER <= 8'h35; // 5
											6'd6, 6'd16 ,6'd26 ,6'd36 ,6'd46 ,6'd56 : CHARACTER <= 8'h36; // 6
											6'd7, 6'd17 ,6'd27 ,6'd37 ,6'd47 ,6'd57 : CHARACTER <= 8'h37; // 7
											6'd8, 6'd18 ,6'd28 ,6'd38 ,6'd48 ,6'd58 : CHARACTER <= 8'h38; // 8
											6'd9, 6'd19 ,6'd29 ,6'd39 ,6'd49 ,6'd59 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0B;
									end
									else begin
										START <= 0;
									end
								end
						8'h0B : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0B;
										CHARACTER <= 8'h2F; // /
										address <= 8'h0C;
									end
									else begin
										START <= 0;
									end
								end
						8'h0C : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0C;
										case (t_min)
											4'b0000 : CHARACTER <= 8'h30; // 0
											4'b0001 : CHARACTER <= 8'h31; // 1
											4'b0010 : CHARACTER <= 8'h32; // 2
											4'b0011 : CHARACTER <= 8'h33; // 3
											4'b0100 : CHARACTER <= 8'h34; // 4
											4'b0101 : CHARACTER <= 8'h35; // 5
											4'b0110 : CHARACTER <= 8'h36; // 6
											4'b0111 : CHARACTER <= 8'h37; // 7
											4'b1000 : CHARACTER <= 8'h38; // 8
											4'b1001 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0D;
									end
									else begin
										START <= 0;
									end
								end
						8'h0D : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0D;
										CHARACTER <= 8'h3A; // :
										address <= 8'h0E;
									end
									else begin
										START <= 0;
									end
								end
						8'h0E : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0E;
										case (t_sec)
											6'd10 ,6'd11 ,6'd12 ,6'd13 ,6'd14 ,6'd15 ,6'd16 ,6'd17 ,6'd18 ,6'd19 : CHARACTER <= 8'h31; // 1
											6'd20 ,6'd21 ,6'd22 ,6'd23 ,6'd24 ,6'd25 ,6'd26 ,6'd27 ,6'd28 ,6'd29 : CHARACTER <= 8'h32; // 2
											6'd30 ,6'd31 ,6'd32 ,6'd33 ,6'd34 ,6'd35 ,6'd36 ,6'd37 ,6'd38 ,6'd39 : CHARACTER <= 8'h33; // 3
											6'd40 ,6'd41 ,6'd42 ,6'd43 ,6'd44 ,6'd45 ,6'd46 ,6'd47 ,6'd48 ,6'd49 : CHARACTER <= 8'h34; // 4
											6'd50 ,6'd51 ,6'd52 ,6'd53 ,6'd54 ,6'd55 ,6'd56 ,6'd57 ,6'd58 ,6'd59 : CHARACTER <= 8'h35; // 5
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0F;
									end
									else begin
										START <= 0;
									end
								end
						8'h0F : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0F;
										case (t_sec)
											6'd0, 6'd10 ,6'd20 ,6'd30 ,6'd40 ,6'd50 : CHARACTER <= 8'h30; // 0
											6'd1, 6'd11 ,6'd21 ,6'd31 ,6'd41 ,6'd51 : CHARACTER <= 8'h31; // 1
											6'd2, 6'd12 ,6'd22 ,6'd32 ,6'd42 ,6'd52 : CHARACTER <= 8'h32; // 2
											6'd3, 6'd13 ,6'd23 ,6'd33 ,6'd43 ,6'd53 : CHARACTER <= 8'h33; // 3
											6'd4, 6'd14 ,6'd24 ,6'd34 ,6'd44 ,6'd54 : CHARACTER <= 8'h34; // 4
											6'd5, 6'd15 ,6'd25 ,6'd35 ,6'd45 ,6'd55 : CHARACTER <= 8'h35; // 5
											6'd6, 6'd16 ,6'd26 ,6'd36 ,6'd46 ,6'd56 : CHARACTER <= 8'h36; // 6
											6'd7, 6'd17 ,6'd27 ,6'd37 ,6'd47 ,6'd57 : CHARACTER <= 8'h37; // 7
											6'd8, 6'd18 ,6'd28 ,6'd38 ,6'd48 ,6'd58 : CHARACTER <= 8'h38; // 8
											6'd9, 6'd19 ,6'd29 ,6'd39 ,6'd49 ,6'd59 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h40;
									end
									else begin
										START <= 0;
									end
								end
						8'h40 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h40;
										CHARACTER <= mode[5]?8'h31:8'h30; // intepol 0 or 1
										address <= 8'h41;
									end
									else begin
										START <= 0;
									end
								end
						8'h41 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h41;
										CHARACTER <= 8'h69; // i
										address <= 8'h42;
									end
									else begin
										START <= 0;
									end
								end
						8'h42 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h42;
										CHARACTER <= mode[10]?8'h31:8'h20; // 1 or _
										address <= 8'h43;
									end
									else begin
										START <= 0;
									end
								end
						8'h43 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h43;
										CHARACTER <= mode[10]?8'h2F:8'h20; // / or _
										address <= 8'h44;
									end
									else begin
										START <= 0;
									end
								end
						8'h44 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h44;
										if (mode[11:10] == 2'b0) begin
											CHARACTER <= 8'h31; // 1
										end
										else begin
											case (mode[9:6])
												4'b0010 : CHARACTER <= 8'h32; // 2
												4'b0011 : CHARACTER <= 8'h33; // 3
												4'b0100 : CHARACTER <= 8'h34; // 4
												4'b0101 : CHARACTER <= 8'h35; // 5
												4'b0110 : CHARACTER <= 8'h36; // 6
												4'b0111 : CHARACTER <= 8'h37; // 7
												4'b1000 : CHARACTER <= 8'h38; // 8
												default : CHARACTER <= 8'h31; // 1
											endcase
										end
										address <= 8'h45;
									end
									else begin
										START <= 0;
									end
								end
						8'h45 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h45;
										CHARACTER <= 8'h78; // x
										address <= 8'h47;
									end
									else begin
										START <= 0;
									end
								end				
						8'h47 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h47;
										CHARACTER <= 8'h20; // _
										address <= 8'h48;
									end
									else begin
										START <= 0;
									end
								end
						8'h48 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h48;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time/8)?8'hFF:8'h20; // cube
										address <= 8'h49;
									end
									else begin
										START <= 0;
									end
								end
						8'h49 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h49;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time/8*2)?8'hFF:8'h20; // cube
										address <= 8'h4A;
									end
									else begin
										START <= 0;
									end
								end
						8'h4A : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4A;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time/8*3)?8'hFF:8'h20; // cube
										address <= 8'h4B;
									end
									else begin
										START <= 0;
									end
								end
						8'h4B : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4B;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time/8*4)?8'hFF:8'h20; // cube
										address <= 8'h4C;
									end
									else begin
										START <= 0;
									end
								end
						8'h4C : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4C;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time/8*5)?8'hFF:8'h20; // cube
										address <= 8'h4D;
									end
									else begin
										START <= 0;
									end
								end
						8'h4D : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4D;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time/8*6)?8'hFF:8'h20; // cube
										address <= 8'h4E;
									end
									else begin
										START <= 0;
									end
								end
						8'h4E : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4E;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time/8*7)?8'hFF:8'h20; // cube
										address <= 8'h4F;
									end
									else begin
										START <= 0;
									end
								end
						8'h4F : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4F;
										CHARACTER <= (timeline[63:32] + total_time/16 >= total_time)?8'hFF:8'h20; // cube
										state <= PAUSE;
									end
									else begin
										START <= 0;
									end
								end
						default : state <= PAUSE;
					endcase
				end
			end
			else if (state == STOP) begin
				START <= 0;
				last_clock <= clock_counter;
				if (STATUS[15:12] == REC_NONE) begin
					state <= IDLE;
				end
				else if (STATUS[15:12] == REC_PLAY) begin
					state <= S_PLAY;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
				else if (STATUS[15:12] == REC_PAUSE) begin
					state <= S_PAUSE;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
				else if (STATUS[15:12] == REC_STOP) begin
					state <= S_STOP;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
				else if (STATUS[15:12] == REC_RECORD) begin
					state <= S_RECORD;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
			end
			else if (state == S_STOP) begin
				if (clock_counter > last_clock + 10) begin
					last_clock <= clock_counter;
					case (address)
						8'h00 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h00;
										CHARACTER <= 8'h53; // S
										address <= 8'h01;
									end
									else begin
										START <= 0;
									end
								end
						8'h01 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h01;
										CHARACTER <= 8'h54; // T
										address <= 8'h02;
									end
									else begin
										START <= 0;
									end
								end
						8'h02 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h02;
										CHARACTER <= 8'h4F; // O
										address <= 8'h03;
									end
									else begin
										START <= 0;
									end
								end
						8'h03 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h03;
										CHARACTER <= 8'h50; // P
										address <= 8'h04;
									end
									else begin
										START <= 0;
									end
								end
						8'h04 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h04;
										CHARACTER <= 8'h20; // _
										address <= 8'h05;
									end
									else begin
										START <= 0;
									end
								end
						8'h05 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h05;
										CHARACTER <= 8'h20; // _
										address <= 8'h07;
									end
									else begin
										START <= 0;
									end
								end				
						8'h07 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h07;
										case (c_min)
											4'b0000 : CHARACTER <= 8'h30; // 0
											4'b0001 : CHARACTER <= 8'h31; // 1
											4'b0010 : CHARACTER <= 8'h32; // 2
											4'b0011 : CHARACTER <= 8'h33; // 3
											4'b0100 : CHARACTER <= 8'h34; // 4
											4'b0101 : CHARACTER <= 8'h35; // 5
											4'b0110 : CHARACTER <= 8'h36; // 6
											4'b0111 : CHARACTER <= 8'h37; // 7
											4'b1000 : CHARACTER <= 8'h38; // 8
											4'b1001 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h08;
									end
									else begin
										START <= 0;
									end
								end
						8'h08 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h08;
										CHARACTER <= 8'h3A; // :
										address <= 8'h09;
									end
									else begin
										START <= 0;
									end
								end
						8'h09 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h09;
										case (c_sec)
											6'd10 ,6'd11 ,6'd12 ,6'd13 ,6'd14 ,6'd15 ,6'd16 ,6'd17 ,6'd18 ,6'd19 : CHARACTER <= 8'h31; // 1
											6'd20 ,6'd21 ,6'd22 ,6'd23 ,6'd24 ,6'd25 ,6'd26 ,6'd27 ,6'd28 ,6'd29 : CHARACTER <= 8'h32; // 2
											6'd30 ,6'd31 ,6'd32 ,6'd33 ,6'd34 ,6'd35 ,6'd36 ,6'd37 ,6'd38 ,6'd39 : CHARACTER <= 8'h33; // 3
											6'd40 ,6'd41 ,6'd42 ,6'd43 ,6'd44 ,6'd45 ,6'd46 ,6'd47 ,6'd48 ,6'd49 : CHARACTER <= 8'h34; // 4
											6'd50 ,6'd51 ,6'd52 ,6'd53 ,6'd54 ,6'd55 ,6'd56 ,6'd57 ,6'd58 ,6'd59 : CHARACTER <= 8'h35; // 5
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0A;
									end
									else begin
										START <= 0;
									end
								end
						8'h0A : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0A;
										case (c_sec)
											6'd0, 6'd10 ,6'd20 ,6'd30 ,6'd40 ,6'd50 : CHARACTER <= 8'h30; // 0
											6'd1, 6'd11 ,6'd21 ,6'd31 ,6'd41 ,6'd51 : CHARACTER <= 8'h31; // 1
											6'd2, 6'd12 ,6'd22 ,6'd32 ,6'd42 ,6'd52 : CHARACTER <= 8'h32; // 2
											6'd3, 6'd13 ,6'd23 ,6'd33 ,6'd43 ,6'd53 : CHARACTER <= 8'h33; // 3
											6'd4, 6'd14 ,6'd24 ,6'd34 ,6'd44 ,6'd54 : CHARACTER <= 8'h34; // 4
											6'd5, 6'd15 ,6'd25 ,6'd35 ,6'd45 ,6'd55 : CHARACTER <= 8'h35; // 5
											6'd6, 6'd16 ,6'd26 ,6'd36 ,6'd46 ,6'd56 : CHARACTER <= 8'h36; // 6
											6'd7, 6'd17 ,6'd27 ,6'd37 ,6'd47 ,6'd57 : CHARACTER <= 8'h37; // 7
											6'd8, 6'd18 ,6'd28 ,6'd38 ,6'd48 ,6'd58 : CHARACTER <= 8'h38; // 8
											6'd9, 6'd19 ,6'd29 ,6'd39 ,6'd49 ,6'd59 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0B;
									end
									else begin
										START <= 0;
									end
								end
						8'h0B : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0B;
										CHARACTER <= 8'h2F; // /
										address <= 8'h0C;
									end
									else begin
										START <= 0;
									end
								end
						8'h0C : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0C;
										case (t_min)
											4'b0000 : CHARACTER <= 8'h30; // 0
											4'b0001 : CHARACTER <= 8'h31; // 1
											4'b0010 : CHARACTER <= 8'h32; // 2
											4'b0011 : CHARACTER <= 8'h33; // 3
											4'b0100 : CHARACTER <= 8'h34; // 4
											4'b0101 : CHARACTER <= 8'h35; // 5
											4'b0110 : CHARACTER <= 8'h36; // 6
											4'b0111 : CHARACTER <= 8'h37; // 7
											4'b1000 : CHARACTER <= 8'h38; // 8
											4'b1001 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0D;
									end
									else begin
										START <= 0;
									end
								end
						8'h0D : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0D;
										CHARACTER <= 8'h3A; // :
										address <= 8'h0E;
									end
									else begin
										START <= 0;
									end
								end
						8'h0E : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0E;
										case (t_sec)
											6'd10 ,6'd11 ,6'd12 ,6'd13 ,6'd14 ,6'd15 ,6'd16 ,6'd17 ,6'd18 ,6'd19 : CHARACTER <= 8'h31; // 1
											6'd20 ,6'd21 ,6'd22 ,6'd23 ,6'd24 ,6'd25 ,6'd26 ,6'd27 ,6'd28 ,6'd29 : CHARACTER <= 8'h32; // 2
											6'd30 ,6'd31 ,6'd32 ,6'd33 ,6'd34 ,6'd35 ,6'd36 ,6'd37 ,6'd38 ,6'd39 : CHARACTER <= 8'h33; // 3
											6'd40 ,6'd41 ,6'd42 ,6'd43 ,6'd44 ,6'd45 ,6'd46 ,6'd47 ,6'd48 ,6'd49 : CHARACTER <= 8'h34; // 4
											6'd50 ,6'd51 ,6'd52 ,6'd53 ,6'd54 ,6'd55 ,6'd56 ,6'd57 ,6'd58 ,6'd59 : CHARACTER <= 8'h35; // 5
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0F;
									end
									else begin
										START <= 0;
									end
								end
						8'h0F : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0F;
										case (t_sec)
											6'd0, 6'd10 ,6'd20 ,6'd30 ,6'd40 ,6'd50 : CHARACTER <= 8'h30; // 0
											6'd1, 6'd11 ,6'd21 ,6'd31 ,6'd41 ,6'd51 : CHARACTER <= 8'h31; // 1
											6'd2, 6'd12 ,6'd22 ,6'd32 ,6'd42 ,6'd52 : CHARACTER <= 8'h32; // 2
											6'd3, 6'd13 ,6'd23 ,6'd33 ,6'd43 ,6'd53 : CHARACTER <= 8'h33; // 3
											6'd4, 6'd14 ,6'd24 ,6'd34 ,6'd44 ,6'd54 : CHARACTER <= 8'h34; // 4
											6'd5, 6'd15 ,6'd25 ,6'd35 ,6'd45 ,6'd55 : CHARACTER <= 8'h35; // 5
											6'd6, 6'd16 ,6'd26 ,6'd36 ,6'd46 ,6'd56 : CHARACTER <= 8'h36; // 6
											6'd7, 6'd17 ,6'd27 ,6'd37 ,6'd47 ,6'd57 : CHARACTER <= 8'h37; // 7
											6'd8, 6'd18 ,6'd28 ,6'd38 ,6'd48 ,6'd58 : CHARACTER <= 8'h38; // 8
											6'd9, 6'd19 ,6'd29 ,6'd39 ,6'd49 ,6'd59 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h40;
									end
									else begin
										START <= 0;
									end
								end
						8'h40 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h40;
										CHARACTER <= mode[5]?8'h31:8'h30; // intepol 0 or 1
										address <= 8'h41;
									end
									else begin
										START <= 0;
									end
								end
						8'h41 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h41;
										CHARACTER <= 8'h69; // i
										address <= 8'h42;
									end
									else begin
										START <= 0;
									end
								end
						8'h42 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h42;
										CHARACTER <= mode[10]?8'h31:8'h20; // 1 or _
										address <= 8'h43;
									end
									else begin
										START <= 0;
									end
								end
						8'h43 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h43;
										CHARACTER <= mode[10]?8'h2F:8'h20; // / or _
										address <= 8'h44;
									end
									else begin
										START <= 0;
									end
								end
						8'h44 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h44;
										if (mode[11:10] == 2'b0) begin
											CHARACTER <= 8'h31; // 1
										end
										else begin
											case (mode[9:6])
												4'b0010 : CHARACTER <= 8'h32; // 2
												4'b0011 : CHARACTER <= 8'h33; // 3
												4'b0100 : CHARACTER <= 8'h34; // 4
												4'b0101 : CHARACTER <= 8'h35; // 5
												4'b0110 : CHARACTER <= 8'h36; // 6
												4'b0111 : CHARACTER <= 8'h37; // 7
												4'b1000 : CHARACTER <= 8'h38; // 8
												default : CHARACTER <= 8'h31; // 1
											endcase
										end
										address <= 8'h45;
									end
									else begin
										START <= 0;
									end
								end
						8'h45 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h45;
										CHARACTER <= 8'h78; // x
										address <= 8'h47;
									end
									else begin
										START <= 0;
									end
								end				
						8'h47 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h47;
										CHARACTER <= 8'h20; // _
										address <= 8'h48;
									end
									else begin
										START <= 0;
									end
								end
						8'h48 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h48;
										CHARACTER <= 8'hFF; // cube
										address <= 8'h49;
									end
									else begin
										START <= 0;
									end
								end
						8'h49 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h49;
										CHARACTER <= 8'hFF; // cube
										address <= 8'h4A;
									end
									else begin
										START <= 0;
									end
								end
						8'h4A : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4A;
										CHARACTER <= 8'hFF; // cube
										address <= 8'h4B;
									end
									else begin
										START <= 0;
									end
								end
						8'h4B : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4B;
										CHARACTER <= 8'hFF; // cube
										address <= 8'h4C;
									end
									else begin
										START <= 0;
									end
								end
						8'h4C : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4C;
										CHARACTER <= 8'hFF; // cube
										address <= 8'h4D;
									end
									else begin
										START <= 0;
									end
								end
						8'h4D : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4D;
										CHARACTER <= 8'hFF; // cube
										address <= 8'h4E;
									end
									else begin
										START <= 0;
									end
								end
						8'h4E : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4E;
										CHARACTER <= 8'hFF; // cube
										address <= 8'h4F;
									end
									else begin
										START <= 0;
									end
								end
						8'h4F : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4F;
										CHARACTER <= 8'hFF; // cube
										state <= STOP;
									end
									else begin
										START <= 0;
									end
								end
						default : state <= STOP;
					endcase
				end
			end
			else if (state == RECORD) begin
				START <= 0;
				last_clock <= clock_counter;
				if (STATUS[15:12] == REC_NONE) begin
					state <= IDLE;
				end
				else if (STATUS[15:12] == REC_PLAY) begin
					state <= S_PLAY;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
				else if (STATUS[15:12] == REC_PAUSE) begin
					state <= S_PAUSE;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
				else if (STATUS[15:12] == REC_STOP) begin
					state <= S_STOP;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
				else if (STATUS[15:12] == REC_RECORD) begin
					state <= S_RECORD;
					mode <= STATUS;
					timeline <= TIME;
					address <= 8'h0;
				end
			end
			else if (state == S_RECORD) begin
				if (clock_counter > last_clock + 10) begin
					last_clock <= clock_counter;
					case (address)
						8'h00 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h00;
										CHARACTER <= 8'h52; // R
										address <= 8'h01;
									end
									else begin
										START <= 0;
									end
								end
						8'h01 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h01;
										CHARACTER <= 8'h45; // E
										address <= 8'h02;
									end
									else begin
										START <= 0;
									end
								end
						8'h02 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h02;
										CHARACTER <= 8'h43; // C
										address <= 8'h03;
									end
									else begin
										START <= 0;
									end
								end
						8'h03 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h03;
										CHARACTER <= 8'h4F; // O
										address <= 8'h04;
									end
									else begin
										START <= 0;
									end
								end
						8'h04 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h04;
										CHARACTER <= 8'h52; // R
										address <= 8'h05;
									end
									else begin
										START <= 0;
									end
								end
						8'h05 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h05;
										CHARACTER <= 8'h44; // D
										address <= 8'h07;
									end
									else begin
										START <= 0;
									end
								end				
						8'h07 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h07;
										case (c_min)
											4'b0000 : CHARACTER <= 8'h30; // 0
											4'b0001 : CHARACTER <= 8'h31; // 1
											4'b0010 : CHARACTER <= 8'h32; // 2
											4'b0011 : CHARACTER <= 8'h33; // 3
											4'b0100 : CHARACTER <= 8'h34; // 4
											4'b0101 : CHARACTER <= 8'h35; // 5
											4'b0110 : CHARACTER <= 8'h36; // 6
											4'b0111 : CHARACTER <= 8'h37; // 7
											4'b1000 : CHARACTER <= 8'h38; // 8
											4'b1001 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h08;
									end
									else begin
										START <= 0;
									end
								end
						8'h08 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h08;
										CHARACTER <= 8'h3A; // :
										address <= 8'h09;
									end
									else begin
										START <= 0;
									end
								end
						8'h09 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h09;
										case (c_sec)
											6'd10 ,6'd11 ,6'd12 ,6'd13 ,6'd14 ,6'd15 ,6'd16 ,6'd17 ,6'd18 ,6'd19 : CHARACTER <= 8'h31; // 1
											6'd20 ,6'd21 ,6'd22 ,6'd23 ,6'd24 ,6'd25 ,6'd26 ,6'd27 ,6'd28 ,6'd29 : CHARACTER <= 8'h32; // 2
											6'd30 ,6'd31 ,6'd32 ,6'd33 ,6'd34 ,6'd35 ,6'd36 ,6'd37 ,6'd38 ,6'd39 : CHARACTER <= 8'h33; // 3
											6'd40 ,6'd41 ,6'd42 ,6'd43 ,6'd44 ,6'd45 ,6'd46 ,6'd47 ,6'd48 ,6'd49 : CHARACTER <= 8'h34; // 4
											6'd50 ,6'd51 ,6'd52 ,6'd53 ,6'd54 ,6'd55 ,6'd56 ,6'd57 ,6'd58 ,6'd59 : CHARACTER <= 8'h35; // 5
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0A;
									end
									else begin
										START <= 0;
									end
								end
						8'h0A : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0A;
										case (c_sec)
											6'd0, 6'd10 ,6'd20 ,6'd30 ,6'd40 ,6'd50 : CHARACTER <= 8'h30; // 0
											6'd1, 6'd11 ,6'd21 ,6'd31 ,6'd41 ,6'd51 : CHARACTER <= 8'h31; // 1
											6'd2, 6'd12 ,6'd22 ,6'd32 ,6'd42 ,6'd52 : CHARACTER <= 8'h32; // 2
											6'd3, 6'd13 ,6'd23 ,6'd33 ,6'd43 ,6'd53 : CHARACTER <= 8'h33; // 3
											6'd4, 6'd14 ,6'd24 ,6'd34 ,6'd44 ,6'd54 : CHARACTER <= 8'h34; // 4
											6'd5, 6'd15 ,6'd25 ,6'd35 ,6'd45 ,6'd55 : CHARACTER <= 8'h35; // 5
											6'd6, 6'd16 ,6'd26 ,6'd36 ,6'd46 ,6'd56 : CHARACTER <= 8'h36; // 6
											6'd7, 6'd17 ,6'd27 ,6'd37 ,6'd47 ,6'd57 : CHARACTER <= 8'h37; // 7
											6'd8, 6'd18 ,6'd28 ,6'd38 ,6'd48 ,6'd58 : CHARACTER <= 8'h38; // 8
											6'd9, 6'd19 ,6'd29 ,6'd39 ,6'd49 ,6'd59 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0B;
									end
									else begin
										START <= 0;
									end
								end
						8'h0B : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0B;
										CHARACTER <= 8'h2F; // /
										address <= 8'h0C;
									end
									else begin
										START <= 0;
									end
								end
						8'h0C : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0C;
										case (t_min)
											4'b0000 : CHARACTER <= 8'h30; // 0
											4'b0001 : CHARACTER <= 8'h31; // 1
											4'b0010 : CHARACTER <= 8'h32; // 2
											4'b0011 : CHARACTER <= 8'h33; // 3
											4'b0100 : CHARACTER <= 8'h34; // 4
											4'b0101 : CHARACTER <= 8'h35; // 5
											4'b0110 : CHARACTER <= 8'h36; // 6
											4'b0111 : CHARACTER <= 8'h37; // 7
											4'b1000 : CHARACTER <= 8'h38; // 8
											4'b1001 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0D;
									end
									else begin
										START <= 0;
									end
								end
						8'h0D : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0D;
										CHARACTER <= 8'h3A; // :
										address <= 8'h0E;
									end
									else begin
										START <= 0;
									end
								end
						8'h0E : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0E;
										case (t_sec)
											6'd10 ,6'd11 ,6'd12 ,6'd13 ,6'd14 ,6'd15 ,6'd16 ,6'd17 ,6'd18 ,6'd19 : CHARACTER <= 8'h31; // 1
											6'd20 ,6'd21 ,6'd22 ,6'd23 ,6'd24 ,6'd25 ,6'd26 ,6'd27 ,6'd28 ,6'd29 : CHARACTER <= 8'h32; // 2
											6'd30 ,6'd31 ,6'd32 ,6'd33 ,6'd34 ,6'd35 ,6'd36 ,6'd37 ,6'd38 ,6'd39 : CHARACTER <= 8'h33; // 3
											6'd40 ,6'd41 ,6'd42 ,6'd43 ,6'd44 ,6'd45 ,6'd46 ,6'd47 ,6'd48 ,6'd49 : CHARACTER <= 8'h34; // 4
											6'd50 ,6'd51 ,6'd52 ,6'd53 ,6'd54 ,6'd55 ,6'd56 ,6'd57 ,6'd58 ,6'd59 : CHARACTER <= 8'h35; // 5
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h0F;
									end
									else begin
										START <= 0;
									end
								end
						8'h0F : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h0F;
										case (t_sec)
											6'd0, 6'd10 ,6'd20 ,6'd30 ,6'd40 ,6'd50 : CHARACTER <= 8'h30; // 0
											6'd1, 6'd11 ,6'd21 ,6'd31 ,6'd41 ,6'd51 : CHARACTER <= 8'h31; // 1
											6'd2, 6'd12 ,6'd22 ,6'd32 ,6'd42 ,6'd52 : CHARACTER <= 8'h32; // 2
											6'd3, 6'd13 ,6'd23 ,6'd33 ,6'd43 ,6'd53 : CHARACTER <= 8'h33; // 3
											6'd4, 6'd14 ,6'd24 ,6'd34 ,6'd44 ,6'd54 : CHARACTER <= 8'h34; // 4
											6'd5, 6'd15 ,6'd25 ,6'd35 ,6'd45 ,6'd55 : CHARACTER <= 8'h35; // 5
											6'd6, 6'd16 ,6'd26 ,6'd36 ,6'd46 ,6'd56 : CHARACTER <= 8'h36; // 6
											6'd7, 6'd17 ,6'd27 ,6'd37 ,6'd47 ,6'd57 : CHARACTER <= 8'h37; // 7
											6'd8, 6'd18 ,6'd28 ,6'd38 ,6'd48 ,6'd58 : CHARACTER <= 8'h38; // 8
											6'd9, 6'd19 ,6'd29 ,6'd39 ,6'd49 ,6'd59 : CHARACTER <= 8'h39; // 9
											default : CHARACTER <= 8'h30; // 0
										endcase
										address <= 8'h40;
									end
									else begin
										START <= 0;
									end
								end
						8'h40 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h40;
										CHARACTER <= mode[5]?8'h31:8'h30; // intepol 0 or 1
										address <= 8'h41;
									end
									else begin
										START <= 0;
									end
								end
						8'h41 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h41;
										CHARACTER <= 8'h69; // i
										address <= 8'h42;
									end
									else begin
										START <= 0;
									end
								end
						8'h42 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h42;
										CHARACTER <= mode[10]?8'h31:8'h20; // 1 or _
										address <= 8'h43;
									end
									else begin
										START <= 0;
									end
								end
						8'h43 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h43;
										CHARACTER <= mode[10]?8'h2F:8'h20; // / or _
										address <= 8'h44;
									end
									else begin
										START <= 0;
									end
								end
						8'h44 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h44;
										if (mode[11:10] == 2'b0) begin
											CHARACTER <= 8'h31; // 1
										end
										else begin
											case (mode[9:6])
												4'b0010 : CHARACTER <= 8'h32; // 2
												4'b0011 : CHARACTER <= 8'h33; // 3
												4'b0100 : CHARACTER <= 8'h34; // 4
												4'b0101 : CHARACTER <= 8'h35; // 5
												4'b0110 : CHARACTER <= 8'h36; // 6
												4'b0111 : CHARACTER <= 8'h37; // 7
												4'b1000 : CHARACTER <= 8'h38; // 8
												default : CHARACTER <= 8'h31; // 1
											endcase
										end
										address <= 8'h45;
									end
									else begin
										START <= 0;
									end
								end
						8'h45 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h45;
										CHARACTER <= 8'h78; // x
										address <= 8'h47;
									end
									else begin
										START <= 0;
									end
								end				
						8'h47 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h47;
										CHARACTER <= 8'h20; // _
										address <= 8'h48;
									end
									else begin
										START <= 0;
									end
								end
						8'h48 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h48;
										CHARACTER <= 8'hFF; // cube
										address <= 8'h49;
									end
									else begin
										START <= 0;
									end
								end
						8'h49 : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h49;
										CHARACTER <= 8'hFF; // cube
										address <= 8'h4A;
									end
									else begin
										START <= 0;
									end
								end
						8'h4A : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4A;
										CHARACTER <= 8'hFF; // cube
										address <= 8'h4B;
									end
									else begin
										START <= 0;
									end
								end
						8'h4B : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4B;
										CHARACTER <= 8'hFF; // cube
										address <= 8'h4C;
									end
									else begin
										START <= 0;
									end
								end
						8'h4C : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4C;
										CHARACTER <= 8'hFF; // cube
										address <= 8'h4D;
									end
									else begin
										START <= 0;
									end
								end
						8'h4D : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4D;
										CHARACTER <= 8'hFF; // cube
										address <= 8'h4E;
									end
									else begin
										START <= 0;
									end
								end
						8'h4E : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4E;
										CHARACTER <= 8'hFF; // cube
										address <= 8'h4F;
									end
									else begin
										START <= 0;
									end
								end
						8'h4F : begin
									if (!BUSY) begin
										START <= 1;
										ADDRESS <= 8'h4F;
										CHARACTER <= 8'hFF; // cube
										state <= RECORD;
									end
									else begin
										START <= 0;
									end
								end
						default : state <= RECORD;
					endcase
				end
			end
		//end
	end
end

endmodule