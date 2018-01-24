// DE2_115_TOP
// Revision History :
// --------------------------------------------------------------------
// Shiva Rajagopal, Cornell University, Dec 2015
// --------------------------------------------------------------------

module DE2_115_tbSRAMController (
    // Clock Inputs
    input         CLOCK_50,    // 50MHz Input 1
    input         CLOCK2_50,   // 50MHz Input 2
    input         CLOCK3_50,   // 50MHz Input 3
    output        SMA_CLKOUT,  // External Clock Output
    input         SMA_CLKIN,   // External Clock Input

    // Push Button
    input  [3:0]  KEY,         // Pushbutton[3:0]

    // DPDT Switch
    input  [17:0] SW,          // Toggle Switch[17:0]

    // 7-SEG Display
    output [6:0]  HEX0,        // Seven Segment Digit 0
    output [6:0]  HEX1,        // Seven Segment Digit 1
    output [6:0]  HEX2,        // Seven Segment Digit 2
    output [6:0]  HEX3,        // Seven Segment Digit 3
    output [6:0]  HEX4,        // Seven Segment Digit 4
    output [6:0]  HEX5,        // Seven Segment Digit 5
    output [6:0]  HEX6,        // Seven Segment Digit 6
    output [6:0]  HEX7,        // Seven Segment Digit 7

    // LED
    output [8:0]  LEDG,        // LED Green[8:0]
    output [17:0] LEDR,        // LED Red[17:0]

    // UART
    output        UART_TXD,    // UART Transmitter
    input         UART_RXD,    // UART Receiver
    output        UART_CTS,    // UART Clear to Send
    input         UART_RTS,    // UART Request to Send

    // IRDA
    input         IRDA_RXD,    // IRDA Receiver

    // SDRAM Interface
    inout  [31:0] DRAM_DQ,     // SDRAM Data bus 32 Bits
    output [12:0] DRAM_ADDR,   // SDRAM Address bus 13 Bits
    output [1:0]  DRAM_BA,     // SDRAM Bank Address
    output [3:0]  DRAM_DQM,    // SDRAM Byte Data Mask 
    output        DRAM_RAS_N,  // SDRAM Row Address Strobe
    output        DRAM_CAS_N,  // SDRAM Column Address Strobe
    output        DRAM_CKE,    // SDRAM Clock Enable
    output        DRAM_CLK,    // SDRAM Clock
    output        DRAM_WE_N,   // SDRAM Write Enable
    output        DRAM_CS_N,   // SDRAM Chip Select

    // Flash Interface
    inout  [7:0]  FL_DQ,       // FLASH Data bus 8 Bits
    output [22:0] FL_ADDR,     // FLASH Address bus 23 Bits
    output        FL_WE_N,     // FLASH Write Enable
    output        FL_WP_N,     // FLASH Write Protect / Programming Acceleration
    output        FL_RST_N,    // FLASH Reset
    output        FL_OE_N,     // FLASH Output Enable
    output        FL_CE_N,     // FLASH Chip Enable
    input         FL_RY,       // FLASH Ready/Busy output

    // SRAM Interface
    inout  [15:0] SRAM_DQ,     // SRAM Data bus 16 Bits
    output [19:0] SRAM_ADDR,   // SRAM Address bus 20 Bits
    output        SRAM_OE_N,   // SRAM Output Enable
    output        SRAM_WE_N,   // SRAM Write Enable
    output        SRAM_CE_N,   // SRAM Chip Enable
    output        SRAM_UB_N,   // SRAM High-byte Data Mask 
    output        SRAM_LB_N,   // SRAM Low-byte Data Mask 

    // ISP1362 Interface
    inout  [15:0] OTG_DATA,    // ISP1362 Data bus 16 Bits
    output [1:0]  OTG_ADDR,    // ISP1362 Address 2 Bits
    output        OTG_CS_N,    // ISP1362 Chip Select
    output        OTG_RD_N,    // ISP1362 Write
    output        OTG_WR_N,    // ISP1362 Read
    output        OTG_RST_N,   // ISP1362 Reset
    input         OTG_INT,     // ISP1362 Interrupts
    inout         OTG_FSPEED,  // USB Full Speed, 0 = Enable, Z = Disable
    inout         OTG_LSPEED,  // USB Low Speed,  0 = Enable, Z = Disable
    input  [1:0]  OTG_DREQ,    // ISP1362 DMA Request
    output [1:0]  OTG_DACK_N,  // ISP1362 DMA Acknowledge

    // LCD Module 16X2
    inout  [7:0]  LCD_DATA,    // LCD Data bus 8 bits
    output        LCD_ON,      // LCD Power ON/OFF
    output        LCD_BLON,    // LCD Back Light ON/OFF
    output        LCD_RW,      // LCD Read/Write Select, 0 = Write, 1 = Read
    output        LCD_EN,      // LCD Enable
    output        LCD_RS,      // LCD Command/Data Select, 0 = Command, 1 = Data

    // SD Card Interface
    inout  [3:0]  SD_DAT,      // SD Card Data
    inout         SD_CMD,      // SD Card Command Line
    output        SD_CLK,      // SD Card Clock
    input         SD_WP_N,     // SD Write Protect

    // EEPROM Interface
    output        EEP_I2C_SCLK, // EEPROM Clock
    inout         EEP_I2C_SDAT, // EEPROM Data

    // PS2
    inout         PS2_DAT,     // PS2 Data
    inout         PS2_CLK,     // PS2 Clock
    inout         PS2_DAT2,    // PS2 Data 2 (use for 2 devices and y-cable)
    inout         PS2_CLK2,    // PS2 Clock 2 (use for 2 devices and y-cable)

    // I2C  
    inout         I2C_SDAT,    // I2C Data
    output        I2C_SCLK,    // I2C Clock

    // Audio CODEC
    inout         AUD_ADCLRCK, // Audio CODEC ADC LR Clock
    input         AUD_ADCDAT,  // Audio CODEC ADC Data
    inout         AUD_DACLRCK, // Audio CODEC DAC LR Clock
    output        AUD_DACDAT,  // Audio CODEC DAC Data
    inout         AUD_BCLK,    // Audio CODEC Bit-Stream Clock
    output        AUD_XCK,     // Audio CODEC Chip Clock

    // Ethernet Interface (88E1111)
    input         ENETCLK_25,    // Ethernet clock source

    output        ENET0_GTX_CLK, // GMII Transmit Clock 1
    input         ENET0_INT_N,   // Interrupt open drain output 1
    input         ENET0_LINK100, // Parallel LED output of 100BASE-TX link 1
    output        ENET0_MDC,     // Management data clock ref 1
    inout         ENET0_MDIO,    // Management data 1
    output        ENET0_RST_N,   // Hardware Reset Signal 1
    input         ENET0_RX_CLK,  // GMII and MII receive clock 1
    input         ENET0_RX_COL,  // GMII and MII collision 1
    input         ENET0_RX_CRS,  // GMII and MII carrier sense 1
    input   [3:0] ENET0_RX_DATA, // GMII and MII receive data 1
    input         ENET0_RX_DV,   // GMII and MII receive data valid 1
    input         ENET0_RX_ER,   // GMII and MII receive error 1
    input         ENET0_TX_CLK,  // MII Transmit clock 1
    output  [3:0] ENET0_TX_DATA, // MII Transmit data 1
    output        ENET0_TX_EN,   // GMII and MII transmit enable 1
    output        ENET0_TX_ER,   // GMII and MII transmit error 1

    output        ENET1_GTX_CLK, // GMII Transmit Clock 1
    input         ENET1_INT_N,   // Interrupt open drain output 1
    input         ENET1_LINK100, // Parallel LED output of 100BASE-TX link 1
    output        ENET1_MDC,     // Management data clock ref 1
    inout         ENET1_MDIO,    // Management data 1
    output        ENET1_RST_N,   // Hardware Reset Signal 1
    input         ENET1_RX_CLK,  // GMII and MII receive clock 1
    input         ENET1_RX_COL,  // GMII and MII collision 1
    input         ENET1_RX_CRS,  // GMII and MII carrier sense 1
    input   [3:0] ENET1_RX_DATA, // GMII and MII receive data 1
    input         ENET1_RX_DV,   // GMII and MII receive data valid 1
    input         ENET1_RX_ER,   // GMII and MII receive error 1
    input         ENET1_TX_CLK,  // MII Transmit clock 1
    output  [3:0] ENET1_TX_DATA, // MII Transmit data 1
    output        ENET1_TX_EN,   // GMII and MII transmit enable 1
    output        ENET1_TX_ER,   // GMII and MII transmit error 1

    // Expansion Header
    inout   [6:0] EX_IO,       // 14-pin GPIO Header
    inout  [35:0] GPIO,        // 40-pin Expansion header

    // TV Decoder
    input  [8:0]  TD_DATA,     // TV Decoder Data
    input         TD_CLK27,    // TV Decoder Clock Input
    input         TD_HS,       // TV Decoder H_SYNC
    input         TD_VS,       // TV Decoder V_SYNC
    output        TD_RESET_N,  // TV Decoder Reset

    // VGA
    output        VGA_CLK,     // VGA Clock
    output        VGA_HS,      // VGA H_SYNC
    output        VGA_VS,      // VGA V_SYNC
    output        VGA_BLANK_N, // VGA BLANK
    output        VGA_SYNC_N,  // VGA SYNC
    output [7:0]  VGA_R,       // VGA Red[9:0]
    output [7:0]  VGA_G,       // VGA Green[9:0]
    output [7:0]  VGA_B       // VGA Blue[9:0]
);

    // Turn off all displays.
    assign HEX0 = 7'h7F;
    assign HEX1 = 7'h7F;
    assign HEX2 = 7'h7F;
    assign HEX3 = 7'h7F;
    assign HEX4 = 7'h7F;
    assign HEX5 = 7'h7F;
    assign HEX6 = 7'h7F;
    assign HEX7 = 7'h7F;

    // Set all GPIO to tri-state.
    assign GPIO_0 = 36'hzzzzzzzzz;
    assign GPIO_1 = 36'hzzzzzzzzz;

    // Disable audio codec.
    // assign AUD_DACDAT = 1'b0;
    // assign AUD_XCK    = 1'b0;

    // Disable DRAM
    assign DRAM_ADDR  = 13'h0;
    assign DRAM_BA_0  = 2'b0;
    assign DRAM_CAS_N = 1'b1;
    assign DRAM_CKE   = 1'b0;
    assign DRAM_CLK   = 1'b0;
    assign DRAM_CS_N  = 1'b1;
    assign DRAM_DQ    = 32'hzzzz;
    assign DRAM_DQM   = 4'b0;
    assign DRAM_RAS_N = 1'b1;
    assign DRAM_UDQM  = 1'b0;
    assign DRAM_WE_N  = 1'b1;

    // Disable flash.
    assign FL_ADDR  = 23'h0;
    assign FL_CE_N  = 1'b1;
    assign FL_DQ    = 8'hzz;
    assign FL_OE_N  = 1'b1;
    assign FL_RST_N = 1'b1;
    assign FL_WE_N  = 1'b1;
    assign FL_WP_N  = 1'b0;

    // Disable LCD.
    assign LCD_BLON = 1'b0;
    assign LCD_DATA = 8'hzz;
    assign LCD_EN   = 1'b0;
    assign LCD_ON   = 1'b0;
    assign LCD_RS   = 1'b0;
    assign LCD_RW   = 1'b0;

    // Disable OTG.
    assign OTG_ADDR    = 2'h0;
    assign OTG_CS_N    = 1'b1;
    assign OTG_DACK_N  = 2'b11;
    assign OTG_FSPEED  = 1'b1;
    assign OTG_DATA    = 16'hzzzz;
    assign OTG_LSPEED  = 1'b1;
    assign OTG_RD_N    = 1'b1;
    assign OTG_RST_N   = 1'b1;
    assign OTG_WR_N    = 1'b1;

    // Disable SD
    assign SD_DAT = 4'bzzzz;
    assign SD_CLK = 1'b0;
    assign SD_CMD = 1'b0;

    // Disable SRAM.
    /*
    assign SRAM_ADDR = 20'h0;
    assign SRAM_CE_N = 1'b1;
    assign SRAM_DQ   = 16'hzzzz;
    assign SRAM_LB_N = 1'b1;
    assign SRAM_OE_N = 1'b1;
    assign SRAM_UB_N = 1'b1;
    assign SRAM_WE_N = 1'b1;
    */
    assign SRAM_CE_N = 1'b0;
    assign SRAM_OE_N = 1'b0;
    assign SRAM_LB_N = 1'b0;
    assign SRAM_UB_N = 1'b0;
    // Disable all other peripherals.
    /*
    assign I2C_SCLK   = 1'b0;
    */
    //assign TD_RESET_N = 1'b0;
    assign UART_TXD   = 1'b0;
    assign UART_CTS   = 1'b0;


    ///////////////////////////////////////
    // Main program
    ///////////////////////////////////////

    //assign TD_RESET_N = 1'b1;  // Enable 27MHz Clock
    wire rst_main;
    assign rst_main = SW[17];

    wire w_read;
    wire w_write;
    wire [31:0] w_addr;
    wire [15:0] w_data;
    wire w_done;

    MemoryInterface memoryInterface(
        .i_clk(CLOCK_50),
        .i_rst(rst_main),
        .i_read(w_read),
        .i_write(w_write),
        .i_addr(w_addr),
        .io_data(w_data),
        .o_done(w_done),
        .sram_we_n(SRAM_WE_N),
        .sram_addr(SRAM_ADDR),
        .sram_dq(SRAM_DQ)
    );

    tbMemoryInterface tb(
        .i_clk(CLOCK_50),
        .i_rst(rst_main),
        .i_btn(KEY),
        .i_sw(SW[15:0]),
        .o_led(LEDR[15:0]),
        .o_read(w_read),
        .o_write(w_write),
        .o_addr(w_addr),
        .io_data(w_data),
        .i_done(w_done)
    );

endmodule

module tbMemoryInterface(
    input           i_clk,
    input           i_rst,
    input   [3:0]   i_btn,
    input   [15:0]  i_sw,
    output  [15:0]  o_led,
    // Memory Interface
    output          o_read,
    output          o_write,
    output  [31:0]  o_addr,
    inout   [15:0]  io_data,
    input           i_done
);
    wire w_btn0, w_btn1, w_btn2, w_btn3;
    Debounce db0(.i_in(i_btn[0]),.i_clk(i_clk),.o_pos(w_btn0));
    Debounce db1(.i_in(i_btn[1]),.i_clk(i_clk),.o_pos(w_btn1));
    Debounce db2(.i_in(i_btn[2]),.i_clk(i_clk),.o_pos(w_btn2));
    Debounce db3(.i_in(i_btn[3]),.i_clk(i_clk),.o_pos(w_btn3));

    enum {
        S_WAIT,
        S_READ,
        S_WRITE
    } STATES;
    reg [2:0] STATE;

    reg [15:0] r_data;
    assign o_led = r_data;
    reg r_read, r_write;
    assign o_read = r_read;
    assign o_write = r_write;
    reg [15:0] r_addr;
    assign o_addr = r_addr;

    reg r_val_read;
    reg r_val_written;

    reg oe_data; // output enabled
    assign io_data = oe_data?r_data:16'hzzzz;

    always_ff @(posedge i_clk or posedge i_rst) begin
        if(i_rst) begin
            STATE <= S_WAIT;
            r_data <= 0;
            r_read <= 0;
            r_write <= 0;
            r_addr <= 0;
            r_val_read <= 0;
            r_val_written <= 0;
            oe_data <= 0;
        end
        else begin
            if(STATE == S_WAIT) begin
                if(w_btn0) begin 
                    r_data <= 16'hffff;
                    STATE <= S_READ; 
                end
            end
            else if(STATE == S_READ) begin
                if(w_btn0) begin 
                    oe_data <= 1;
                    r_val_read <= 0;
                    r_data <= 16'h0000;
                    STATE <= S_WRITE; 
                end
                else begin
                    if(r_val_read) begin
                        r_read <= 0;
                        if(i_done) begin
                            r_data <= io_data;
                        end
                    end

                    if(w_btn2) begin 
                        r_addr <= r_addr + 1;
                        r_val_read <= 0;
                    end
                    else if(w_btn3) begin
                        if(r_addr > 0) begin
                            r_addr <= r_addr - 1; 
                            r_val_read <= 0;
                        end
                    end else begin
                        if(!r_val_read) begin
                            r_read <= 1;
                            r_val_read <= 1;
                        end
                    end
                end
            end
            else if(STATE == S_WRITE) begin
                if(w_btn0) begin 
                    oe_data <= 0;
                    r_val_written <= 0;
                    r_data <= 16'hffff;
                    STATE <= S_READ; 
                end
                else begin
                    if(r_val_written) begin
                        r_write <= 0;
                        if(i_done) begin
                            r_data <= 0;
                        end
                    end
                    if(w_btn1) begin
                        if(!r_val_written) begin
                            r_write <= 1;
                            r_data <= i_sw;
                            r_val_written <= 1;
                        end
                    end
                    else if(w_btn2) begin 
                        r_addr <= r_addr + 1;
                        r_val_written <= 0;
                    end
                    else if(w_btn3) begin
                        if(r_addr > 0) begin
                            r_addr <= r_addr - 1; 
                            r_val_written <= 0;
                        end
                    end
                end
            end
        end
    end

endmodule
