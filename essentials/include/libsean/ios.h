//
// ios.h
//
// Created by SeanIsNotAConstant on 22.10.24
//

#import <Foundation/Foundation.h>
#import "Peripherals/Display/Display.h"
#import "Peripherals/Mouse/Mouse.h"

void kickstart(NSString *path);
TouchTracker *getTracker(void *arg);
void send_cpu(uint8_t);
