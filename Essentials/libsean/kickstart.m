//
//  kickstart.c
//  Sean16CPU
//
//  Created by Frida Boleslawska on 26.09.24.
//

#import <Foundation/Foundation.h>

#include "Sean16.h"
#include "libasmfile.h"
#include <Bootloader/bootloader.h>
#include <compiler.h>

void kickstart(NSString *path) {
    uint8_t **asmData = sean16compiler([NSString stringWithFormat:@"sean16cmp %@ void", path]);
    
    if (asmData == NULL) {
        return;
    }
    
    uint8_t binmap[1000][6] = {0};

    for (int i = 0; i < 1000; i++) {
        if (asmData[i] != NULL) {
            memcpy(binmap[i], asmData[i], sizeof(binmap[i]));
        }
    }

for (size_t i = 0; i < 6; ++i) {
        free(asmData[i]);
    }

    free(asmData);
    
    bootloader(binmap);
}
