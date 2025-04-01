//
//  proc.h
//  Sean16CPU
//
//  Created by Frida Boleslawska on 26.09.24.
//

#ifndef proc_h
#define proc_h

#include <RAM/ram.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <pthread/pthread.h>

typedef struct {
    uint8_t pid;            // process identifier
    uint8_t state;          // 0 = not running / 1 = running / 2 = paused / 3 = killed
    pthread_t thread;       // processes thread;
    page_t *page[126];        // process pages
} proc;

proc* proc_fork(uint8_t binmap[1000][6]);
void proc_kill(proc *process);

#endif /* proc_h */
