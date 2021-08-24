//
//  Configuration.h
//  Synestheatre
//
//  Created by James on 10/08/2018.
//  Copyright © 2018 James. All rights reserved.
//

#import "ColourConfiguration.h"
#import "ReverbConfiguration.h"
#import <Foundation/Foundation.h>
/**
 * Class to hold all variables in a synestheatre configuration
 */

@interface Configuration : NSObject

@property (nonatomic,readwrite) int rows;
@property (nonatomic,readwrite) int cols;
@property (nonatomic,readwrite) int colours;
@property (nonatomic,readwrite) NSArray* filenames;
@property (nonatomic,readwrite) NSString* name;
@property (nonatomic,readwrite) float horizontalFocus;
@property (nonatomic,readwrite) float verticalFocus;
@property (nonatomic,readwrite) float horizontalTimingOffset;
@property (nonatomic,readwrite) float verticalTimingOffset;
@property (nonatomic,readwrite) float depthDataWindowWidth;
@property (nonatomic,readwrite) float depthDataWindowHeight;
@property (nonatomic,readwrite) float heartbeatInterval;
@property (nonatomic,readwrite) float depthRange;
@property (nonatomic,readwrite) float depthDistance;
@property (nonatomic,readwrite) float defaultDepth;
@property (nonatomic,readwrite) bool depthMode;
@property (nonatomic,readwrite) NSString* panGesture;
@property (nonatomic,readwrite) NSString* twoFingerGesture;
@property (nonatomic,readwrite) NSString* pinchGesture;
@property (nonatomic,readwrite) NSString* volSource;
@property (nonatomic,readwrite) NSString* orientation;
@property (nonatomic,readwrite) ColourConfiguration colourConfiguration;
@property (nonatomic,readwrite) ReverbConfiguration reverbConfiguration;
@property (nonatomic,readwrite) NSArray* colourTimings;
@property (nonatomic,readwrite) bool exponentialLoudness;
@property (nonatomic,readwrite) float maxDepthVolume;
@property (nonatomic,readwrite) NSDictionary *syntJsonDic;
/**
 * Attempts to load a configuration from the path given
 */
- (bool)loadSyntFile:(NSString*)syntFilePath error:(NSError**)error;

/**
 * Saves a synt file with the current settings as custom.synt.  This will overwrite any previous ones
 * called custom
 */
-(void)saveSyntFileWithCurrentSettings;

@end
