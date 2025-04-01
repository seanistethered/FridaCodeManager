//
//  cpu.h
//  Sean16CPU
//
//  Created by Frida Boleslawska on 04.10.24.
//

#ifndef cpu_h
#define cpu_h

// CPU - Main
#define EXT   0x00
#define STO   0x01
#define ADD   0x02
#define SUB   0x03
#define MUL   0x04
#define DIV   0x05
#define DSP   0x06     //DEBUG INSTRUCTION
#define JMP   0x07
#define IFQ   0x08
#define RAN   0x0A

// CPU - Peripherals
#define MUS   0x09

// CPU - Clocl
#define SSP   0xB0
#define NSP   0xB1

// GPU - Main
#define GPX   0xA0
#define GDL   0xA1
#define GDC   0xA2
#define GCS   0xA3
#define GGC   0xA4

void *execute(void *arg);

#endif /* cpu_h */
