
module AudioCoreInterpolation(
    input   [15:0]  i_data_prev,
    input   [15:0]  i_data,
    input   [3:0]   i_divisor,
    output  [15:0]  o_quotient
);
    wire [15:0] C, D, _C;
    assign C = i_data + 16'b1 + ~i_data_prev;
    assign _C = 16'b1 + ~C;
    
    /*  x/1  = x
        x/2  = x>>1
        x/3 ~= x>>2 + x>>4 + x>>6
        x/4  = x>>2
        x/5 ~= x>>3 + x>>4 + x>>6
        x/6 ~= x>>3 + x>>5 + x>>7
        x/7 ~= x>>3 + x>>6 + x>>9
        x/8  = x>>3*/
    
    always_comb begin
        case (i_divisor)
            4'd2:    begin o_quotient = C[15]?(16'b1+~(_C>>1)):(C>>1); end
            4'd3:    begin o_quotient = C[15]?(16'b1+~((_C>>2)+(_C>>4)+(_C>>6))):((C>>2)+(C>>4)+(C>>6)); end
            4'd4:    begin o_quotient = C[15]?(16'b1+~(_C>>2)):(C>>2); end
            4'd5:    begin o_quotient = C[15]?(16'b1+~((_C>>3)+(_C>>4)+(_C>>6))):((C>>3)+(C>>4)+(C>>6)); end
            4'd6:    begin o_quotient = C[15]?(16'b1+~((_C>>3)+(_C>>5)+(_C>>7))):((C>>3)+(C>>5)+(C>>7)); end
            4'd7:    begin o_quotient = C[15]?(16'b1+~((_C>>3)+(_C>>6)+(_C>>9))):((C>>3)+(C>>6)+(C>>9)); end
            4'd8:    begin o_quotient = C[15]?(16'b1+~(_C>>3)):(C>>3); end
            default: begin o_quotient = 0; end
        endcase
    end
    
endmodule