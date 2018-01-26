#include "renLoop.h"
#include "renInputController.h"
#include <stdio.h>
#include <time.h>

static int renInputInitialized = 0;

void renLoop(renScene* scene, renCamera* camera){
	renRenderer* renderer = renInitRenderer();
	if(!renInputInitialized) {
		renMouseInit();
		renKeyboardInit();
		puts("Input initialized.");
		renInputInitialized = 1;
	}

	clock_t tStart, tEnd;
	float fps = 30;
	float freq = 0.2;
	float angularFreq = 2 * M_PI * freq;
	clock_t clocksPerFrame = (clock_t)(CLOCKS_PER_SEC / fps);

	char dir[2];
	renRenderScene(renderer, scene, camera);

	tStart = clock();
	while(1) {
		clock_t tNow = clock();
		clock_t tDelta = tNow - tStart;

		/*
		if(tDelta >= clocksPerFrame) {
			tStart = tNow;
			renRenderScene(renderer, scene, camera);
			renCameraRotateAboutY(camera, angularFreq * tDelta / clocksPerFrame);
		}
		*/
		int mouseThresholdX = 1;
		if(mouseInputX > mouseThresholdX || mouseInputX < -mouseThresholdX) {
			renRenderScene(renderer, scene, camera);
			renCameraRotateAboutY(camera, mouseInputX);
		}

		if(keyboardInput) {
			if(keyboardInput==-1) {
				return;
			}

			tStart = clock();
			float amount = 1.0f;
			if(keyboardInput=='w' || keyboardInput=='a'
			|| keyboardInput=='s' || keyboardInput=='d'
			|| keyboardInput=='q' || keyboardInput=='e') {
				amount = .2f;
			}
			renCameraTransform(camera, keyboardInput, amount);
			renRenderScene(renderer, scene, camera);
			tEnd = clock();
		}

		double timePerFrame = ((double)(tEnd - tStart) / CLOCKS_PER_SEC);
	}
}
