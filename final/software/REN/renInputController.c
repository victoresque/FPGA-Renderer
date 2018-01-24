#include "renInputController.h"
#include "altera_up_avalon_ps2.h"

static void ps2Wait(alt_u32 byte) {
	while(1) { alt_u32 reg0 = IORD_32DIRECT(PS2_MOUSE_BASE, 0);
		if(reg0 & 0x00008000) { if((reg0 & 0x000000FF)==byte) {
			break;
		}}
	}
}
static void ps2Send(alt_u32 byte) {
	IOWR_32DIRECT(PS2_MOUSE_BASE, 0, byte);
}
static void ps2SendWaitACK(alt_u32 byte) {
	int timeout = 10000;
	int T;
	while(1) {
		T = timeout;
		ps2Send(byte);
		while(T--) {
			alt_u32 reg0 = IORD_32DIRECT(PS2_MOUSE_BASE, 0);
			if(reg0 & 0x00008000) { if((reg0 & 0x000000FF)==0xFA) {
				return;
			}}
		}
	}
}

static void handle_mouse_irq(void* context) {
	alt_irq_disable(PS2_MOUSE_IRQ);
	alt_u32 reg0 = IORD_32DIRECT(PS2_MOUSE_BASE, 0);
	int packet = reg0 & 0x000000FF;

	if(mousePacketIndex == 0) {
		mousePacket0 = packet;
	}
	else if(mousePacketIndex == 1) {
		if(mousePacket0&(1<<4)) {
			mouseInputX = -(256-packet);
		}
		else {
			mouseInputX = packet;
		}
	}

	mousePacketIndex = (mousePacketIndex+1)%3;
	alt_irq_enable(PS2_MOUSE_IRQ);
}
static void handle_keyboard_irq(void* context) {
	alt_irq_disable(PS2_KEYBOARD_IRQ);
	//puts("Keyboard IRQ");
	alt_u32 reg0 = IORD_32DIRECT(PS2_KEYBOARD_BASE, 0);
	int keycode = reg0 & 0x000000FF;
	//printf("%d\n",keycode);
	if(!keyboardRelease) {
		switch(keycode) {
			case 29: keyboardInput = 'w'; break;
			case 28: keyboardInput = 'a'; break;
			case 27: keyboardInput = 's'; break;
			case 35: keyboardInput = 'd'; break;
			case 67: keyboardInput = 'i'; break;
			case 59: keyboardInput = 'j'; break;
			case 66: keyboardInput = 'k'; break;
			case 75: keyboardInput = 'l'; break;
			case 21: keyboardInput = 'q'; break;
			case 36: keyboardInput = 'e'; break;
			case 118: keyboardInput = -1; break;
			case 240: keyboardInput = 0; keyboardRelease = 1; break;
			default: break;
		}
	}
	else {
		keyboardRelease = 0;
	}

	alt_irq_enable(PS2_KEYBOARD_IRQ);
}

void renMouseInit() {
	ps2SendWaitACK(0xFF);
	//puts("1"); fflush(stdout);
	ps2Wait(0xAA);
	//puts("2"); fflush(stdout);
	ps2Wait(0x00);
	//puts("3"); fflush(stdout);
	ps2SendWaitACK(0xF4);
	//puts("Done"); fflush(stdout);


	/*
	while(1) { alt_u32 reg0 = IORD_32DIRECT(PS2_MOUSE_BASE, 0);
		if(reg0 & 0x00008000) {
			printf("%x\n",reg0 & 0xFF);
			fflush(stdout);
		}
	}*/

	alt_up_ps2_dev* ps2_mouse = NULL;
	ps2_mouse = alt_up_ps2_open_dev(PS2_MOUSE_NAME);

	/*ps2_mouse->timeout = 0;
	alt_up_ps2_clear_fifo(ps2_mouse);
	alt_up_ps2_init(ps2_mouse);
	ps2_mouse->device_type = PS2_MOUSE;*/
	alt_up_ps2_enable_read_interrupt(ps2_mouse);

	void* edge_capture_ptr = (void*) &ren_mouse_edge_capture;
	alt_irq_register( PS2_MOUSE_IRQ, edge_capture_ptr, handle_mouse_irq);

	mousePacketIndex = 0;
}

void renKeyboardInit() {
	alt_up_ps2_dev* ps2_keyboard = NULL;
	ps2_keyboard = alt_up_ps2_open_dev(PS2_KEYBOARD_NAME);

	ps2_keyboard->timeout = 2000000;
	alt_up_ps2_clear_fifo(ps2_keyboard);
	alt_up_ps2_init(ps2_keyboard);
	ps2_keyboard->device_type = PS2_KEYBOARD;
	alt_up_ps2_enable_read_interrupt(ps2_keyboard);

	keyboardRelease = 0;

	void* edge_capture_ptr = (void*) &ren_keyboard_edge_capture;
	alt_irq_register( PS2_KEYBOARD_IRQ, edge_capture_ptr, handle_keyboard_irq);
}
