#ifndef _RENINPUTCONTROLLER_H_
#define _RENINPUTCONTROLLER_H_
#include "../includes.h"

void renMouseInit();
void renKeyboardInit();

volatile int ren_mouse_edge_capture;
volatile int ren_keyboard_edge_capture;

int keyboardRelease;
char keyboardInput;

int mousePacket0;
int mousePacketIndex;
int mouseInputX;

#endif
