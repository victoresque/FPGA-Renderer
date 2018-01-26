#ifndef _RENOBJECT_H_
#define _RENOBJECT_H_

#include "renDefine.h"

typedef struct {
    int v_idx, vt_idx, vn_idx;
} renVertex;

typedef struct {
    size_t          numTris;
    renVertex*      tri;            // size = numTris*3

    size_t          numVerts;
    gbVec3*         vert;          // size = numVerts

    size_t          numNormals;
    gbVec3*         normal;        // size = numNormals

    size_t          numTexCoords;
    gbVec2*         texCoord;      // size = numTexCoords

    unsigned char*  texture;
} renObject;

#endif
