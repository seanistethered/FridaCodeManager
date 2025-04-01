//
//  Sean16.c
//  Sean16CPU
//
//  Created by Frida Boleslawska on 26.09.24.
//

#include "../Sean16.h"
#include "peripheral.h"
#include "rdrand.h"
#include "cpu.h"
#include <Bootloader/bootloader.h>
#include <GPU/gpu.h>
#import <CoreGraphics/CoreGraphics.h>

static uint16_t reg[S_CPU_REGISTER_MAX];
static uint16_t dummyreg[5];
static uint8_t cpu_signal = 0;

void send_cpu(uint8_t signal)
{
    cpu_signal = signal;
}

uint16_t* getPointer(uint16_t value, uint8_t quad)
{
    if (value < 65) {
        return &reg[value];
    } else {
        dummyreg[quad] = value - 65;
        return &dummyreg[quad];
    }
}

void evaluate(int *i, int mode, int reg1, int reg2, int jmpaddr)
{
    if(mode == 0) { // EQUALS
        if(reg1 == reg2) {
            *i = jmpaddr - 1;
        }
    } else if(mode == 1) {
        if(reg1 > reg2) {
            *i = jmpaddr - 1;
        }
    } else if(mode == 2) {
        if(reg1 < reg2) {
            *i = jmpaddr - 1;
        }
    } else if(mode == 3) {
        if(reg1 != reg2) {
            *i = jmpaddr - 1;
        }
    }
}

void *execute(void *arg)
{
    cpu_signal = 0;

    proc *proccess = (proc *)arg;

    for(int i = 0; i < S_CPU_REGISTER_MAX; i++) {
        reg[i] = 0;
    }

    uint16_t *ptr1;
    uint16_t *ptr2;
    uint16_t *ptr3;
    uint16_t *ptr4;
    uint16_t *ptr5;
    uint8_t instruction;

    printf("[cpu] initialised\n");
    printf("[cpu] executing\n");

    for(int i = 0; i < 1000; i++) {
        if(cpu_signal != 0) {
            return NULL;
        }

        instruction = *(proccess->page[0]->memory[i][0]);

        ptr1 = getPointer(*(proccess->page[0]->memory[i][1]), 1);
        ptr2 = getPointer(*(proccess->page[0]->memory[i][2]), 2);
        ptr3 = getPointer(*(proccess->page[0]->memory[i][3]), 3);
        ptr4 = getPointer(*(proccess->page[0]->memory[i][4]), 4);
        ptr5 = getPointer(*(proccess->page[0]->memory[i][5]), 5);

        switch(instruction) {
            case EXT: printf("[cpu] exited on line %d\n", i); return 0;
            case STO: *ptr1 = *ptr2; break;
            case ADD: *ptr1 += *ptr2; break;
            case SUB: *ptr1 -= *ptr2; break;
            case MUL: *ptr1 *= *ptr2; break;
            case DIV: *ptr1 /= *ptr2; break;
            case DSP: printf("[cpu] %d\n", *ptr1); break;
            case JMP: i = *ptr1 -1; break;
            case IFQ: evaluate(&i, *ptr1, *ptr2, *ptr3, *ptr4); break;
            case MUS: periphalMUS(proccess->page[2], ptr1, ptr2, ptr3); break;
            case RAN: rdrand(ptr1, *ptr2, *ptr3); break;
            case GPX: usleep(50); setpixel(*ptr1, *ptr2, *ptr3); break;
            case GDL: usleep(50); drawLine(*ptr1, *ptr2, *ptr3, *ptr4, *ptr5); break;
            case GDC: usleep(50); drawCharacter(*ptr1, *ptr2, *ptr3, *ptr4); break;
            case GCS: usleep(50); clearScreen(); break;
            case GGC: usleep(50); *ptr1 = getColorOfPixel(*ptr2, *ptr3); break;
            case SSP: sleep(*ptr1); break;
            case NSP: usleep(*ptr1 * *ptr2 * *ptr3); break;
            default: printf("[cpu] 0x%02x is illegal\n", i); return NULL;
        }
    }

    return NULL;
}
