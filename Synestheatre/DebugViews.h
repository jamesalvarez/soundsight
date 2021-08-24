//
//  DebugViews.h
//  Synestheatre
//
//  Created by James on 03/08/2018.
//  Copyright © 2018 James. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynestheatreMain.h"

@interface DebugViews : NSObject

/** Singleton pattern: http://www.galloway.me.uk/tutorials/singleton-classes/
 *  For easier access to send debug messages throughout app
 */
+ (DebugViews*)sharedManager;

@property (strong, nonatomic) SynestheatreMain* synestheatreMain;
@property (strong, nonatomic) id<DepthSensor> depthSensor;


/**
 *  Image views, left and right for various purposes, plus debug colour image view
 */
@property (strong, nonatomic) UIImageView* leftImageView;
@property (strong, nonatomic) UIImageView* rightImageView;
@property (strong, nonatomic) UIImageView* colourImageView;

/**
 *  Text view for debug messages from synestheatre and sensor
 */
@property (strong, nonatomic) UITextView* synestheatreConsoleTextView;
@property (strong, nonatomic) UITextView* sensorConsoleTextView;


-(void) displaySynestheatreConsoleText:(NSString*)text;
-(void) displaySensorConsoleText:(NSString*)text;
-(void) displayCentreColour:(UIImage*)colourImage;
-(void) setupWithParent:(UIView*)parent;
-(void) updateSensorImage;
-(void) reset;
-(void) clear;



@end
