#include <stdio.h>

#define TINYOBJ_LOADER_C_IMPLEMENTATION
#define GB_MATH_IMPLEMENTATION

#include "includes.h"
#include "REN/ren.h"
#include "tinyobj/objLoader.h"
#include "lodepng/texLoader.h"
#include "sd/sd.h"

// Defined in Makefile
// #define __COMPILE_TO_NIOSII__

void gbTest();

int main(){
	if(!sdLoad()) {
		return 1;
	}

    renScene* scene;
    renCamera* camera;

    while(1) {
    	char objName[256];
    	char texName[256];
    	int camDist;
    	puts("Input model file, texture file, distance...");
    	scanf("%s%s%d", objName, texName, &camDist);

    	scene = renInitScene();
		scene->object = objLoadSD(objName);
		scene->object->texture = texLoadSD(texName);
		 gbMat4 wtc = (gbMat4)
		    { 1, 0, 0, 0,
		      0, 1, 0, 0,
		      0, 0, 1, 0,
		      0, 0, -camDist, 1 };

		    camera = renInitCamera( 0.980f, 0.735f, FRAME_WIDTH, FRAME_HEIGHT,
		                            1.0f, 10000.0f, 20.0f, wtc );
		    renLoop(scene, camera);
    }
    return 0;
}

/*
gbMat4 wtc = (gbMat4)
		    { 1, 0, 0, 0,
		      0, 1, 0, 0,
		      0, 0, 1, 0,
		     // 0, -7, -20, 1 }; // Cow
		    //  0, 0, -5, 1}; // cube
		      0, 0, -3, 1 }; // Suzanne
		     // 0, 0, -3, 1 }; // spot
		      // 0, -2, -6, 1 }; // teapot
		     //   0, -750, -1900, 1 }; // deer
		     // 0, -2, -4, 1 }; // camero
		     // 0, -1250, -6000, 1 }; // Venus*/

/* Cow Front 45
renCameraTransform(camera, 'a', 12);
renCameraTransform(camera, 'w', 8);
renCameraTransform(camera, 'l', 45);
renCameraTransform(camera, 's', 3); */
/* Cow Side
renCameraTransform(camera, 'a', 12);
renCameraTransform(camera, 'w', 22);
renCameraTransform(camera, 'l', 90);
renCameraTransform(camera, 's', 10); */
/* Spot
renCameraTransform(camera, 'w', 5);
renCameraTransform(camera, 'a', 2);
renCameraTransform(camera, 'l', 135);
renCameraTransform(camera, 'i', 90);
renCameraTransform(camera, 'w', 1.8);
renCameraTransform(camera, 'k', 120);
renCameraTransform(camera, 's', 0.4); */
/* Camero
renCameraTransform(camera, 'k', 25);
renCameraTransform(camera, 's', 0); */
