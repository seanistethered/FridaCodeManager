//
//  peripheral.m
//  Sean16CPU
//
//  Created by Frida Boleslawska on 01.10.24.
//

#import "peripheral.h"

void periphalMUS(page_t *periphals, uint16_t *x, uint16_t *y, uint16_t *btn) {
    CGPoint *mouseptr = *((CGPoint **)&periphals->memory[0][0]);
    NSInteger *btnptr = *((NSInteger **)&periphals->memory[0][1]);
    
    // getting values
    *x = (uint16_t)mouseptr->x;
    *y = (uint16_t)mouseptr->y;
    *btn = *btnptr;
    
    // reset btnptr
    *btnptr = 0;
}
