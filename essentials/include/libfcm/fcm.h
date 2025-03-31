#ifndef FCM_H
#define FCM_H

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <mach/mach.h>
#include <unistd.h>

/**
 * @brief Functions to get Information about the darwin host machine
 *
 */
NSString *ghost();
NSString *gosver();
NSString *gos();
NSString *gosb();
NSString *gmodel();
NSString *garch();
NSString *gcpu();

/**
 * @brief Functions to generate a documents container in case it doesnr exist yet
 *
 */
NSString* contgen(void);

void killTaskWithBundleID(NSString *bundleID);
void killTaskWithProcessName(NSString *processName);

#endif // FCM_H
