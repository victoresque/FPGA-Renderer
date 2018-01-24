
module AudioInit(
    input i_start,
    input i_rst,
    input i_clk100k,
    output o_I2C_SCLK,
    inout io_I2C_SDAT,
    output o_finished,
    // TEST
    output o_led
);
    logic [7:0]  CodecAddr  = 8'b00110100; // 6 bit addr + 1 bit read/write setting          
                            //           v
    logic [15:0] LLineIn    = 16'b0000000010010111;
    logic [15:0] RLineIn    = 16'b0000001010010111;
    logic [15:0] LHeadOut   = 16'b0000010001111001;
    logic [15:0] RHeadOut   = 16'b0000011001111001;
    logic [15:0] APathCtrl  = 16'b0000100000010101;
    logic [15:0] DPathCtrl  = 16'b0000101000000000;
    logic [15:0] PowerCtrl  = 16'b0000110000000000;

    // bitlen = 32
    // logic [15:0] IFormat    = 16'b0000111001001110;
    // bitlen = 16
    logic [15:0] IFormat    = 16'b0000111001000010;

    // USB Mode, BOSR = 0
    // 32kHz/32kHz
     logic [15:0] SampleCtrl = 16'b0001000000011001;
    // 96kHz/96kHz
    //logic [15:0] SampleCtrl = 16'b0001000000011101;

    logic [15:0] ActiveCtrl = 16'b0001001000000001;

    localparam I2C_ADDR_LENGTH   = 8;
    localparam I2C_DATA_LENGTH   = 16;
    localparam I2C_PACKET_COUNT  = 10;

    logic [I2C_ADDR_LENGTH-1:0]                  r_addr;
    logic [I2C_DATA_LENGTH*I2C_PACKET_COUNT-1:0] r_settings;

    enum {
        S_WAIT,
        S_START,
        S_SEND_ADDR,
        S_GET_ACK,
        S_SEND_DATA,
        S_STOP,
        S_RELEASE
    } STATES;

    logic [2:0] STATE;
    logic [2:0] r_stateAfterACK;

    logic [4:0] r_bitCounter;       // Range: [0, 17]
    logic [3:0] r_dataCounter;      // Range: [0, 10]
    logic       r_startCounter;     // Range: [0, 1]
    logic [1:0] r_clkCounter;       // Range: [1, 3]

    logic r_I2C_SCLK, r_I2C_SDAT;

    reg oe_SDAT;
    assign io_I2C_SDAT = oe_SDAT?r_I2C_SDAT:1'bz;
    assign o_I2C_SCLK = r_I2C_SCLK;

    logic r_ack;
    logic r_led;
    assign o_led = r_ack;

    logic r_finished;
    assign o_finished = r_finished;

    always_ff @(posedge i_clk100k or posedge i_rst) begin
        if(i_rst) begin
            r_I2C_SCLK <= 1;
            oe_SDAT <= 0;
            r_I2C_SDAT <= 0;
            r_finished <= 0;
            r_ack <= 1;
            STATE <= S_WAIT;
        end
        else begin
            if(STATE == S_WAIT) begin
                r_finished <= 0;
                if(i_start) begin
                    r_dataCounter <= I2C_PACKET_COUNT;
                    r_settings <= { LLineIn, RLineIn, LHeadOut, RHeadOut,
                                    APathCtrl, DPathCtrl, PowerCtrl, IFormat, 
                                    SampleCtrl, ActiveCtrl };
                    r_startCounter <= 1;
                    STATE <= S_START;
                end
            end
            if(STATE == S_START) begin
                if(r_startCounter == 1) begin
                    oe_SDAT <= 1;
                    r_I2C_SDAT <= 0;
                    r_startCounter <= r_startCounter - 1;
                end
                else begin
                    r_I2C_SCLK <= 0;
                    r_bitCounter <= I2C_ADDR_LENGTH;
                    r_clkCounter <= 3;
                    r_addr <= CodecAddr;
                    STATE <= S_SEND_ADDR;
                end
            end
            else if(STATE == S_SEND_ADDR) begin
                if(r_clkCounter == 3) begin
                    if(r_bitCounter) begin
                        oe_SDAT <= 1;
                        r_I2C_SDAT <= r_addr[7];
                        r_addr <= r_addr << 1;
                        r_bitCounter <= r_bitCounter - 1;
                    end
                    else begin
                        oe_SDAT <= 0;
                        r_bitCounter <= I2C_DATA_LENGTH+1;
                        r_stateAfterACK <= S_SEND_DATA;
                        STATE <= S_GET_ACK;
                    end
                    r_clkCounter <= r_clkCounter - 1;
                end
                else if(r_clkCounter == 2) begin
                    r_I2C_SCLK <= 1;
                    r_clkCounter <= r_clkCounter - 1;
                end
                else if(r_clkCounter == 1) begin
                    r_I2C_SCLK <= 0;
                    r_clkCounter <= 3;
                end
            end
            else if(STATE == S_GET_ACK) begin
                if(r_clkCounter == 2) begin
                    r_ack <= r_ack & ~io_I2C_SDAT;
                    r_I2C_SCLK <= 1;
                    r_clkCounter <= r_clkCounter - 1;
                end
                else if(r_clkCounter == 1) begin
                    r_I2C_SCLK <= 0;
                    r_clkCounter <= 3;
                    STATE <= r_stateAfterACK;
                end
            end
            else if(STATE == S_SEND_DATA) begin
                if(r_clkCounter == 3) begin
                    if(r_bitCounter > I2C_DATA_LENGTH-7) begin
                        oe_SDAT <= 1;
                        r_I2C_SDAT <= r_settings[160-1];
                        r_settings <= r_settings << 1;
                        r_bitCounter <= r_bitCounter - 1;
                    end
                    else if(r_bitCounter == I2C_DATA_LENGTH-7) begin
                        oe_SDAT <= 0;
                        r_bitCounter <= r_bitCounter - 1;
                        r_stateAfterACK <= S_SEND_DATA;
                        STATE <= S_GET_ACK;
                    end
                    else if(r_bitCounter) begin
                        oe_SDAT <= 1;
                        r_I2C_SDAT <= r_settings[160-1];
                        r_settings <= r_settings << 1;
                        r_bitCounter <= r_bitCounter - 1;
                    end
                    else begin
                        oe_SDAT <= 0;
                        r_bitCounter <= I2C_DATA_LENGTH;
                        r_stateAfterACK <= S_STOP;
                        STATE <= S_GET_ACK;
                    end
                    r_clkCounter <= r_clkCounter - 1;
                end
                else if(r_clkCounter == 2) begin
                    r_I2C_SCLK <= 1;
                    r_clkCounter <= r_clkCounter - 1;
                end
                else if(r_clkCounter == 1) begin
                    r_I2C_SCLK <= 0;
                    r_clkCounter <= 3;
                end
            end
            else if(STATE == S_STOP) begin
                if(r_clkCounter == 3) begin
                    oe_SDAT <= 1;
                    r_I2C_SDAT <= 0;
                    r_clkCounter <= r_clkCounter - 1;
                end
                else if(r_clkCounter == 2) begin
                    r_I2C_SCLK <= 1;
                    r_clkCounter <= r_clkCounter - 1;
                end
                else if(r_clkCounter == 1) begin
                    oe_SDAT <= 1;
                    r_I2C_SDAT <= 1;
                    r_clkCounter <= 3;
                    r_dataCounter <= r_dataCounter - 1;
                    STATE <= S_RELEASE;
                end
            end
            else if(STATE == S_RELEASE) begin
                if(r_finished == 0) begin
                    oe_SDAT <= 0;
                    if(r_dataCounter) begin
                        r_startCounter <= 1;
                        STATE <= S_START;
                    end
                    else begin
                        r_finished <= 1;
                    end
                end
                else if(i_start == 0) begin
                    STATE <= S_WAIT;
                end
            end
        end
    end

endmodule