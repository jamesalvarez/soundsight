//
//  SynestheatreParameterController.m
//  Synestheatre
//
//  Created by James on 06/07/2018.
//  Copyright © 2018 James. All rights reserved.
//

#import "ParameterController.h"
#import "Toast.h"

// A struct to hold all UI related variables
typedef struct UIVariables {
    CGFloat translationXStart;
    CGFloat translationYStart;
    int numberOfTouches;
    
} UIVariables;

@interface ParameterController () {
    UIVariables _ui;
    NSTimer* _voiceUpdate;
}
@end

@implementation ParameterController

-(void)queueVoiceUpdate:(NSString*)utterance {
    if (_voiceUpdate != nil) {
        [_voiceUpdate invalidate];
        _voiceUpdate = nil;
    }
    
    _voiceUpdate = [NSTimer scheduledTimerWithTimeInterval:1.0
                                       target:self
                                     selector:@selector(sayVoiceUpdate:)
                                     userInfo:utterance
                                      repeats:NO];
}

-(void)sayVoiceUpdate:(NSTimer*) timer {
    [[NSNotificationCenter defaultCenter] postNotificationName: @"SaySomething" object: timer.userInfo];
    _voiceUpdate = nil;
}

- (void)setStartValueForGestureCode:(NSString*)gestureCode {
    if ([gestureCode isEqualToString:@"focus"]) {
        _ui.translationXStart = [[_synestheatreMain config] horizontalFocus];
        _ui.translationYStart = [[_synestheatreMain config] verticalFocus];
    }else if ([gestureCode isEqualToString:@"window"]) {
        _ui.translationXStart = [[_synestheatreMain config] depthDataWindowWidth];
        _ui.translationYStart = [[_synestheatreMain config] depthDataWindowHeight];
    } else if ([gestureCode isEqualToString:@"timing"]) {
        _ui.translationXStart = [[_synestheatreMain config] horizontalTimingOffset];
        _ui.translationYStart = [[_synestheatreMain config] verticalTimingOffset];
    } else if ([gestureCode isEqualToString:@"heartbeat"]) {
        _ui.translationXStart = [[_synestheatreMain config] heartbeatInterval];
        _ui.translationYStart = 0;
    } else if ([gestureCode isEqualToString:@"depth"]) {
        _ui.translationXStart = [[_synestheatreMain config] depthRange];
        _ui.translationYStart = 0;
    } else if ([gestureCode isEqualToString:@"depth_distance"]) {
        _ui.translationXStart = [[_synestheatreMain config] depthRange];
        _ui.translationYStart = [[_synestheatreMain config] depthDistance];
    } else if ([gestureCode isEqualToString:@"bw"]) {
        _ui.translationXStart = [[_synestheatreMain config] colourConfiguration].bw_level;
        _ui.translationYStart = 0;
    }
}



- (void)changeValueForGestureCode:(NSString*)gestureCode forTranslation:(CGPoint)translation {
    NSString* feedback = nil;
    
    if ([gestureCode isEqualToString:@"focus"]) {
        float range = SYN_FOCUS_MAX - SYN_FOCUS_MIN;
        [_synestheatreMain setHorizontalFocus: _ui.translationXStart + (range * translation.x) ];
        [_synestheatreMain setVerticalFocus:   _ui.translationYStart + (range * translation.y)];
        
        feedback = [NSString stringWithFormat:@"Horizontal focus: %.02f\nVertical focus: %.02f", _synestheatreMain.config.horizontalFocus, _synestheatreMain.config.verticalFocus];
        
    } else if ([gestureCode isEqualToString:@"window"]) {
        float range = SYN_DEPTH_WIN_MAX - SYN_DEPTH_WIN_MIN;
        [_synestheatreMain setDepthWindow:_ui.translationYStart + (range * translation.y) width:_ui.translationXStart + (range * translation.x)];
        
        feedback = [NSString stringWithFormat:@"Depth window height: %.02f\nDepth window width: %.02f", _synestheatreMain.config.depthDataWindowHeight, _synestheatreMain.config.depthDataWindowWidth];
        
    } else if ([gestureCode isEqualToString:@"timing"]) {
        float range = SYN_TIMING_MAX - SYN_TIMING_MIN;
        [_synestheatreMain setHorizontalTimingOffset:_ui.translationXStart + (range * translation.x)];
        [_synestheatreMain setVerticalTimingOffset:_ui.translationYStart + (range * translation.y)];
        
        feedback = [NSString stringWithFormat:@"Horizontal timing offset: %.02f\nVertical timing offset: %.02f", _synestheatreMain.config.horizontalTimingOffset, _synestheatreMain.config.verticalTimingOffset];
        
    } else if ([gestureCode isEqualToString:@"heartbeat"]) {
        float range = SYN_HB_MAX - SYN_HB_MIN;
        float newTempo;
        if (fabs(translation.x) > fabs(translation.y)) {
            newTempo = _ui.translationXStart + (range * translation.x);
        } else {
            newTempo = _ui.translationXStart + (range * translation.y);
        }
        [_synestheatreMain setHeartbeatTempo:newTempo];
        
        feedback = [NSString stringWithFormat:@"Heartbeat interval: %.02f seconds", _synestheatreMain.config.heartbeatInterval];
        
    } else if ([gestureCode isEqualToString:@"depth"]) {
        float range = SYN_DEPTH_MM_MAX - SYN_DEPTH_MM_MIN;
        float newDepth;
        if (fabs(translation.x) > fabs(translation.y)) {
            newDepth = _ui.translationXStart + (range * translation.x);
        } else {
            newDepth = _ui.translationXStart + (range * translation.y);
        }
        [_synestheatreMain setDepthRange:newDepth];
        
        feedback = [NSString stringWithFormat:@"Depth range: %.02f millimetres", _synestheatreMain.config.depthRange];
        
    } else if ([gestureCode isEqualToString:@"depth_distance"]) {
        
        NSString* feedback;
        if (fabs(translation.x) > fabs(translation.y)) {
            float range = SYN_DEPTH_MM_MAX - SYN_DEPTH_MM_MIN;
            float newDepth = _ui.translationXStart + (range * translation.x);
            [_synestheatreMain setDepthRange:newDepth];
            feedback = [NSString stringWithFormat:@"Depth range: %.02f millimetres", _synestheatreMain.config.depthRange];
        } else {
            float range = SYN_CLOSEST_DEPTH_MM_MAX - SYN_CLOSEST_DEPTH_MM_MIN;
            float newDepth = _ui.translationYStart + (range * translation.y);
            [_synestheatreMain setDepthDistance:newDepth];
            feedback = [NSString stringWithFormat:@"Depth distance: %.02f millimetres", _synestheatreMain.config.depthDistance];
        }

    } else if ([gestureCode isEqualToString:@"bw"]) {
        float range = 1;
        float newBwLevel;
        if (fabs(translation.x) > fabs(translation.y)) {
            newBwLevel = _ui.translationXStart + (range * translation.x);
        } else {
            newBwLevel = _ui.translationXStart + (range * translation.y);
        }
        [_synestheatreMain setBwLevel: newBwLevel];
        
        feedback = [NSString stringWithFormat:@"BW Level: %.02f", _synestheatreMain.config.colourConfiguration.bw_level];
        
        
    }
    
    if (feedback != nil) {
        [_debugViews displaySensorConsoleText:feedback];
        
        if ([[[NSUserDefaults standardUserDefaults]stringForKey:@"voice_feedback"] integerValue] > 1) {
            [self queueVoiceUpdate:feedback];
        }
        
        
    }
}

-(void)panGestureStarted:(int)numberOfTouches {
    
    _ui.numberOfTouches = numberOfTouches;
    
    if (_ui.numberOfTouches == 1) {
        [self setStartValueForGestureCode:[[_synestheatreMain config] panGesture]];
    } else if(_ui.numberOfTouches == 2) {
        [self setStartValueForGestureCode:[[_synestheatreMain config] twoFingerGesture]];
    }

}

-(void)panGestureUpdated:(CGPoint)translation gestureEnded:(bool)gestureEnded {
    
    CGFloat xpercentage = translation.x / [UIScreen mainScreen].bounds.size.width;
    CGFloat ypercentage = translation.y / [UIScreen mainScreen].bounds.size.height;
    CGPoint percentage = CGPointMake(xpercentage, ypercentage);
    
    NSLog(@"Pan: %@", NSStringFromCGPoint(percentage));
    if (_ui.numberOfTouches == 1) {
        [self changeValueForGestureCode:[[_synestheatreMain config] panGesture] forTranslation:percentage];
    } else if(_ui.numberOfTouches == 2) {
        [self changeValueForGestureCode:[[_synestheatreMain config] twoFingerGesture] forTranslation:percentage];
    }
}

- (void)pinchGestureStarted {
    [self setStartValueForGestureCode:[[_synestheatreMain config] pinchGesture]];
}

/*Pinch gestures are continuous, so your action method is called each time the distance between the fingers changes. The distance between the fingers is reported as a scale factor. At the beginning of the gesture, the scale factor is 1.0. As the distance between the two fingers increases, the scale factor increases proportionally. */
- (void)pinchGestureUpdated:(CGPoint)translation gestureEnded:(bool)gestureEnded {
    
    CGFloat xpercentage = translation.x / [UIScreen mainScreen].bounds.size.width;
    CGFloat ypercentage = translation.y / [UIScreen mainScreen].bounds.size.height;
    CGPoint percentage = CGPointMake(xpercentage, ypercentage);
    
    NSLog(@"Pinch: %@", NSStringFromCGPoint(percentage));
    
    [self changeValueForGestureCode:[[_synestheatreMain config] pinchGesture] forTranslation:percentage];
}

- (void)doubleTap {
    [_synestheatreMain switchConfiguration];
}

@end
