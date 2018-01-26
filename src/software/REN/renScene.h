#ifndef _RENSCENE_H_
#define _RENSCENE_H_

#include "renDefine.h"
#include "renObject.h"

typedef struct {
    renObject*      object;
} renScene;

renScene*   renInitScene();

#endif
