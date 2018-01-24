#ifndef _RENRENDER_H_
#define _RENRENDER_H_

#include "renDefine.h"
#include "renScene.h"
#include "renCamera.h"
#include "renObject.h"

typedef struct {
    renFrameBuf*    frameBuf;

} renRenderer;

renRenderer* renInitRenderer();

void renRenderScene(renRenderer* renderer, renScene* scene, renCamera* camera);
void renInitFrameBuf(renRenderer* renderer);
void renInitZBuf(renRenderer* renderer, renCamera* camera);
void renRenderObject(renRenderer* renderer, renObject* object, renCamera* camera);
void renRenderTriangle(renRenderer* renderer, renCamera* camera, gbVec3 light, renObject* object, renVertex* vertex);
void renRenderFrameBuf(renRenderer* renderer);

#endif
