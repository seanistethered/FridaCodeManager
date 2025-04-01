//
//  Display.h
//  Sean16CPU
//
//  Created by Frida Boleslawska on 27.09.24.
//

#import <UIKit/UIKit.h>

@interface MyScreenEmulatorView : UIView

- (instancetype)initWithFrame:(CGRect)frame screenWidth:(NSInteger)width screenHeight:(NSInteger)height;
- (void)setPixelAtX:(NSInteger)x y:(NSInteger)y colorIndex:(NSUInteger)colorIndex;
- (UIColor *)colorAtPixelX:(NSInteger)x y:(NSInteger)y;
- (NSInteger)colorIndexAtPixelX:(NSInteger)x y:(NSInteger)y;
- (void)clear;

@end

MyScreenEmulatorView *getEmulator(void);
