/*
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
*/

#import <UIKit/UIKit.h>
#define HAS_LIBCXX
#import <Structure/Structure.h>
#import "SynestheatreMain.h"
#import "GestureController.h"
#import "TransparentLabelView.h"
#import "ParameterController.h"
#import "InAppSettingsKit/IASKAppSettingsViewController.h"

@class GestureController;
@class ParameterController;

/**
 *  Creates the Synestheatre and controls interactions with it
 */
@interface MainViewController : UIViewController <IASKSettingsDelegate>

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *dragModeButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIImageView* leftImageView;
/**
 *  Class to control user gestures
 */
@property (strong, nonatomic) IBOutlet GestureController *gestureController;

/**
 *  Class to control parameter translations
 */
@property (strong, nonatomic) IBOutlet ParameterController *parameterController;

/**
 *  The main class for Synestheatre
 */
@property (strong, nonatomic) SynestheatreMain *synestheatreMain;

/**
 *  Say something with speech synthesizer
 *
 *  @param something something to say...
 */
- (void)saySomething:(NSString*)something;

// Restarts engine, redectecting depth sensor etc
- (void)restartEngine;

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue;


@end
