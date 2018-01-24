#ifndef _SD_H_
#define _SD_H_
#include <stdio.h>

void sdTest();

int sdLoad();
const char* sdReadFile(const char* filepath, size_t* datalen);

#define SD_MAXFILESIZE 1048576

#endif
