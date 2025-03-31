//
//  rdrand.h
//  Sean16CPU
//
//  Created by Frida Boleslawska on 03.10.24.
//

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>

#ifndef rdrand_h
#define rdrand_h

void rdrand(uint16_t *ptr, uint16_t min, uint16_t max);

#endif /* rdrand_h */
