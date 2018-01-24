`include "../include/RSADefine.sv"

module RSAWrapper(
    input [RSA_MAX_LOG2:0] i_RSA_BIT,
    output LED_ready,
    input avm_rst,
    input avm_clk,
    output [4:0] avm_address,
    output avm_read,
    input [31:0] avm_readdata,
    output avm_write,
    output [31:0] avm_writedata,
    input avm_waitrequest
);

    localparam RX_BASE     = 0*4;
    localparam TX_BASE     = 1*4;
    localparam STATUS_BASE = 2*4;
    localparam TX_OK_BIT = 6;
    localparam RX_OK_BIT = 7;

    localparam S_GET_KEY = 0;
    localparam S_GET_DATA = 1;
    localparam S_GET_ESC = 2;
    localparam S_WAIT_CALC = 3;
    localparam S_SEND_DATA = 4;
    logic [2:0] STATE;

    localparam RSA_ESC = 0;
    localparam RSA_ESC_END = 1;

    logic r_rsa_start;
    logic [RSA_BUS:0] r_enc, w_enc_next, r_e, r_n;
    assign w_enc_next = (r_enc<<8)|avm_readdata[7:0];

    logic [RSA_BUS:0] w_dec, r_dec, w_rsa_finished;

    logic [4:0] r_avm_address, w_avm_address;
    logic [RSA_MAX_LOG2:0] r_bytes_counter;
    logic r_avm_read, w_avm_read, r_avm_write, w_avm_write;
    
    logic [RSA_MAX_LOG2:0] RSA_CHUNK;
    assign RSA_CHUNK = i_RSA_BIT>>3;

    assign avm_address = r_avm_address;
    assign avm_read = r_avm_read;
    assign avm_write = r_avm_write;
    ///
    logic [7:0] r_avm_writedata;
    assign avm_writedata = r_avm_writedata;
    ///

    logic r_LED_ready;
    assign LED_ready = r_LED_ready;


    RSACore rsa_core(
        .i_RSA_BIT(i_RSA_BIT),
        .i_clk(avm_clk),
        .i_rst(avm_rst),
        .i_start(r_rsa_start),
        .i_a(r_enc),
        .i_e(r_e),
        .i_n(r_n),
        .o_a_pow_e(w_dec),
        .o_finished(w_rsa_finished)
    );

    task StartRead;
        input [4:0] addr;
        begin
            r_avm_read <= 1;
            r_avm_write <= 0;
            r_avm_address <= addr;
        end
    endtask
    task StartWrite;
        input [4:0] addr;
        begin
            r_avm_read <= 0;
            r_avm_write <= 1;
            r_avm_address <= addr;
            case(i_RSA_BIT)
                128:  begin r_avm_writedata <= r_dec[119-:8];  end
                256:  begin r_avm_writedata <= r_dec[247-:8];  end
                512:  begin r_avm_writedata <= r_dec[503-:8];  end
                1024: begin r_avm_writedata <= r_dec[1015-:8]; end
                default: begin r_avm_writedata <= r_dec[119-:8]; end
            endcase
        end
    endtask
    task Reset;
        begin
            r_n <= 0;
            r_e <= 0;
            r_enc <= 0;
            r_dec <= 0;
            StartRead(STATUS_BASE);
            STATE <= S_GET_KEY;
            r_bytes_counter <= 0;
            r_rsa_start <= 0;
            r_LED_ready <= 1;
        end
    endtask

    always_comb begin
    end

    always_ff @(posedge avm_clk or posedge avm_rst) begin
        if (avm_rst) begin
            Reset();
        end
        else begin
            if(STATE == S_GET_KEY && !avm_waitrequest) begin
                r_LED_ready <= 1;

                if(r_avm_address == STATUS_BASE) begin
                    if (avm_readdata[RX_OK_BIT]) begin
                        StartRead(RX_BASE);
                    end
                end
                else if(r_avm_address == RX_BASE) begin
                    if(r_bytes_counter < RSA_CHUNK) begin
                        r_n <= (r_n<<8)|avm_readdata[7:0];
                    end
                    else begin
                        r_e <= (r_e<<8)|avm_readdata[7:0];
                    end

                    if(r_bytes_counter == RSA_CHUNK*2-1) begin
                        r_bytes_counter <= 0;
                        STATE <= S_GET_DATA;
                        r_enc <= 0;
                        r_dec <= 0;
                    end
                    else begin
                        r_bytes_counter <= r_bytes_counter + 1;
                    end

                    StartRead(STATUS_BASE);
                end
            end
            else if(STATE == S_GET_DATA && !avm_waitrequest) begin
                r_LED_ready <= 0;
                if(r_avm_address == STATUS_BASE) begin
                    if (avm_readdata[RX_OK_BIT]) begin
                        StartRead(RX_BASE);
                    end
                end
                else if(r_avm_address == RX_BASE) begin
                    r_enc <= (r_enc<<8)|avm_readdata[7:0];
                    if(r_bytes_counter == RSA_CHUNK-1) begin
                        if(w_enc_next == RSA_ESC) begin
                            r_enc <= 0;
                            STATE <= S_GET_ESC; 
                        end
                        else begin
                            r_rsa_start <= 1;
                            STATE <= S_WAIT_CALC;
                        end
                        r_bytes_counter <= 0;
                    end
                    else begin
                        r_bytes_counter <= r_bytes_counter + 1;
                    end

                    StartRead(STATUS_BASE);
                end
            end
            else if(STATE == S_GET_ESC && !avm_waitrequest) begin
                if(r_avm_address == STATUS_BASE) begin
                    if (avm_readdata[RX_OK_BIT]) begin
                        StartRead(RX_BASE);
                    end
                end
                else if(r_avm_address == RX_BASE) begin
                    r_enc <= (r_enc<<8)|avm_readdata[7:0];
                    if(r_bytes_counter == RSA_CHUNK-1) begin
                        if(w_enc_next == RSA_ESC) begin
                            r_rsa_start <= 1;
                            STATE <= S_WAIT_CALC;
                        end
                        else if(w_enc_next == RSA_ESC_END) begin
                            Reset();
                        end
                        else begin
                        end
                        r_bytes_counter <= 0;
                    end
                    else begin
                        r_bytes_counter <= r_bytes_counter + 1;
                    end

                    StartRead(STATUS_BASE);
                end
            end
            else if(STATE == S_WAIT_CALC) begin
                r_rsa_start <= 0;

                if(w_rsa_finished) begin
                    r_dec <= w_dec;
                    STATE <= S_SEND_DATA;
                end
            end
            else if(STATE == S_SEND_DATA && !avm_waitrequest) begin
                if(r_avm_address == STATUS_BASE) begin
                    if (avm_readdata[TX_OK_BIT]) begin
                        StartWrite(TX_BASE);
                    end
                end
                else if(r_avm_address == TX_BASE) begin
                    if(r_bytes_counter == RSA_CHUNK-1-1) begin
                        r_enc <= 0;
                        r_bytes_counter <= 0;
                        STATE <= S_GET_DATA;
                    end
                    else begin
                        r_bytes_counter <= r_bytes_counter + 1;
                    end

                    r_dec <= r_dec<<8;
                    StartRead(STATUS_BASE);
                end
            end
        end
    end
    
endmodule
