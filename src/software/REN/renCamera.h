#ifndef _RENCAMERA_H_
#define _RENCAMERA_H_

#include "renDefine.h"

typedef struct {
    float       top;
    float       bottom;
    float       left;
    float       right;
    float       nearClippingPlane;
    float       farClippingPlane;
    gbMat4      worldToCamera;
} renCamera;


renCamera* renInitCamera(
    float       filmWidth,
    float       filmHeight,
    int         imageWidth,
    int         imageHeight,
    // fitFilm,
    float       nearClippingPlane,
    float       farClippingPlane,
    float       focalLength,
    gbMat4      worldToCamera
);
void renCameraTransform(renCamera* camera, char dir, float amount);
void renCameraRotateAboutY(renCamera* camera, float deg);
void renCameraRotateAboutCameraX(renCamera* camera, float deg);

#endif
