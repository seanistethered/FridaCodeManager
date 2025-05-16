//
//  Mouse.m
//  Sean16CPU
//
//  Created by Frida Boleslawska on 05.10.24.
//

#import "Mouse.h"

@interface TouchTracker ()

@property (nonatomic, strong) UIView *trackedView;
@property (nonatomic, assign) BOOL isTrackingPaused;
@property (nonatomic, assign) BOOL touchHidden;
@property (nonatomic, assign) CGFloat scaleFactor;  // New property for scaling

@end

@implementation TouchTracker

- (instancetype)initWithView:(UIView *)view scale:(CGFloat)scale {
    self = [super init];
    if (self) {
        _touchPosition = CGPointMake(0, 0);
        _isTrackingPaused = YES; // Initially paused
        _lastTouchState = 0;
        _trackedView = view;
        _scaleFactor = scale;

        // Gesture recognizer for touch events
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [view addGestureRecognizer:panGesture];
        
        // Tap gesture recognizer for touch events
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [view addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)setScaleFactor:(CGFloat)scaleFactor {
    _scaleFactor = scaleFactor;
}

- (void)startTracking {
    if (!self.isTrackingPaused) {
        return; // Already tracking
    }

    self.isTrackingPaused = NO;
    self.touchHidden = NO; // Ensure the touch is visible
}

- (void)stopTracking {
    self.isTrackingPaused = YES;
    self.touchHidden = YES; // Optionally hide touch indicator
}

- (CGPoint*)getPos {
    return &_touchPosition;
}

- (NSInteger*)getBtn {
    return &_lastTouchState;
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    if (self.isTrackingPaused) return;

    CGPoint location = [gesture locationInView:self.trackedView];
    [self updateTouchPosition:location];
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (self.isTrackingPaused) return;

    CGPoint location = [gesture locationInView:self.trackedView];
    self.lastTouchState = 2; // Represents a touch
    [self updateTouchPosition:location];
}

- (void)updateTouchPosition:(CGPoint)location {
    // Ensure the touch position is within the view bounds
    if (CGRectContainsPoint(self.trackedView.bounds, location)) {
        // Adjust the touch position based on the scale factor
        CGPoint scaledLocation = CGPointMake(location.x / self.scaleFactor, location.y / self.scaleFactor);
        
        // Update the touch position with the scaled value
        self.touchPosition = scaledLocation;
        
        // Optional: Log or handle the touch position
        //NSLog(@"Touch position: (%.2f, %.2f)", scaledLocation.x, scaledLocation.y);
    }
}

@end

static TouchTracker *touchTrackerInstance = nil;

TouchTracker *getTracker(void *arg) {
    // Ensure arg is a valid UIView pointer
    UIView *view = (__bridge UIView *)arg;

    if (touchTrackerInstance == nil) {
        CGRect screenSize = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenSize.size.width;
        // CGFloat screenHeight = screenSize.size.height;

        touchTrackerInstance = [[TouchTracker alloc] initWithView:view scale:(screenWidth / 254.0)];
    }
    
    return touchTrackerInstance;
}