//
//  GestureController.m
//  Synestheatre
//
//  Created by James on 16/09/2016.
//  Copyright © 2016 James. All rights reserved.
//

#import "GestureController.h"
#import <AVFoundation/AVFoundation.h>

// Typedef to hold the direction of pinching gesture
typedef enum {
    pinchX,
    pinchY,
    pinchBoth,
} PinchDirection;

@implementation GestureController

- (void)awakeFromNib {
    
    [super awakeFromNib];
    [self.tapGesture requireGestureRecognizerToFail:self.longPressGesture];
    [self.tapGesture setNumberOfTapsRequired:2];
}

#pragma mark Gestures


- (IBAction)panGesture:(UIPanGestureRecognizer *)panGesture {
    
    static int numberOfTouches = 0;
    bool numberOfTouchesChanged = numberOfTouches != [panGesture numberOfTouches];
    bool gestureStarted = [panGesture state] == UIGestureRecognizerStateBegan;
    bool gestureEnded = [panGesture state] == UIGestureRecognizerStateEnded;
    
    if (!gestureEnded && (gestureStarted || numberOfTouchesChanged)) {
        //reset translation
        numberOfTouches = (int)[panGesture numberOfTouches] ;
        [panGesture setTranslation:CGPointZero inView:[panGesture view]];
        [_parameterController panGestureStarted: numberOfTouches];
    }
    
    CGPoint translation = [panGesture translationInView:[panGesture view]];
    [_parameterController panGestureUpdated:translation gestureEnded:gestureEnded];
}


- (IBAction)pinchGesture:(UIPinchGestureRecognizer *)pinchRecognizer {
    
    static CGFloat xDistance;
    static CGFloat yDistance;
    
    if ([pinchRecognizer state] == UIGestureRecognizerStateBegan) {
        
        CGPoint touch1 = [pinchRecognizer locationOfTouch:0 inView:[_pinchGesture view]];
        CGPoint touch2 = [pinchRecognizer locationOfTouch:1 inView:[_pinchGesture view]];
        xDistance = fabs(touch1.x - touch2.x);
        yDistance = fabs(touch1.y - touch2.y);

        [_parameterController pinchGestureStarted];
    }
    
    PinchDirection pinchDirection = [self getPinchDirection:pinchRecognizer];
    float xOffset = (xDistance * pinchRecognizer.scale) - xDistance;
    float yOffset = (yDistance * pinchRecognizer.scale) - yDistance;
    
    
    CGPoint translation;
    switch(pinchDirection) {
        case pinchX:
            translation = CGPointMake(xOffset, 0);
            break;
        case pinchY:
            translation = CGPointMake(0, yOffset);
            break;
        case pinchBoth:
            translation = CGPointMake(xOffset, yOffset);
            break;
    }
    
    bool pinchEnded = [pinchRecognizer state] == UIGestureRecognizerStateEnded;
    [_parameterController pinchGestureUpdated:translation gestureEnded:pinchEnded];
    
}

-(PinchDirection)getPinchDirection:(UIPinchGestureRecognizer *)pinchRecognizer {
    
    // Prevent crashes when there are less than 2 touches in the view
    if ([pinchRecognizer numberOfTouches] < 2) return pinchBoth;

    UIView *theView = [pinchRecognizer view];
    CGPoint locationOne = [pinchRecognizer locationOfTouch:0 inView:theView];
    CGPoint locationTwo = [pinchRecognizer locationOfTouch:1 inView:theView];
    
    //avoid dividing by zero when calculating slope
    double abSlope = (locationOne.x == locationTwo.x) ? 10000 :
        ABS((locationTwo.y - locationOne.y)/(locationTwo.x - locationOne.x));
    
    
    if (abSlope < 0.5) { //scale X
        return pinchX;
    }else if (abSlope > 1.7) { //scale Y
        return pinchY;
    } else { //both
        return pinchBoth;
    }
}


- (IBAction)tapGesture:(UITapGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateRecognized) {
        NSLog(@"Tap");
        [_parameterController doubleTap];
    }
    
}


- (IBAction)longPressGesture:(UILongPressGestureRecognizer *)longPressGesture {
    NSLog(@"Long Press");
    

    static bool draggedWhilstLongPressing = false;
    static NSTimeInterval pressStartTime = 0.0;
    
    if ([longPressGesture state] == UIGestureRecognizerStateBegan) {
        pressStartTime = [NSDate timeIntervalSinceReferenceDate];
        draggedWhilstLongPressing = false;
        AudioServicesPlayAlertSound(1105);
        [_viewControler performSegueWithIdentifier:@"settings_show" sender:nil];
    } else if ([longPressGesture state] == UIGestureRecognizerStateEnded) {
        
        //NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - pressStartTime;
        
        
    } else {
        draggedWhilstLongPressing = true;
    }
}

@end
