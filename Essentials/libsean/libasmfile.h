//
//  libasmfile.h
//  Sean16CPU
//
//  Created by Frida Boleslawska on 02.10.24.
//

#ifndef libasmfile_h
#define libasmfile_h

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#define MAX_INSTRUCTIONS 1000
#define MAX_ARGS 6

uint8_t** readasm(const char *filename);
void storeasm(const char *filename, uint8_t *values, size_t size);

#endif /* libasmfile_h */
