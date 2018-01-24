// DE2_115_TOP
// Revision History :
// --------------------------------------------------------------------
// Shiva Rajagopal, Cornell University, Dec 2015
// --------------------------------------------------------------------

module DE2_115 (
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
    assign SRAM_CE_N = 1'b0;
    assign SRAM_OE_N = 1'b0;
    assign SRAM_LB_N = 1'b0;
    assign SRAM_UB_N = 1'b0;
    assign HEX0 = 7'h7F;
    assign HEX1 = 7'h7F;
    assign HEX2 = 7'h7F;
    assign HEX3 = 7'h7F;
    assign HEX4 = 7'h7F;
    assign HEX5 = 7'h7F;
    assign HEX6 = 7'h7F;
    assign HEX7 = 7'h7F;
    
    ///////////////////////////////////////
    // Main program
    ///////////////////////////////////////

    // Audio CODEC
    AudioPLL audioPLL(
        .clk_clk(CLOCK_50),
        .reset_reset_n(~rst_main),
        .audio_clk_clk(AUD_XCK)
    );
    wire rst_audio;
    assign rst_audio = SW[16];
    AudioConfig audioConfig(
        .audio_and_video_config_0_external_interface_SDAT(I2C_SDAT),
        .audio_and_video_config_0_external_interface_SCLK(I2C_SCLK),
        .clk_clk(CLOCK_50),
        .reset_reset_n(~rst_audio)
    );
    
    // Main Module
    wire rst_main;
    assign rst_main = SW[17];
    wire            w_mem_read;
    wire            w_mem_write;
    wire    [31:0]  w_mem_addr;
    wire    [15:0]  w_mem_data;
    wire            w_mem_done;
	 wire    [63:0]  w_time;
    
    wire    [15:0]  w_input_event;
    wire    [15:0]  w_event_hold;
    
    wire    [15:0]  w_fancy;
    
    Recorder recorder(
        .i_clk(CLOCK_50),
        .i_rst(rst_main),
        .i_input_event(w_input_event),
        .o_output_event(),
		  
        .o_event_hold(w_event_hold),
		.o_time(w_time),
		  
        .AUD_BCLK(AUD_BCLK),
        .AUD_ADCLRCK(AUD_ADCLRCK),
        .AUD_ADCDAT(AUD_ADCDAT),
        .AUD_DACLRCK(AUD_DACLRCK),
        .AUD_DACDAT(AUD_DACDAT),
        .o_mem_read(w_mem_read),
        .o_mem_write(w_mem_write),
        .o_mem_addr(w_mem_addr),
        .io_mem_data(w_mem_data),
        .i_mem_done(w_mem_done),
        
        .o_fancy(w_fancy),
    );
    
    Fancy thisIsSoFancy(
        .i_clk(CLOCK_50),
        .i_rst(rst_main),
        .i_event_hold(w_event_hold),
        .i_fancy_raw(w_fancy),
        .o_led(LEDR[15:0]),
        .AUD_BCLK(AUD_BCLK),
        .AUD_ADCLRCK(AUD_ADCLRCK),
        .AUD_ADCDAT(AUD_ADCDAT)
    );
    
    // Memory Controller
    wire [24:0] w_avm_address;
    wire [3:0]  w_avm_byteenable;
    wire        w_avm_chipselect;
    wire [31:0] w_avm_writedata;
    wire        w_avm_read;
    wire        w_avm_write;
    wire [31:0] w_avm_readdata;
    wire        w_avm_readdatavalid;
    wire        w_avm_waitrequest;
    sdram_avm_controller sdram_avm_controller_inst(
        .clk(CLOCK_50),
        .rst(rst_main),
        .i_read(w_mem_read),
        .i_write(w_mem_write),
        .i_addr(w_mem_addr),
        .io_data(w_mem_data),
        .o_done(w_mem_done),
        .o_avm_address(w_avm_address),
        .o_avm_byteenable(w_avm_byteenable),
        .o_avm_chipselect(w_avm_chipselect),
        .o_avm_writedata(w_avm_writedata),
        .o_avm_read(w_avm_read),
        .o_avm_write(w_avm_write),
        .i_avm_readdata(w_avm_readdata),
        .i_avm_readdatavalid(w_avm_readdatavalid),
        .i_avm_waitrequest(w_avm_waitrequest)
    );
    SDRAM SDRAMController(
        .clk_clk(CLOCK_50),
        .rst_reset_n(~rst_main),
        .sdram_avm_address(w_avm_address),
        .sdram_avm_byteenable_n(~w_avm_byteenable),
        .sdram_avm_chipselect(w_avm_chipselect),
        .sdram_avm_writedata(w_avm_writedata),
        .sdram_avm_read_n(~w_avm_read),
        .sdram_avm_write_n(~w_avm_write),
        .sdram_avm_readdata(w_avm_readdata),
        .sdram_avm_readdatavalid(w_avm_readdatavalid),
        .sdram_avm_waitrequest(w_avm_waitrequest),
        .sdram_clk_clk(DRAM_CLK),
        .sdram_wire_addr(DRAM_ADDR),
        .sdram_wire_ba(DRAM_BA),
        .sdram_wire_cas_n(DRAM_CAS_N),
        .sdram_wire_cke(DRAM_CKE),
        .sdram_wire_cs_n(DRAM_CS_N),
        .sdram_wire_dq(DRAM_DQ),
        .sdram_wire_dqm(DRAM_DQM),
        .sdram_wire_ras_n(DRAM_RAS_N),
        .sdram_wire_we_n(DRAM_WE_N)
    );
    /*SRAMController sramcontroller(
        .i_clk(CLOCK_50),
        .i_rst(rst_main),
        .i_read(w_mem_read),
        .i_write(w_mem_write),
        .i_addr(w_mem_addr),
        .io_data(w_mem_data),
        .o_done(w_mem_done),
        .SRAM_WE_N(SRAM_WE_N),
        .SRAM_ADDR(SRAM_ADDR),
        .SRAM_DQ(SRAM_DQ)
    );*/
    // Input Controller
    InputController inputController(
        .i_clk(CLOCK_50),
        .i_rst(rst_main),
        .i_btn_play(KEY[3]),
        .i_btn_pause(KEY[2]),
        .i_btn_stop(KEY[1]),
        .i_btn_record(KEY[0]),
        .i_sw_speed(SW[8:0]),
        .i_sw_interpol(SW[9]),
        .o_input_event(w_input_event)
    );
    // Output Controller
	 LCD lcd_controller(
        .LCD_DATA(LCD_DATA),
        .LCD_EN(LCD_EN),
        .LCD_RW(LCD_RW),
        .LCD_RS(LCD_RS),
        .LCD_ON(LCD_ON),
        .LCD_BLON(LCD_BLON),
        .BUSY(busy),
        .START(start),
        .CLEAR(clear),

        .CHARACTER(char),
        .ADDRESS(addr),
        .i_rst(SW[17]),
        .i_clk(CLOCK_50),
    );
    
    LCD_wrapper LCD_top(
        .CHARACTER(char),
        .ADDRESS(addr),

        .START(start),
        .CLEAR(clear),
        .BUSY(busy),

        .i_clk(CLOCK2_50),
        .i_rst(SW[17]),
        .STATUS(w_event_hold),
        .TIME(w_time)
    );
    
    wire [7:0] char;
    wire [7:0] addr;
    wire start;
    wire busy;
    wire clear;
	 
	 /* Legacy
    OutputController outputController(
        .i_clk(CLOCK_50),
        .i_rst(rst_main),
        .i_output_event(w_output_event),
        .i_time(w_time)
    );
        assign w_aud_init_fin = 1;
        wire w_clk100k;
        I2CPLL i2cPLL(
            .clk_clk(CLOCK2_50),
            .reset_reset_n(~rst_main),
            .i2c_clk(w_clk100k)
        );
        AudioInit audioInit(
            .i_start(w_aud_init_start),
            .i_rst(rst_main),
            .i_clk100k(w_clk100k),
            .o_I2C_SCLK(I2C_SCLK),
            .io_I2C_SDAT(I2C_SDAT),
            .o_finished(w_aud_init_fin)
        );
    */
endmodule
