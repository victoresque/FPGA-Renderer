#include "renCamera.h"

static const float inchToMm = 25.4;

renCamera* renInitCamera(
    float       filmWidth,              // inch
    float       filmHeight,             // inch
    int         imageWidth,
    int         imageHeight,
    // fitFilm,
    float       nearClippingPlane,
    float       farClippingPlane,
    float       focalLength,            // mm
    gbMat4      worldToCamera
) {
    renCamera* camera;
    camera = (renCamera*) malloc(sizeof(renCamera));

    float filmRatio  = filmWidth/filmHeight;
    float imageRatio = imageWidth/(float)imageHeight;

    camera->top   = ((filmHeight * inchToMm / 2) / focalLength) * nearClippingPlane;
    camera->right = ((filmWidth  * inchToMm / 2) / focalLength) * nearClippingPlane;

    // Overscan
    if (filmRatio > imageRatio){
        camera->top   *= filmRatio / imageRatio;
    }else{
        camera->right *= imageRatio / filmRatio;
    }

    camera->bottom = -camera->top;
    camera->left   = -camera->right;

    camera->nearClippingPlane = nearClippingPlane;
    camera->farClippingPlane  = farClippingPlane;

    camera->worldToCamera = worldToCamera;

    return camera;
}


void renCameraTransform(renCamera* camera, char dir, float amount) {
    if(dir == 'w' || dir == 'a' || dir == 's' || dir == 'd') {
        gbVec4 forward;
        if(dir == 'w' || dir == 's') {
            forward = (gbVec4) {0.0f, 0.0f, -1.0f, 1.0f};
        }
        else {
            forward = (gbVec4) {1.0f, 0.0f, 0.0f, 1.0f};
        }
        gbMat4 cameraToWorld;
        gb_mat4_inverse(&cameraToWorld, &camera->worldToCamera);
        gb_mat4_mul_vec4(&forward, &cameraToWorld, forward);
        gb_vec3_sub(&forward.xyz, forward.xyz, cameraToWorld.col[3].xyz);
        gb_vec3_norm(&forward.xyz, forward.xyz);
        if(dir == 's' || dir == 'a') amount *= -1.0f;
        gb_vec3_mul(&forward.xyz, forward.xyz, amount);
        gb_vec3_add(&cameraToWorld.col[3].xyz, cameraToWorld.col[3].xyz, forward.xyz);
        gb_mat4_inverse(&camera->worldToCamera, &cameraToWorld);
    }
    else if(dir == 'i' || dir == 'j' || dir == 'k' || dir == 'l') {
        gbMat4 wtc;
        wtc = camera->worldToCamera;
        gbMat4 cameraToWorld;
        gb_mat4_inverse(&cameraToWorld, &camera->worldToCamera);

        float deg = amount * M_PI / 180;
        if(dir=='j' || dir == 'i') {
            deg *= -1.0f;
        }

        gbMat4 rot;
        float c = cosf(deg), s = sinf(deg);
        float x, y, z;
        x = cameraToWorld.col[3].e[0];
        y = cameraToWorld.col[3].e[1];
        z = cameraToWorld.col[3].e[2];

        if(dir == 'j' || dir == 'l') { // Camera yaw
            rot = (gbMat4)
                    {c,0,-s,0,
                     0,1,0,0,
                     s,0,c,0,
                     (1-c)*x-s*z,0,(1-c)*z+s*x,1};
            gb_mat4_mul(&camera->worldToCamera, &wtc, &rot);
        }
        else if(dir == 'i' || dir == 'k') { // Camera pitch
            rot = (gbMat4)
                    {1,0,0,0,
                     0,c,s,0,
                     0,-s,c,0,
                     0,0,0,1};
            gb_mat4_mul(&camera->worldToCamera, &rot, &wtc);
        }
    }
    else if(dir == 'q' || dir == 'e') {
    	gbMat4 wtc;
		wtc = camera->worldToCamera;
		gbMat4 cameraToWorld;
		gb_mat4_inverse(&cameraToWorld, &camera->worldToCamera);
		cameraToWorld.col[3].e[1] += dir=='q'?amount:-amount;
		gb_mat4_inverse(&camera->worldToCamera, &cameraToWorld);
    }
}

void renCameraRotateAboutY(renCamera* camera, float deg) {
    gbMat4 cameraToWorld;
    gb_mat4_inverse(&cameraToWorld, &camera->worldToCamera);
    float rx = cameraToWorld.col[3].e[0];
    float rz = cameraToWorld.col[3].e[2];
    float r = sqrtf(rx*rx+rz*rz);
    float degSide = (180.0f - deg) / 2;

    degSide = gb_to_radians(degSide);

    float forward = r * cosf(degSide) * 2 * cosf(degSide);
    float pan = r * cosf(degSide) * 2 * sinf(degSide);
    renCameraTransform(camera, 'd', pan);

    gb_mat4_inverse(&cameraToWorld, &camera->worldToCamera);
    float phi = rz>0?atanf(rx/rz):atanf(rx/rz)+M_PI;
    float dx = forward * sinf(phi);
    float dz = forward * cosf(phi);
    cameraToWorld.col[3].e[0] -= dx;
    cameraToWorld.col[3].e[2] -= dz;
    gb_mat4_inverse(&camera->worldToCamera, &cameraToWorld);

    renCameraTransform(camera, 'j', deg);
}

void renCameraRotateAboutCameraX(renCamera* camera, float deg) {

}
