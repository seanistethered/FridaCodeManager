#ifndef LIBZIP_H
#define LIBZIP_H

#import <Foundation/Foundation.h>

/**
 * @brief Functions to handle zip files
 *
 */
int libzip_zip(NSString *path, NSString *dest, BOOL keepParent);
int libzip_unzip(NSString *path, NSString *dest);

#endif // LIBZIP_H
