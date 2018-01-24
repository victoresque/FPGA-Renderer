`ifndef _RECORDER_DEFINE_VH_
`define _RECORDER_DEFINE_VH_

parameter REC_NONE      = 4'd0;
parameter REC_PLAY      = 4'd1;
parameter REC_PAUSE     = 4'd2;
parameter REC_STOP      = 4'd3;
parameter REC_RECORD    = 4'd4;

parameter REC_NORMAL    = 2'd0;
parameter REC_SLOW      = 2'd1;
parameter REC_FAST      = 2'd2;

parameter REC_BUFSIZE   = 4;

parameter REC_BITLEN    = 16;
parameter REC_BITLOG    = 5;
parameter REC_FS        = 32000; // Sampling Frequency

/*
    Function:
        Play(1/8x~8x)
        Record
        Pause
        Stop
        ----Additional
            Next Audio
            Prev Audio
            Loop All
            Loop A
            Loop B
        
    Parameter
        Fast/Slow
        Mult
        Interpol

*/

`endif