`ifndef QUARTUS_II
    `include "include/RSADefine.sv"
`else 
    `include "../include/RSADefine.sv"
`endif

module RSACore(
    input [RSA_MAX_LOG2:0] i_RSA_BIT,
    input i_clk,
    input i_rst,
    input i_start,
    input [RSA_BUS:0] i_a,
    input [RSA_BUS:0] i_e,
    input [RSA_BUS:0] i_n,
    output [RSA_BUS:0] o_a_pow_e,
    output o_finished
);
    localparam S_WAIT = 0;
    localparam S_PRE = 1;
    localparam S_POW = 2;
    logic [1:0] STATE;

    logic r_finished;
    logic r_pre_start, r_pow_start;
    logic w_pre_finished, w_pow_finished;
    logic [RSA_BUS:0] r_a, r_e, r_n;
    logic [RSA_BUS:0] r_a_2_BIT, w_a_2_BIT;
    logic [RSA_BUS:0] r_a_pow_e, w_a_pow_e;

    assign o_finished = r_finished;
    assign o_a_pow_e = r_a_pow_e;
    
    Pre pre(
        .i_RSA_BIT(i_RSA_BIT),
        .i_clk(i_clk),
        .i_start(r_pre_start),
        .i_rst(i_rst),
        .i_y(r_a),
        .i_n(r_n),
        .o_y_2_BIT(w_a_2_BIT),
        .o_finished(w_pre_finished)
    );
    
    Pow pow(
        .i_RSA_BIT(i_RSA_BIT),
        .i_clk(i_clk),
        .i_start(r_pow_start),
        .i_rst(i_rst),
        .i_y(r_a_2_BIT),
        .i_d(r_e),
        .i_n(r_n),
        .o_y_pow_d(w_a_pow_e),
        .o_finished(w_pow_finished)
    );

    always_ff @(posedge i_clk) begin
        if(i_rst) begin
            STATE <= S_WAIT;
            r_finished <= 0;
            r_pre_start <= 0;
            r_pow_start <= 0;
        end
        else if(STATE == S_WAIT) begin
            r_finished <= 0;
            if(i_start) begin
                r_pre_start <= 1;
                r_a <= i_a;
                r_e <= i_e;
                r_n <= i_n;
                STATE <= S_PRE;
            end
        end
        else if(STATE == S_PRE) begin
            r_pre_start <= 0;
            if(w_pre_finished) begin
                r_a_2_BIT <= w_a_2_BIT;
                r_pow_start <= 1;
                STATE <= S_POW;
            end
        end
        else if(STATE == S_POW) begin
            r_pow_start <= 0;
            if(w_pow_finished) begin
                r_a_pow_e <= w_a_pow_e;
                r_finished <= 1;
                STATE <= S_WAIT;
            end
        end
    end
endmodule

//- Pow -----------------------------------------------------------------
module Pow(
    input [RSA_MAX_LOG2:0] i_RSA_BIT,
    input i_clk,
    input i_start,
    input i_rst,
    input [RSA_BUS:0] i_y,
    input [RSA_BUS:0] i_d,
    input [RSA_BUS:0] i_n,
    output [RSA_BUS:0] o_y_pow_d, // (y*2^-BIT)^d mod n
    output o_finished
);
    localparam S_WAIT = 0;
    localparam S_POW = 1;
    localparam S_MUL = 2;
    logic [1:0] STATE;

    logic r_finished;
    logic [RSA_BUS+1:0] r_d;
    logic [RSA_BUS:0] r_x, r_y;
    logic [RSA_BUS:0] r_x_mul_y, w_x_mul_y;
    logic [RSA_BUS:0] r_y_mul_y, w_y_mul_y;
    logic [RSA_MAX_LOG2:0] r_counter;
    logic r_mul_start;
    logic r_x_mul_y_fin, w_x_mul_y_fin;
    logic r_y_mul_y_fin, w_y_mul_y_fin;

    assign o_finished = r_finished;
    assign o_y_pow_d = r_x;

    Mul x_mul_y(
        .i_RSA_BIT(i_RSA_BIT),
        .i_clk(i_clk),
        .i_start(r_mul_start),
        .i_rst(i_rst),
        .i_x(r_x),
        .i_y(r_y),
        .i_n(i_n),
        .o_x_mul_y(w_x_mul_y),
        .o_finished(w_x_mul_y_fin)
    );
    Mul y_mul_y(
        .i_RSA_BIT(i_RSA_BIT),
        .i_clk(i_clk),
        .i_start(r_mul_start),
        .i_rst(i_rst),
        .i_x(r_y),
        .i_y(r_y),
        .i_n(i_n),
        .o_x_mul_y(w_y_mul_y),
        .o_finished(w_y_mul_y_fin)
    );

    always_ff @(posedge i_clk) begin
        if(i_rst) begin
            r_finished <= 0;
            r_mul_start <= 0;
            STATE <= S_WAIT;
        end
        else if(STATE == S_WAIT) begin
            r_finished <= 0;
            if(i_start) begin
                r_d <= i_d[RSA_BUS:0]<<1; // REMEMBER THIS FUCKING SHIFT.
                r_x <= 1;
                r_y <= i_y;
                r_counter <= i_RSA_BIT+1;
                // BUG: counter <= i_RSA_BIT; THIS IS A BUG BECAUSE THAT FUCKING SHIFT.
                STATE <= S_POW;
            end
        end
        else if(STATE == S_POW) begin
            if(r_d[0]) begin
                r_x <= r_x_mul_y;
            end
            if(r_counter) begin
                r_d <= r_d>>1;
                r_counter <= r_counter-1;

                r_mul_start <= 1;
                r_x_mul_y_fin <= 0;
                r_y_mul_y_fin <= 0;
                STATE <= S_MUL;
            end
            else begin
                r_finished <= 1;
                STATE <= S_WAIT;
            end
        end
        else if(STATE == S_MUL) begin
            r_mul_start <= 0;
            if(r_x_mul_y_fin && r_y_mul_y_fin) begin
                STATE <= S_POW;
            end
            else begin
                if(w_x_mul_y_fin) begin
                    r_x_mul_y <= w_x_mul_y;
                end
                if(w_y_mul_y_fin) begin
                    r_y <= w_y_mul_y;
                end
                r_x_mul_y_fin <= r_x_mul_y_fin | w_x_mul_y_fin;
                r_y_mul_y_fin <= r_x_mul_y_fin | w_x_mul_y_fin;
            end
        end
    end
endmodule

//- Pre -----------------------------------------------------------------
module Pre(
    input [RSA_MAX_LOG2:0] i_RSA_BIT,
    input i_clk,
    input i_start,
    input i_rst,
    input [RSA_BUS:0] i_y,
    input [RSA_BUS:0] i_n,
    output [RSA_BUS:0] o_y_2_BIT, // y * 2^BIT mod n
    output o_finished
);
    localparam S_WAIT = 0;
    localparam S_CALC = 1;
    logic STATE;

    logic r_finished;
    logic [RSA_BUS+2:0] r_ret, w_ret_mul_2;
    logic [RSA_MAX_LOG2:0] r_counter;

    assign o_finished = r_finished;
    assign o_y_2_BIT = r_ret[RSA_BUS:0];

    assign w_ret_mul_2 = r_ret<<1;

    always_ff @(posedge i_clk) begin
        if(i_rst) begin
            r_finished <= 0;
            STATE <= S_WAIT;
        end
        else if(STATE == S_WAIT) begin
            r_finished <= 0;
            if(i_start) begin
                r_ret <= i_y;
                r_counter <= i_RSA_BIT;
                STATE <= S_CALC;
            end
        end
        else if(STATE == S_CALC) begin
            if(r_counter) begin
                if(w_ret_mul_2 >= i_n) begin
                    r_ret <= w_ret_mul_2-i_n;
                end
                else begin
                    r_ret <= w_ret_mul_2;
                end
                r_counter <= r_counter-1;
            end
            else begin
                r_finished <= 1;
                STATE <= S_WAIT;
            end
        end
    end
endmodule

//- Mul -----------------------------------------------------------------
module Mul(
    input [RSA_MAX_LOG2:0] i_RSA_BIT,
    input i_clk,
    input i_start,
    input i_rst,
    input [RSA_BUS:0] i_x,
    input [RSA_BUS:0] i_y,
    input [RSA_BUS:0] i_n,
    output [RSA_BUS:0] o_x_mul_y, // xy * 2^-BIT mod n
    output o_finished
);
    localparam S_WAIT = 0;
    localparam S_CALC = 1;
    logic STATE;

    logic r_finished;
    logic [RSA_BUS+2:0] r_ret, r_x, r_y, r_n;
    logic [RSA_MAX_LOG2:0] r_counter;

    assign o_finished = r_finished;
    assign o_x_mul_y = r_ret[RSA_BUS:0];

    always_ff @(posedge i_clk) begin
        if(i_rst) begin
            r_finished <= 0;
            STATE <= S_WAIT;
        end
        else if(STATE == S_WAIT) begin
            r_finished <= 0;
            if(i_start) begin
                r_ret <= 0;
                r_x <= i_x;
                r_y <= i_y;
                r_n <= i_n;
                r_counter <= i_RSA_BIT;
                STATE <= S_CALC;
            end
        end
        else if(STATE == S_CALC) begin
            if(r_counter) begin
                if(r_y[0] && ((r_ret+r_x)&1)) begin
                    r_ret <= (r_ret+r_x+r_n)>>1;
                end
                else if(r_y[0]) begin
                    r_ret <= (r_ret+r_x)>>1;
                end
                else if(r_ret[0]) begin
                    r_ret <= (r_ret+r_n)>>1;
                end
                else begin
                    r_ret <= r_ret>>1;
                end
                r_y <= r_y>>1;
                r_counter <= r_counter-1;
            end
            else begin
                r_finished <= 1;
                if(r_ret >= r_n) begin
                    r_ret <= r_ret - r_n;
                end
                STATE <= S_WAIT;
            end
        end
        else begin
        end
    end

endmodule