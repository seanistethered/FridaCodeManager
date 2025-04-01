#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <sys/utsname.h>
#include <sys/sysctl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
#include <stdbool.h>

#define PROC_PIDPATHINFO_MAXSIZE 1024

extern int proc_pidpath(int pid, void * buffer, uint32_t  buffersize);

NSString *container_saved = nil;

/**
 * @brief This is a interface of a NSObject made by apple
 *
 */
@interface MCMContainer : NSObject
- (NSURL *)url;
+ (instancetype)containerWithIdentifier:(NSString *)identifier
                      createIfNecessary:(BOOL)createIfNecessary
                                existed:(BOOL *)existed
                                  error:(NSError **)error;
@end

@interface MCMAppDataContainer : MCMContainer
@end

/**
 * @brief This function is to get the darwin hosts hostname
 *
 */
NSString *ghost(void)
{
    return [[NSProcessInfo processInfo] hostName];
}

/**
 * @brief This function is to get the darwin hosts os version
 *
 */
NSString *gosver(void)
{
    return [[UIDevice currentDevice] systemVersion];
}

/**
 * @brief This function is to get the OS name of the darwin host
 *
 */
NSString *gos(void)
{
    return [[UIDevice currentDevice] systemName];
}

/**
 * @brief This function is to get the OS build number of the darwin host
 *
 */
NSString *gosb(void)
{
    size_t size;
    sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    char *version = malloc(size);
    sysctlbyname("kern.osversion", version, &size, NULL, 0);
    NSString *buildNumber = [NSString stringWithUTF8String:version];
    free(version);
    return buildNumber;
}

/**
 * @brief This function is to get the model name of the darwin host
 *
 */
NSString *gmodel(void)
{
    struct utsname systemInfo;
    uname(&systemInfo);

    NSString *modelName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return modelName;
}

/**
 * @brief This function is to get the cpu name of the darwin host(specifically iPhone)
 *
 */
NSString *gcpu(void)
{
    NSString *machine = gmodel();
    NSString *iphoneFamily = [machine substringToIndex:[machine length] - 2];

    NSDictionary *cpuNames = @{
        @"iPhone1": @"APL0098",
        @"iPhone2": @"APL0098",
        @"iPhone3": @"Apple A4",
        @"iPhone4": @"Apple A5",
        @"iPhone5": @"Apple A6",
        @"iPhone6": @"Apple A7",
        @"iPhone7": @"Apple A8",
        @"iPhone8": @"Apple A9",
        @"iPhone9": @"Apple A10 Fusion",
        @"iPhone10": @"Apple A11 Bionic",
        @"iPhone11": @"Apple A12 Bionic",
        @"iPhone12": @"Apple A13 Bionic",
        @"iPhone13": @"Apple A14 Bionic",
        @"iPhone14": @"Apple A15 Bionic",
        @"iPhone15": @"Apple A16 Bionic",
        @"iPhone16": @"Apple A16 Bionic",
    };

    NSString *cpuName = cpuNames[iphoneFamily] ?: @"Unknown";
    return cpuName;
}

/**
 * @brief This function is to get the darwin hosts architecture
 *
 */
NSString *garch(void)
{
    NSString *machine = gmodel();
    NSString *iphoneFamily = [machine substringToIndex:[machine length] - 2];
    
    NSDictionary *cpuNames = @{
        @"iPhone1": @"armv6",
        @"iPhone2": @"armv6",
        @"iPhone3": @"armv7",
        @"iPhone4": @"armv7",
        @"iPhone5": @"armv7",
        @"iPhone6": @"armv8",
        @"iPhone7": @"armv8",
        @"iPhone8": @"armv8",
        @"iPhone9": @"arm64",
        @"iPhone10": @"arm64",
        @"iPhone11": @"arm64e",
        @"iPhone12": @"arm64e",
        @"iPhone13": @"arm64e",
        @"iPhone14": @"arm64e",
        @"iPhone15": @"arm64e",
        @"iPhone16": @"arm64e",
    };

    NSString *cpuName = cpuNames[iphoneFamily] ?: @"Unknown";
    return cpuName;
}

/**
 * @brief This function is to generate a document container in case it doest exist yet
 *
 */
NSString* contgen(void)
{
    if(container_saved == nil) {
        MCMAppDataContainer* container = [MCMAppDataContainer containerWithIdentifier:NSBundle.mainBundle.bundleIdentifier createIfNecessary:YES existed:nil error:nil];
        container_saved = container.url.path;
    }

    return container_saved;
}

/**
 * @brief This function is to kill a process using its Bundle identifier
 *
 */
void killTaskWithBundleID(NSString *bundleID)
{
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t miblen = 4;

    size_t size;
    sysctl(mib, miblen, NULL, &size, NULL, 0);
    struct kinfo_proc *process = malloc(size);

    if (sysctl(mib, miblen, process, &size, NULL, 0) == -1) {
        perror("sysctl");
        free(process);
        return;
    }

    size_t numProcesses = size / sizeof(struct kinfo_proc);

    for (size_t i = 0; i < numProcesses; i++) {
        pid_t pid = process[i].kp_proc.p_pid;
        char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];

        if (proc_pidpath(pid, pathBuffer, sizeof(pathBuffer)) > 0) {
            NSString *executablePath = [NSString stringWithUTF8String:pathBuffer];

            if ([executablePath containsString:bundleID]) {
                NSLog(@"Found process with PID: %d for bundle ID: %@", pid, bundleID);

                if (kill(pid, SIGKILL) == 0) {
                    NSLog(@"Successfully killed process with PID: %d", pid);
                } else {
                    perror("kill");
                }
            }
        }
    }
    free(process);
}

//
void killTaskWithProcessName(NSString *processName)
{
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t miblen = 4;

    size_t size;
    sysctl(mib, miblen, NULL, &size, NULL, 0);
    struct kinfo_proc *process = malloc(size);

    if (sysctl(mib, miblen, process, &size, NULL, 0) == -1) {
        perror("sysctl");
        free(process);
        return;
    }

    size_t numProcesses = size / sizeof(struct kinfo_proc);

    for (size_t i = 0; i < numProcesses; i++) {
        pid_t pid = process[i].kp_proc.p_pid;
        char pathBuffer[PROC_PIDPATHINFO_MAXSIZE];

        if (proc_pidpath(pid, pathBuffer, sizeof(pathBuffer)) > 0) {
            NSString *executablePath = [NSString stringWithUTF8String:pathBuffer];
            NSString *executableName = [executablePath lastPathComponent];

            if ([executableName isEqualToString:processName]) {
                //NSLog(@"Found process with PID: %d for process name: %@", pid, processName);

                if (kill(pid, SIGKILL) == 0) {
                    //NSLog(@"Successfully killed process with PID: %d", pid);
                } else {
                    perror("kill");
                }
            }
        }
    }
    free(process);
}
