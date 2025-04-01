//
//  fs-init.m
//  Sean16CPU
//
//  Created by Frida Boleslawska on 05.10.24.
//

#import "fs.h"

VirtualFileSystem *vfs;

// check function
uint8_t fs_check(void) {
    if(vfs == NULL) {
        return 0;
    }

    return 1;
}

// head functions
void fs_init(void) {
    if(vfs == NULL) {
        // Get the path to the app's Documents directory in the app container
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths firstObject];
        
        // Path to the virtual file system file
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"virtualFS.dat"];
        
        NSUInteger fsSize = 10 * 1024 * 1024; // 10 MB virtual file system size
        vfs = [[VirtualFileSystem alloc] initWithFilePath:filePath size:fsSize];
        [vfs formatFileSystem];
    }
}

void fs_format(void) {
    if(vfs != NULL) {
        [vfs formatFileSystem];
    }
}

// management functions
void fs_mkdir(char *path) {
    if(vfs != NULL) {
        vfs_mkdir(vfs.rootDirectory, [NSString stringWithFormat:@"%s", path]);
    }
}

void fs_rmdir(char *path) {
    if(vfs != NULL) {
        vfs_rmdir(vfs.rootDirectory, [NSString stringWithFormat:@"%s", path]);
    }
}

void fs_cfile(char *path, char *content) {
    if(vfs != NULL) {
        vfs_create_file(vfs.rootDirectory, [NSString stringWithFormat:@"%s", path], [[NSString stringWithFormat:@"%s", content] dataUsingEncoding:NSUTF8StringEncoding]);
    }
}

void fs_dfile(char *path) {
    if(vfs != NULL) {
        vfs_delete_file(vfs.rootDirectory, [NSString stringWithFormat:@"%s", path]);
    }
}

const char* fs_rfile(char *path) {
    if(vfs != NULL) {
        NSData *readContent = vfs_read_file(vfs.rootDirectory, [NSString stringWithFormat:@"%s", path]);
        NSString *content = [[NSString alloc] initWithData:readContent encoding:NSUTF8StringEncoding];
        return [content UTF8String];
    }
    
    return NULL;
}
