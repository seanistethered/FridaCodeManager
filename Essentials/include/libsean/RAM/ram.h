//
//  ram.h
//  Sean16CPU
//
//  Created by Frida Boleslawska on 27.09.24.
//

#ifndef ram_h
#define ram_h

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>

#define S_RAMSIZE_MAX 100000

typedef struct {
    uint16_t id;
    uint8_t *memory[1024][6];
} page_t;

page_t* genpage(void);
void freepage(page_t *page);

#endif /* ram_h */
