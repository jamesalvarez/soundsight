//
//  GestureController.h
//  Synestheatre
//
//  Created by James on 16/09/2016.
//  Copyright © 2016 James. All rights reserved.
//

#import "ParameterController.h"
#import "MainViewController.h"
#import <Foundation/Foundation.h>

@class MainViewController;
@class ParameterController;

/**
 *  'GestureController' handles all user touch gestures.  
 */
@interface GestureController : NSObject <UIGestureRecognizerDelegate>

/**
 *  Main view controller
 */
@property (strong, nonatomic) IBOutlet MainViewController *viewControler;

/**
 *  Single finger pans adjust heartbeat rate
 *  Double finger pans adjust maximum depth
 */
@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *panGesture;

/**
 *  Pinches control either:
 *    a) Sub window of depth data
 *    b) Focus of sounds to play (e.g. can focus on just center sounds)
 *    c) Vertical / Horizontal timing offsets
 */
@property (strong, nonatomic) IBOutlet UIPinchGestureRecognizer *pinchGesture;

/**
 *  Double taps switch pinch mode
 */
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapGesture;


/**
 *  Long press switches configuration
 */
@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *longPressGesture;


/**
 * Synestheatre Parameter Controller
 */
@property (strong, nonatomic) IBOutlet ParameterController *parameterController;
@end
