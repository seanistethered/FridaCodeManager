//
//  Mouse.h
//  Sean16CPU
//
//  Created by Frida Boleslawska on 05.10.24.
//

#import <UIKit/UIKit.h>

@interface TouchTracker : NSObject

@property (nonatomic, assign) CGPoint touchPosition;
@property (nonatomic, assign) NSInteger lastTouchState;

- (instancetype)initWithView:(UIView *)view scale:(CGFloat)scale;
- (void)startTracking;
- (void)stopTracking;
- (CGPoint*)getPos;
- (NSInteger*)getBtn;

@end
