`include "../include/RSADefine.sv"

module RSAController (
    input [4:0] i_sw_bits,
    output [RSA_MAX_LOG2:0] o_bits
);
    assign o_bits = i_sw_bits<<7;

endmodule
