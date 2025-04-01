//
// dyexec.h
// libdycall
// Created by SeanIsNotAConstant on October the 19th 2024
//

#ifndef DYEXEC_H
#define DYEXEC_H

#include <Foundation/Foundation.h>

/**
 * @brief This function executes dybinaries
 *
 */
int dyexec(NSString *dylibPath, NSString *arguments);

/**
 * @brief These functions lock or unlock a certain dylib or dybinary
 *
 */
void dylock(NSString *dylibPath);
void dyunlock();

/**
 * @brief This function lists all loaded dylibs or dybinaries
 *
 */
void listdylibs();

#endif // DYEXEC_H
