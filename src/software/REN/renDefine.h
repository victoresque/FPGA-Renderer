#ifndef _RENDEFINE_H_
#define _RENDEFINE_H_

#include "../includes.h"
#include "../math/gb_math.h"
#include "../vip_fr.h"
#include "../graphic_lib/simple_graphics.h"
#include <math.h>

#define RENDER_TIMES 1
#define FRAME_WIDTH  160
#define FRAME_HEIGHT 120

#define FRAME0_ADDR (SRAM_BASE)
#define FRAME1_ADDR (SRAM_BASE + FRAME_WIDTH*FRAME_HEIGHT*4)
#define ZBUF_ADDR   (SRAM_BASE + FRAME_WIDTH*FRAME_HEIGHT*8)
typedef VIP_FRAME_READER renFrameBuf;

#endif
