#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString* contgen(void);

/**
 * @brief This function is for downloading files online
 *
 */
void fdownload(NSString *urlString, NSString *destinationPath) {
    // Prepare to download
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];

    // Semaphore
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    // Download Task
    printf("downloading \"%s\"\n", [urlString UTF8String]);
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            printf("error: download failed: %s\n", [[error localizedDescription] UTF8String]);
            dispatch_semaphore_signal(semaphore);
            return; // Exit early if there is an error
        }

        // Determine the destination path
        NSString *finalDestinationPath = destinationPath;
        if (![finalDestinationPath isAbsolutePath]) {
            // If the destination path is relative, use the Documents directory
            NSString *documentsDirectory = contgen();
            finalDestinationPath = [documentsDirectory stringByAppendingPathComponent:destinationPath];
        }

        // Move File
        NSError *fileError;
        NSFileManager *fileManager = [NSFileManager defaultManager];

        // Check if destination file already exists
        if ([fileManager fileExistsAtPath:finalDestinationPath]) {
            printf("Warning: file already exists at destination path. Overwriting.\n");
            [fileManager removeItemAtPath:finalDestinationPath error:nil]; // Optionally remove existing file
        }

        BOOL success = [fileManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:finalDestinationPath] error:&fileError];

        if (!success) {
            printf("error: moving file failed: %s\n", [[fileError localizedDescription] UTF8String]);
        } else {
            printf("File moved to: %s\n", [finalDestinationPath UTF8String]);
        }

        dispatch_semaphore_signal(semaphore);
    }];

    [downloadTask resume];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    printf("done :3\n");
}
