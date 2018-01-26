//
//  objLoader.c
//  render
//
//  Created by Victor Huang on 5/13/17.
//  Copyright © 2017 Victor Huang. All rights reserved.
//

#include "objLoader.h"
#include <string.h>		// strlen
#include "../sd/sd.h"

static const char* openFile(size_t* len, const char* filepath){
    char* p;
    FILE* f;
    size_t file_size;

    (*len) = 0;

    f = fopen(filepath, "r");
    fseek(f, 0, SEEK_END);
    file_size = ftell(f);
    fclose(f);

    p = (char*) malloc(sizeof(char) * (file_size+1));
    size_t i;
    f = fopen(filepath, "r");
    for(i=0; i<file_size; i++) {
        p[i] = fgetc(f);
    }

    p[i] = 0;
    *len = file_size+1;
    return p;
}

renObject* objLoadSD(const char* filepath) {
	printf("Loading model: \"%s\"...\n", filepath);

	size_t datalen;
	const char* data = sdReadFile(filepath, &datalen);

	tinyobj_attrib_t attrib;
	tinyobj_shape_t* shapes = NULL;
	size_t num_shapes;
	tinyobj_material_t* materials = NULL;
	size_t num_materials;

	unsigned int flags = TINYOBJ_FLAG_TRIANGULATE;
	int ret = tinyobj_parse_obj(&attrib, &shapes, &num_shapes, &materials,
								&num_materials, data, datalen, flags);

	printf("Vertices:       %u\n", attrib.num_vertices);
	printf("Normals:        %u\n", attrib.num_normals);
	printf("Texture coords: %u\n", attrib.num_texcoords);
	printf("Triangles:      %u\n", attrib.num_faces/3);

	renObject* object = (renObject*) malloc(sizeof(renObject));
	object->numTris      = attrib.num_faces/3;
	object->numVerts     = attrib.num_vertices;
	object->numNormals   = attrib.num_normals;
	object->numTexCoords = attrib.num_texcoords;

	object->tri       = (renVertex*) attrib.faces;
	object->vert      = (gbVec3*) attrib.vertices;
	object->normal    = (gbVec3*) attrib.normals;
	object->texCoord  = (gbVec2*) attrib.texcoords;

	free(data);
	return object;
}

renObject* objLoad(const char* filepath) {
    size_t datalen;
    const char* data = openFile(&datalen, filepath);

    tinyobj_attrib_t attrib;
    tinyobj_shape_t* shapes = NULL;
    size_t num_shapes;
    tinyobj_material_t* materials = NULL;
    size_t num_materials;

    unsigned int flags = TINYOBJ_FLAG_TRIANGULATE;
    int ret = tinyobj_parse_obj(&attrib, &shapes, &num_shapes, &materials,
                                &num_materials, data, datalen, flags);

    printf("Vertices:       %u\n", attrib.num_vertices);
    printf("Normals:        %u\n", attrib.num_normals);
    printf("Texture coords: %u\n", attrib.num_texcoords);
    printf("Triangles:      %u\n", attrib.num_faces/3);

    renObject* object = (renObject*) malloc(sizeof(renObject));
    object->numTris      = attrib.num_faces/3;
    object->numVerts     = attrib.num_vertices;
    object->numNormals   = attrib.num_normals;
    object->numTexCoords = attrib.num_texcoords;

    /*
    object->tri       = (renVertex*) malloc(sizeof(renVertex) * object->numTris * 3);
    object->verts     = (gbVec3*) malloc(sizeof(gbVec3) * object->numVerts);
    object->normals   = (gbVec3*) malloc(sizeof(gbVec3) * object->numNormals);
    object->texCoords = (gbVec2*) malloc(sizeof(gbVec2) * object->numTexCoords);
     */

    object->tri       = (renVertex*) attrib.faces;
    object->vert      = (gbVec3*) attrib.vertices;
    object->normal    = (gbVec3*) attrib.normals;
    object->texCoord  = (gbVec2*) attrib.texcoords;

    return object;
}





