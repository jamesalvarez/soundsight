//
//  SynestheatreParameterController.h
//  Synestheatre
//
//  Created by James on 06/07/2018.
//  Copyright © 2018 James. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynestheatreMain.h"

@interface ParameterController : NSObject

@property (strong, nonatomic)  SynestheatreMain *synestheatreMain;

- (void)panGestureStarted:(int)numberOfTouches;

- (void)panGestureUpdated:(CGPoint)translation gestureEnded:(bool)gestureEnded;

- (void)pinchGestureStarted;

- (void)pinchGestureUpdated:(CGPoint)translation gestureEnded:(bool)gestureEnded;

- (void)doubleTap;

@end
