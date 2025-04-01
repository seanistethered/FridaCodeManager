//
//  fs.m
//  Sean16CPU
//
//  Created by Frida Boleslawska on 05.10.24.
//

#import "fs.h"

@implementation VFSDirectory
- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = name;
        _files = [NSMutableArray array];
        _directories = [NSMutableArray array];
    }
    return self;
}
@end

@implementation VFSFile
@end

@implementation VirtualFileSystem

- (instancetype)initWithFilePath:(NSString *)path size:(NSUInteger)size {
    if (self = [super init]) {
        _filePath = path;
        _totalSize = size;
        _rootDirectory = [[VFSDirectory alloc] initWithName:@"/"];
        
        // Create an empty data block (the virtual file system)
        NSMutableData *data = [NSMutableData dataWithLength:size];
        [data writeToFile:path atomically:YES];
        
        _fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:path];
        if (!_fileHandle) {
            //NSLog(@"Failed to open virtual file system.");
            return nil;
        }
    }
    return self;
}

// Format the virtual file system
- (void)formatFileSystem {
    FileSystemMetadata metadata;
    metadata.magic = FS_MAGIC;
    metadata.blockCount = (uint32_t)(self.totalSize / BLOCK_SIZE);
    metadata.freeBlocks = metadata.blockCount - 1;
    
    NSData *metadataData = [NSData dataWithBytes:&metadata length:sizeof(FileSystemMetadata)];
    
    // Write metadata to the first block (block 0)
    [self.fileHandle seekToFileOffset:0];
    [self.fileHandle writeData:metadataData];
    
    //NSLog(@"Formatted the file system with %u blocks.", metadata.blockCount);
}

@end

// VFS Utility functions
void vfs_mkdir(VFSDirectory *parentDir, NSString *dirName) {
    VFSDirectory *newDir = [[VFSDirectory alloc] initWithName:dirName];
    [parentDir.directories addObject:newDir];
    //NSLog(@"Directory '%@' created.", dirName);
}

void vfs_rmdir(VFSDirectory *parentDir, NSString *dirName) {
    for (VFSDirectory *dir in parentDir.directories) {
        if ([dir.name isEqualToString:dirName]) {
            [parentDir.directories removeObject:dir];
            //NSLog(@"Directory '%@' removed.", dirName);
            return;
        }
    }
    //NSLog(@"Directory '%@' not found.", dirName);
}

void vfs_create_file(VFSDirectory *parentDir, NSString *fileName, NSData *content) {
    VFSFile *newFile = [[VFSFile alloc] init];
    newFile.name = fileName;
    newFile.size = content.length;
    newFile.content = content;
    [parentDir.files addObject:newFile];
    //NSLog(@"File '%@' created.", fileName);
}

void vfs_delete_file(VFSDirectory *parentDir, NSString *fileName) {
    for (VFSFile *file in parentDir.files) {
        if ([file.name isEqualToString:fileName]) {
            [parentDir.files removeObject:file];
            //NSLog(@"File '%@' deleted.", fileName);
            return;
        }
    }
    //NSLog(@"File '%@' not found.", fileName);
}

// void vfs_list_dir(VFSDirectory *dir) {
//     //NSLog(@"Listing directory: %@", dir.name);
//     for (VFSDirectory *subdir in dir.directories) {
//         //NSLog(@"[DIR] %@", subdir.name);
//     }
//     for (VFSFile *file in dir.files) {
//         //NSLog(@"[FILE] %@ (%lu bytes)", file.name, (unsigned long)file.size);
//     }
// }

NSData *vfs_read_file(VFSDirectory *parentDir, NSString *fileName) {
    for (VFSFile *file in parentDir.files) {
        if ([file.name isEqualToString:fileName]) {
            //NSLog(@"Reading file '%@'", fileName);
            return file.content;
        }
    }
    //NSLog(@"File '%@' not found.", fileName);
    return nil;
}

void vfs_write_file(VFSDirectory *parentDir, NSString *fileName, NSData *content) {
    for (VFSFile *file in parentDir.files) {
        if ([file.name isEqualToString:fileName]) {
            file.content = content;
            file.size = content.length;
            //NSLog(@"Wrote data to file '%@'", fileName);
            return;
        }
    }
    //NSLog(@"File '%@' not found.", fileName);
}
