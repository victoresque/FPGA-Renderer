module RSADisplay(
	input [4:0] i_sw_bits,
	output [6:0] o_HEX0,
	output [6:0] o_HEX1,
	output [6:0] o_HEX2,
	output [6:0] o_HEX3
);
	/* The layout of seven segment display, 1: dark
	 *    00
	 *   5  1
	 *    66
	 *   4  2
	 *    33
	 */
	parameter D0 = 7'b1000000;
	parameter D1 = 7'b1111001;
	parameter D2 = 7'b0100100;
	parameter D3 = 7'b0110000;
	parameter D4 = 7'b0011001;
	parameter D5 = 7'b0010010;
	parameter D6 = 7'b0000010;
	parameter D7 = 7'b1011000;
	parameter D8 = 7'b0000000;
	parameter D9 = 7'b0010000;
	parameter DN = 7'b1111111;
	parameter D_ = 7'b0111111;

	always_comb begin
		case(i_sw_bits)
			5'b10000: begin o_HEX3=D2; o_HEX2=D0; o_HEX1=D4; o_HEX0=D8; end
			5'b01000: begin o_HEX3=D1; o_HEX2=D0; o_HEX1=D2; o_HEX0=D4; end
			5'b00100: begin o_HEX3=DN; o_HEX2=D5; o_HEX1=D1; o_HEX0=D2; end
			5'b00010: begin o_HEX3=DN; o_HEX2=D2; o_HEX1=D5; o_HEX0=D6; end
			5'b00001: begin o_HEX3=DN; o_HEX2=D1; o_HEX1=D2; o_HEX0=D8; end
			default:  begin o_HEX3=D_; o_HEX2=D_; o_HEX1=D_; o_HEX0=D_; end
		endcase
	end
endmodule
