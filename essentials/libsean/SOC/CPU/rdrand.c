//
//  rdrand.c
//  Sean16CPU
//
//  Created by Frida Boleslawska on 03.10.24.
//

#include "rdrand.h"
#include <stdlib.h>

void rdrand(uint16_t *ptr, uint16_t min, uint16_t max) {
    if (min > max) {
        uint16_t temp = min;
        min = max;
        max = temp;
    }
    uint16_t rand_val = arc4random_uniform(max - min + 1) + min;
    *ptr = rand_val;
}
