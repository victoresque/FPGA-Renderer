#include "renRender.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

renRenderer* renInitRenderer() {
    renRenderer* renderer;
    renderer = (renRenderer*) malloc(sizeof(renRenderer));

    renderer->frameBuf = VIPFR_Init(VFR_BASE, (void *)FRAME0_ADDR, (void *)FRAME1_ADDR, FRAME_WIDTH, FRAME_HEIGHT);
    VIPFR_Go(renderer->frameBuf, TRUE);
    vid_clean_screen(renderer->frameBuf, 0xff000000);
    VIPFR_ActiveDrawFrame(renderer->frameBuf);
    vid_clean_screen(renderer->frameBuf, 0xff000000);
    VIPFR_ActiveDrawFrame(renderer->frameBuf);

    return renderer;
}

void renRenderScene(renRenderer* renderer, renScene* scene, renCamera* camera) {
    renInitFrameBuf(renderer);
    renInitZBuf(renderer, camera);
    renRenderObject(renderer, scene->object, camera);
    renRenderFrameBuf(renderer);
}

void renInitFrameBuf(renRenderer* renderer) {
    size_t bufSize = FRAME_WIDTH * FRAME_HEIGHT;
    int i;
    void* addr = VIPFR_GetDrawFrame(renderer->frameBuf);
    for(i=0; i<bufSize; i++) {
        IOWR_32DIRECT( addr+i*4, 0, 0xff000000);
    }
}

void renInitZBuf(renRenderer* renderer, renCamera* camera) {
    float farClippingPlane = camera->farClippingPlane;
    size_t zbufSize = FRAME_WIDTH * FRAME_HEIGHT;
    int i;
    for(i=0; i<zbufSize; i++) {
        IOWR_32DIRECT(ZBUF_ADDR+i*4, 0, *(unsigned int*)&farClippingPlane);
    }
}
static float triArea(gbVec2 v0, gbVec2 v1, gbVec2 v2) { //v20xv10
    return (v2.e[0]-v0.e[0])*(v1.e[1]-v0.e[1]) - (v1.e[0]-v0.e[0])*(v2.e[1]-v0.e[1]);
}

static void convertToRaster(gbVec3* raster, gbVec3* cam, gbVec3* pt, renCamera* camera) {
    gbVec4 ptWorld = {pt->e[0], pt->e[1], pt->e[2], 1.0f};
    gbVec4 ptCam;
    gb_mat4_mul_vec4(&ptCam, &camera->worldToCamera, ptWorld);
    *cam = ptCam.xyz;

    gbVec2 ptScreen;
    ptScreen.e[0] = -ptCam.e[0] * camera->nearClippingPlane/ptCam.e[2];
    ptScreen.e[1] = -ptCam.e[1] * camera->nearClippingPlane/ptCam.e[2];
    gbVec2 ptNDC;
    ptNDC.e[0] = 2*ptScreen.e[0]/(camera->right-camera->left)
    + (camera->right+camera->left)/(camera->right-camera->left);
    ptNDC.e[1] = 2*ptScreen.e[1]/(camera->top-camera->bottom)
    + (camera->top+camera->bottom)/(camera->top-camera->bottom);

    raster->e[0] = (ptNDC.e[0]+1)/2 * FRAME_WIDTH;
    raster->e[1] = (1-ptNDC.e[1])/2 * FRAME_HEIGHT;
    raster->e[2] = -ptCam.e[2];
}

static void convertToCamera(gbVec3* cam, gbVec3* pt, renCamera* camera) {
    gbVec4 ptWorld = {pt->e[0], pt->e[1], pt->e[2], 1.0f};
    gbVec4 ptCam;
    gb_mat4_mul_vec4(&ptCam, &camera->worldToCamera, ptWorld);
    *cam = ptCam.xyz;
}
static void getCameraLight(gbVec3* light, renCamera* camera) {
    gbVec4 forward;
    forward = (gbVec4) {0.0f, 0.0f, 1.0f, 1.0f};
    gbMat4 cameraToWorld;
    gb_mat4_inverse(&cameraToWorld, &camera->worldToCamera);
    gb_mat4_mul_vec4(&forward, &cameraToWorld, forward);
    gb_vec3_sub(&forward.xyz, forward.xyz, cameraToWorld.col[3].xyz);
    gb_vec3_norm(light, forward.xyz);
}
void renRenderObject(renRenderer* renderer, renObject* object, renCamera* camera) {
    size_t i;
    gbVec3 vLight;
    getCameraLight(&vLight, camera);
    for(i=0; i<object->numTris; i++) {
        renRenderTriangle(renderer, camera, vLight, object, object->tri+i*3);
    }
}
void renRenderTriangle(renRenderer* renderer, renCamera* camera, gbVec3 light, renObject* object, renVertex* vertex) {
    // v is triangle vertices in world space
	int i, j;
	gbVec3 v[3];
	for(i=0; i<3; i++) {
		v[i] = object->vert[vertex[i].v_idx];
	}

    gbVec3 vWorld[3] = {v[0], v[1], v[2]};
    gbVec3 vCam[3];

    convertToRaster(&v[0], &vCam[0], &vWorld[0], camera);
    convertToRaster(&v[1], &vCam[1], &vWorld[1], camera);
    convertToRaster(&v[2], &vCam[2], &vWorld[2], camera);
    // v is triangle vertices in raster space

    if(   v[0].e[2] < camera->nearClippingPlane
       && v[1].e[2] < camera->nearClippingPlane
       && v[2].e[2] < camera->nearClippingPlane) return;

    float xmin = gb_min3(v[0].e[0], v[1].e[0], v[2].e[0]);
    float xmax = gb_max3(v[0].e[0], v[1].e[0], v[2].e[0]);
    float ymin = gb_min3(v[0].e[1], v[1].e[1], v[2].e[1]);
    float ymax = gb_max3(v[0].e[1], v[1].e[1], v[2].e[1]);

    if(xmin >= FRAME_WIDTH || xmax < 0 || ymin >= FRAME_HEIGHT || ymax < 0) return;

    float area = triArea(v[0].xy, v[1].xy, v[2].xy);
    if(area < 0) return;

    // Pre-calculate 1/z for perspective-correct interpolation
    v[0].e[2] = 1/v[0].e[2];
    v[1].e[2] = 1/v[1].e[2];
    v[2].e[2] = 1/v[2].e[2];

    int imin = gb_max(0, xmin-1);
    int imax = gb_min(FRAME_WIDTH-1, xmax+1);
    int jmin = gb_max(0, ymin-1);
    int jmax = gb_min(FRAME_HEIGHT-1, ymax+1);

    gbVec3 vn, v20, v10;
    gb_vec3_sub(&v20, vCam[2], vCam[0]);
    gb_vec3_sub(&v10, vCam[1], vCam[0]);
    gb_vec3_cross(&vn, v10, v20);
    gb_vec3_norm(&vn, vn);

    gbVec3 vNorm[3];
	float fNorm[3];
	int noNormal = 0;
	for(i=0; i<3; i++) {
		if(object->numNormals) {
			vNorm[i] = object->normal[vertex[i].vn_idx];
			fNorm[i] = gb_vec3_dot(light, vNorm[i]);
		}
		else {
			noNormal = 1;
		}
	}
    /*
            Type 1          Type 2          Type3
            +               +               +
           + +             +       +         +  +
          +   +           +    +              +    +
             + +         +  +                  +      +
                +       +                       +
     */

    int jstart = jmin;
    for(i=0; i<3; i++) {
        if(xmin == v[i].e[0]) {
            jstart = (int)v[i].e[1];
            if(jstart < 0)             jstart = 0;
            if(jstart >= FRAME_HEIGHT-1) jstart = FRAME_HEIGHT-1;
            break;
        }
    }

    int insideTriangle;
    int dir; // 0: up, 1: down
    int increment;

    /* TEXTURE */
	gbVec2 st[3];
	for(i=0; i<3; i++) {
		st[i] = object->texCoord[vertex[i].vt_idx];
	}
	/* */

    void* frameBufAddr = VIPFR_GetDrawFrame(renderer->frameBuf);
    for(dir=0; dir<=1; dir++) {
        if(dir == 0)    j = jstart, increment = -1;
        else            j = jstart, increment = 1;

        int istart = imin;
        for(; j<=jmax && j>=jmin; j+=increment) {
            insideTriangle = 0;
            for(i=istart; i<=imax; i++) {
            	gbVec2 vp;
                float w0, w1, w2;

                vp = (gbVec2) {0.5f+i, 0.5f+j};
                w0 = triArea(v[1].xy, v[2].xy, vp);
                w1 = triArea(v[2].xy, v[0].xy, vp);
                w2 = triArea(v[0].xy, v[1].xy, vp);

                if( w0>=0 && w1>=0 && w2>=0 ) {
                    if(!insideTriangle) {
                        if(j!=jstart) {
                            istart = i;
                        }
                        insideTriangle = 1;
                    }

                    w0 /= area;
                    w1 /= area;
                    w2 /= area;

                    float oneOverZ = w0*v[0].e[2] + w1*v[1].e[2] + w2*v[2].e[2];
                    float z = 1/oneOverZ;

                    if(z < camera->nearClippingPlane) continue;
                    unsigned int zBufVal = IORD_32DIRECT(ZBUF_ADDR+(j*FRAME_WIDTH+i)*4, 0);
                    float zBufValf = *(float*)&zBufVal;

                    if(z < zBufValf) {
                    	IOWR_32DIRECT(ZBUF_ADDR+(j*FRAME_WIDTH+i)*4, 0, *(unsigned int*)&z);
                        //calculate original camera coord
                        gbVec3 vdiff;
                        float facing;

                        if(noNormal) {
                        	float x = -z*(w0*vCam[0].e[0]*v[0].e[2] + w1*vCam[1].e[0]*v[1].e[2] + w2*vCam[2].e[0]*v[2].e[2]);
							float y = -z*(w0*vCam[0].e[1]*v[0].e[2] + w1*vCam[1].e[1]*v[1].e[2] + w2*vCam[2].e[1]*v[2].e[2]);
							vdiff = (gbVec3){-x,-y,z};
							gb_vec3_norm(&vdiff, vdiff);
							facing = gb_vec3_dot(vn, vdiff);
                        }
                        else {
                        	// Gouraud
                        	facing = w0*fNorm[0]+w1*fNorm[1]+w2*fNorm[2];
                        }

                        if(facing<0) facing=0;
                        if(facing>1) facing=1;
                        gbVec2 stp;
						stp.x = z*(w0*st[0].x*v[0].e[2]+w1*st[1].x*v[1].e[2]+w2*st[2].x*v[2].e[2]);
						stp.y = z*(w0*st[0].y*v[0].e[2]+w1*st[1].y*v[1].e[2]+w2*st[2].y*v[2].e[2]);
						//stp.x = stp.x;
						stp.y = 1-stp.y;

						int jTex = (int)(stp.y * FRAME_HEIGHT);
						int iTex = (int)(stp.x * FRAME_WIDTH);
						jTex = jTex<FRAME_HEIGHT?jTex:FRAME_HEIGHT-1;
						iTex = iTex<FRAME_WIDTH?iTex:FRAME_WIDTH-1;

						vdiff = (gbVec3){-vCam[0].e[0],-vCam[0].e[1],-vCam[0].e[2]};
						gb_vec3_norm(&vdiff, vdiff);

                        unsigned int color, texR, texG, texB;
                        texR = object->texture[(jTex*FRAME_WIDTH+iTex)*3+0]*facing;
                        texG = object->texture[(jTex*FRAME_WIDTH+iTex)*3+1]*facing;
                        texB = object->texture[(jTex*FRAME_WIDTH+iTex)*3+2]*facing;
                        color = (0xff<<24)+(texR<<16)+(texG<<8)+texB;
                        IOWR_32DIRECT( frameBufAddr+(j*FRAME_WIDTH+i)*4, 0, color);
                    }
                }
                else if(insideTriangle) {
                    insideTriangle = 0;
                    break;
                }
            }
        }
    }
}

void renRenderFrameBuf(renRenderer* renderer) {
	void* addrShow = VIPFR_GetDrawFrame(renderer->frameBuf);
	VIPFR_ActiveDrawFrame(renderer->frameBuf);
	void* addrHide = VIPFR_GetDrawFrame(renderer->frameBuf);

	size_t bufSize = FRAME_WIDTH * FRAME_HEIGHT;
	int i;
	for(i=0; i<bufSize; i++) {
		IOWR_32DIRECT( addrHide+i*4, 0, IORD_32DIRECT(addrShow+i*4, 0));
	}
}


