#include "sd.h"

#include <stdio.h>
#include <stdlib.h>
#include "altera_up_sd_card_avalon_interface.h"

int sdLoad() {
	alt_up_sd_card_dev *device_reference = NULL;
	device_reference = alt_up_sd_card_open_dev(SD_CONTROLLDER_NAME);
	if (device_reference != NULL) {
		while(1) {
			if (alt_up_sd_card_is_Present()) {
				printf("SD card connected.\n");
				if (alt_up_sd_card_is_FAT16()) {
					printf("FAT16 file system detected.\n");
					return 1;
				} else {
					printf("Unknown file system.\n");
					return 0;
				}
			}
		}
	}
}
const char* sdReadFile(const char* filepath, size_t* datalen) {
	short int fileHandle;
	fileHandle = alt_up_sd_card_fopen(filepath, 0);
	if(fileHandle < 0) {
		printf("Fail loading file: \"%s\".\n", filepath);
		return NULL;
	}

	char* data;
	data = (char*) malloc(sizeof(data) * SD_MAXFILESIZE);

	short int databyte;
	int i = 0;
	while((databyte = alt_up_sd_card_read(fileHandle)) >= 0) {
		data[i] = (char) databyte;
		i++;
	}
	data[i] = 0;
	*datalen = i+1;

	alt_up_sd_card_fclose(fileHandle);
	return data;
}

void sdTest() {
    alt_up_sd_card_dev *device_reference = NULL;
    int connected = 0;
    device_reference = alt_up_sd_card_open_dev(SD_CONTROLLDER_NAME);
    if (device_reference != NULL) {
        while(1) {
            if ((connected == 0) && (alt_up_sd_card_is_Present())) {
				printf("Card connected.\n");
				if (alt_up_sd_card_is_FAT16()) {
                    printf("FAT16 file system detected.\n");
                    break;
                } else {
                    printf("Unknown file system.\n");
                }
                connected = 1;
            } else if ((connected == 1) && (alt_up_sd_card_is_Present() == false)) {
                printf("Card disconnected.\n");
                connected = 0;
            }
        }
    }
}
