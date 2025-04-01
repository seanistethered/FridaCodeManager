//
//  Sean16.h
//  Sean16CPU
//
//  Created by Frida Boleslawska on 05.10.24.
//

#ifndef Sean16_h
#define Sean16_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Peripherals/Display/Display.h>
#import <Peripherals/Mouse/Mouse.h>

#include <stdint.h>
#include <unistd.h>

void kickstart(NSString *path);
TouchTracker *getTracker(void *arg);

#define S_CPU_REGISTER_MAX 64
//#define S_RAMSIZE_MAX 10000000

#endif /* Sean16_h */
