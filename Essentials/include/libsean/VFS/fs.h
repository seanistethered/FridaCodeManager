//
//  fs.h
//  Sean16CPU
//
//  Created by Frida Boleslawska on 05.10.24.
//

#import <Foundation/Foundation.h>

#define BLOCK_SIZE 512
#define MAX_FILES 100
#define FS_MAGIC 0xF1F2F3F4

// File system metadata structure
typedef struct {
    uint32_t magic;          // Magic number to identify the file system
    uint32_t blockCount;     // Total number of blocks in the file system
    uint32_t freeBlocks;     // Free blocks available
} FileSystemMetadata;

// VFSFile: Represents a file in the virtual file system
@interface VFSFile : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSUInteger size;
@property (nonatomic, assign) NSUInteger startBlock;
@property (nonatomic, strong) NSData *content;
@end

// VFSDirectory: Represents a directory in the virtual file system
@interface VFSDirectory : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSMutableArray<VFSFile *> *files;
@property (nonatomic, strong) NSMutableArray<VFSDirectory *> *directories;
- (instancetype)initWithName:(NSString *)name;
@end

// VirtualFileSystem: Manages the virtual file system on disk
@interface VirtualFileSystem : NSObject

@property (nonatomic, strong) NSString *filePath;       // Path to the file backing the virtual file system
@property (nonatomic, strong) NSFileHandle *fileHandle; // Handle to the file system file
@property (nonatomic, assign) NSUInteger totalSize;     // Total size of the file system in bytes
@property (nonatomic, strong) VFSDirectory *rootDirectory; // Root directory of the file system

// Initialize a virtual file system with a file path and size
- (instancetype)initWithFilePath:(NSString *)path size:(NSUInteger)size;

// Format the virtual file system (creates metadata and initializes it)
- (void)formatFileSystem;

@end

// VFS utility functions for Unix-like file system operations

/// Create a directory within the specified parent directory
/// @param parentDir The parent directory where the new directory will be created
/// @param dirName The name of the new directory
void vfs_mkdir(VFSDirectory *parentDir, NSString *dirName);

/// Remove a directory by name from the specified parent directory
/// @param parentDir The parent directory containing the directory to be removed
/// @param dirName The name of the directory to be removed
void vfs_rmdir(VFSDirectory *parentDir, NSString *dirName);

/// Create a file with specified content in the parent directory
/// @param parentDir The directory where the new file will be created
/// @param fileName The name of the new file
/// @param content The data to write to the new file
void vfs_create_file(VFSDirectory *parentDir, NSString *fileName, NSData *content);

/// Delete a file by name from the specified directory
/// @param parentDir The directory containing the file to be deleted
/// @param fileName The name of the file to be deleted
void vfs_delete_file(VFSDirectory *parentDir, NSString *fileName);

/// List the contents of the specified directory
/// @param dir The directory to list the contents of
void vfs_list_dir(VFSDirectory *dir);

/// Read the contents of a file by name
/// @param parentDir The directory containing the file
/// @param fileName The name of the file to read from
/// @return The data read from the file, or nil if the file doesn't exist
NSData *vfs_read_file(VFSDirectory *parentDir, NSString *fileName);

/// Write data to a file by name
/// @param parentDir The directory containing the file
/// @param fileName The name of the file to write to
/// @param content The data to write to the file
void vfs_write_file(VFSDirectory *parentDir, NSString *fileName, NSData *content);

// management functions
uint8_t fs_check(void);
void fs_init(void);
void fs_format(void);
void fs_mkdir(char *path);
void fs_rmdir(char *path);
void fs_cfile(char *path, char *content);
void fs_dfile(char *path);
const char* fs_rfile(char *path);
