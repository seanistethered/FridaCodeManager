//
//  kernel.c
//  Sean16CPU
//
//  Created by Frida Boleslawska on 26.09.24.
//

#include "../../Sean16.h"
#include "bootloader.h"
#import <GPU/gpu.h>
#import <Peripherals/Mouse/Mouse.h>
#import <VFS/fs.h>

extern void *execute(void *arg);

void bootloader(uint8_t binmap[1000][6]) {
    // clear my screen
    clearScreen();

    if(!fs_check()) {
        printf("[soc-bootloader-chip] initialising block device\n");
        fs_init();
        printf("[soc-bootloader-chip] formating block device\n");
        fs_format();
        printf("[soc-bootloader-chip] creating test file\n");
        fs_cfile("test.txt", "Hello, Sean16");
        printf("[soc-bootloader-chip] received file content: %s\n", fs_rfile("test.txt"));
        fs_dfile("test.txt");
    } else {
        printf("[soc-bootloader-chip] block device is already initialised\n");
    }
    
    // INIT
    printf("[soc-bootloader-chip] initialising mouse\n");
    TouchTracker *mouse = getTracker(NULL);
    [mouse startTracking];
    
    // fork process
    printf("[soc-bootloader-chip] forking kernel process\n");
    proc *child_task = proc_fork(binmap);
    if(child_task == NULL) {
        printf("[soc-bootloader-chip] forking process failed\n");
        return;
    }
    
    // peripherials mapping
    printf("[soc-bootloader-chip] mapping peripherals\n");
    *((CGPoint **)&child_task->page[2]->memory[0][0]) = [mouse getPos];
    *((NSInteger **)&child_task->page[2]->memory[0][1]) = [mouse getBtn];
    
    // executing process
    printf("[soc-bootloader-chip] executing kernel process\n");
    execute((void*)child_task);

    // DEINIT
    printf("[soc-bootloader-chip] process has finished execution\n");
    printf("[soc-bootloader-chip] deinitialising mouse\n");
    [mouse stopTracking];

    // killing task
    printf("[soc-bootloader-chip] freeing process\n");
    proc_kill(child_task);
}
