//
//  Display.m
//  Sean16CPU
//
//  Created by Frida Boleslawska on 27.09.24.
//

#import "Display.h"
#import <UIKit/UIKit.h>

#define SCREEN_WIDTH 254
#define SCREEN_HEIGHT 254
#define COLOR_COUNT 256
//#define SCALE_FACTOR 1.5

MyScreenEmulatorView *screen = NULL;

@interface MyScreenEmulatorView () {
    NSInteger pixelData[SCREEN_WIDTH][SCREEN_HEIGHT];
    NSMutableArray<UIColor *> *colorPalette;
    CGFloat ScaleFactor;
}
@end

@implementation MyScreenEmulatorView

- (instancetype)initWithFrame:(CGRect)frame screenWidth:(NSInteger)width screenHeight:(NSInteger)height {
    self = [super initWithFrame:frame];
    if (self) {
        CGRect screenSize = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenSize.size.width;
        ScaleFactor = screenWidth / SCREEN_WIDTH;
        memset(pixelData, -1, sizeof(pixelData));
        colorPalette = [[NSMutableArray alloc] initWithCapacity:COLOR_COUNT];
        [self initializeColorPalette];
    }
    return self;
}

- (void)initializeColorPalette {
    // Define the basic 16 colors
    NSArray<UIColor *> *basicColors = @[[UIColor blackColor],   // 0: Black
                                        [UIColor redColor],     // 1: Red
                                        [UIColor greenColor],   // 2: Green
                                        [UIColor blueColor],    // 3: Blue
                                        [UIColor yellowColor],  // 4: Yellow
                                        [UIColor magentaColor], // 5: Magenta
                                        [UIColor cyanColor],    // 6: Cyan
                                        [UIColor whiteColor],   // 7: White
                                        [UIColor darkGrayColor],// 8: Dark Gray
                                        [UIColor lightGrayColor],// 9: Light Gray
                                        [UIColor brownColor],   // 10: Brown
                                        [UIColor orangeColor],  // 11: Orange
                                        [UIColor purpleColor],  // 12: Purple
                                        [UIColor cyanColor],    // 13: Cyan (light)
                                        [UIColor magentaColor], // 14: Magenta (light)
                                        [UIColor grayColor]];   // 15: Gray

    // Fill the first 16 colors from the basic palette
    [colorPalette addObjectsFromArray:basicColors];

    // Fill in the rest of the colors (generated colors)
    for (int i = 16; i < COLOR_COUNT; i++) {
        CGFloat red = (CGFloat)((i - 16) / 36) / 5.0;
        CGFloat green = (CGFloat)(((i - 16) / 6) % 6) / 5.0;
        CGFloat blue = (CGFloat)((i - 16) % 6) / 5.0;

        UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
        [colorPalette addObject:color];
    }
}

- (void)drawRect:(CGRect)rect {
    [[UIColor blackColor] setFill];
    UIRectFill(rect);

    CGFloat scaledPixelSize = ScaleFactor;

    for (int x = 0; x < SCREEN_WIDTH; x++) {
        for (int y = 0; y < SCREEN_HEIGHT; y++) {
            NSInteger colorIndex = pixelData[x][y];
            if (colorIndex != -1 && colorIndex < COLOR_COUNT) {
                CGRect pixelRect = CGRectMake(x * scaledPixelSize, y * scaledPixelSize, scaledPixelSize, scaledPixelSize);
                [colorPalette[colorIndex] setFill];
                UIRectFill(pixelRect);
            }
        }
    }
}

- (void)setPixelAtX:(NSInteger)x y:(NSInteger)y colorIndex:(NSUInteger)colorIndex {
    if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT && colorIndex < COLOR_COUNT) {
        pixelData[x][y] = colorIndex;
        [self setNeedsDisplay];
    }
}

- (UIColor *)colorAtPixelX:(NSInteger)x y:(NSInteger)y {
    if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT) {
        NSInteger colorIndex = pixelData[x][y];
        if (colorIndex != -1) {
            return colorPalette[colorIndex];
        }
    }
    return [UIColor blackColor];
}

- (NSInteger)colorIndexAtPixelX:(NSInteger)x y:(NSInteger)y {
    if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT) {
        return pixelData[x][y];
    }
    return -1;
}

- (void)clear {
    memset(pixelData, -1, sizeof(pixelData));
    [self setNeedsDisplay];
}

MyScreenEmulatorView *getEmulator(void) {
    if (!screen) {
        CGRect screenSize = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenSize.size.width;
        CGRect screenFrame = CGRectMake(0, 0, SCREEN_WIDTH * (screenWidth / SCREEN_WIDTH), SCREEN_HEIGHT * (screenWidth / SCREEN_WIDTH));
        screen = [[MyScreenEmulatorView alloc] initWithFrame:screenFrame screenWidth:SCREEN_WIDTH screenHeight:SCREEN_HEIGHT];
    }
    return screen;
}

@end