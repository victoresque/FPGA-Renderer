#include "texLoader.h"
#include "lodepng.h"
#include <stdlib.h>
#include <math.h>
#include "../REN/renDefine.h"
#include "../sd/sd.h"

unsigned char* texLoad(const char* filepath) {
    unsigned char* texOriginal;
    unsigned char* texDownsampled;
    unsigned int w;
    unsigned int h;
    if(lodepng_decode24_file(&texOriginal, &w, &h, filepath) != 0) {
        printf("Fail loading texture: \"%s\" ", filepath);
        return NULL;
    }

    texDownsampled = (unsigned char*) malloc(sizeof(unsigned char)
                                             * FRAME_WIDTH * FRAME_HEIGHT * 3);
    int i, j, k;
    for(j=0; j<FRAME_HEIGHT; j++) {
        for(i=0; i<FRAME_WIDTH; i++) {
            int io = (int)((float)i * w / FRAME_WIDTH);
            int jo = (int)((float)j * h / FRAME_HEIGHT);
            io = io<w?io:w-1;
            jo = jo<h?jo:h-1;

            for(k=0; k<3; k++) {
                texDownsampled[(j*FRAME_WIDTH+i)*3+k]
                    = texOriginal[(jo*w+io)*3+k];
            }
        }
    }

    FILE* dump = fopen("/Users/victorhuang/Desktop/texdump.ppm", "w");
    fprintf(dump, "P6\n%d %d\n255\n", FRAME_WIDTH, FRAME_HEIGHT);
    fwrite(texDownsampled, 3, FRAME_WIDTH*FRAME_HEIGHT, dump);
    fclose(dump);

    free(texOriginal);
    return texDownsampled;
}

unsigned char* texLoadSD(const char* filepath) {
	printf("Loading texture: \"%s\"...\n", filepath);

	size_t datalen;
	const char* data = sdReadFile(filepath, &datalen);

	unsigned char* texOriginal;
	unsigned char* texDownsampled;
	unsigned int w;
	unsigned int h;

	if(lodepng_decode24(&texOriginal, &w, &h, data, datalen) != 0) {
		printf("Fail loading texture: \"%s\".\n", filepath);
		return NULL;
	}

	texDownsampled = (unsigned char*) malloc(sizeof(unsigned char)
											 * FRAME_WIDTH * FRAME_HEIGHT * 3);
	int i, j, k;
	for(j=0; j<FRAME_HEIGHT; j++) {
		for(i=0; i<FRAME_WIDTH; i++) {
			int io = (int)((float)i * w / FRAME_WIDTH);
			int jo = (int)((float)j * h / FRAME_HEIGHT);
			io = io<w?io:w-1;
			jo = jo<h?jo:h-1;

			for(k=0; k<3; k++) {
				texDownsampled[(j*FRAME_WIDTH+i)*3+k]
					= texOriginal[(jo*w+io)*3+k];
			}
		}
	}

	free(data);
	free(texOriginal);
	return texDownsampled;
}
