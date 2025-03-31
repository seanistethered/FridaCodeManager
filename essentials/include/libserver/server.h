#include <Foundation/Foundation.h>

@interface httpObjServer : NSObject

- (void)startHttpServer:(NSString*)path;
- (void)stopHttpServer;
- (void)rotateHttpServer;

@end