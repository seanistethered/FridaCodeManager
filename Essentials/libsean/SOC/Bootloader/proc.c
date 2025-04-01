//
//  proc.c
//  Sean16CPU
//
//  Created by Frida Boleslawska on 26.09.24.
//

#include "proc.h"
#include <RAM/ram.h>

static proc *processes[UINT16_MAX];

static uint16_t pidn = 0;

proc* proc_fork(uint8_t binmap[1000][6]) {
    proc *pid = malloc(sizeof(proc));

    pid->pid = pidn;
    pid->state = 1;
    pid->page[0] = genpage();
    pid->page[1] = genpage();
    pid->page[2] = genpage();

    if(pid->page[0] == NULL) {
        return NULL;
    } else if(pid->page[1] == NULL) {
        freepage(pid->page[0]);
        return NULL;
    } else if(pid->page[2] == NULL) {
        freepage(pid->page[0]);
        freepage(pid->page[1]);
        return NULL;
    }

    for(int i = 0; 6 > i; i++) {
        for(int j = 0; 1024 > j; j++) {
            *pid->page[0]->memory[i][j] = binmap[i][j];
        }
    }
    
    processes[pidn] = pid;
    pidn++;
    
    return pid;
}

void proc_kill(proc *process) {
    uint16_t pidt = process->pid;
    
    freepage(processes[pidt]->page[0]);
    freepage(processes[pidt]->page[1]);
    freepage(processes[pidt]->page[2]);
    
    free(processes[pidt]);
}
