//
//  SynestheatreMain.h
//  Synestheatre
//
//  Created by James on 11/08/2016.
//  Copyright © 2016 James. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioController.h"
#import "DepthSensor.h"
#import "Configuration.h"

#define SYN_FOCUS_MIN 0
#define SYN_FOCUS_MAX 1
#define SYN_DEPTH_WIN_MIN 0.05
#define SYN_DEPTH_WIN_MAX 1
#define SYN_TIMING_MIN 0
#define SYN_TIMING_MAX 1
#define SYN_DEPTH_MM_MIN 500
#define SYN_DEPTH_MM_MAX 10000
#define SYN_CLOSEST_DEPTH_MM_MIN 0
#define SYN_CLOSEST_DEPTH_MM_MAX 10000
#define SYN_HB_MIN 0.1
#define SYN_HB_MAX 30
#define SYN_BWLEVEL_MIN 0
#define SYN_BWLEVEL_MAX 1

#ifndef DEBUG
#define DEBUG 0
#endif

/**
 *  'SynestheatreMain' is the main class that controls the 'AudioController' by the 'DepthOnlySensor'
 *   The logic for converting depth to time / volume is contained here.  There is an optional callback
 *   to show depth / debug drawings
 *
 *   There is an NSTimer 'heartbeat' which is retriggered every interval (e.g. every second), which retriggers
 *   all the sounds to play.  If there are vertical/horizontal timing offsets, the sounds play after a delay
 *   due to these offsets.  E.g. if you have 10 cols, a heartbeat of a second, and a horizontal timing offset
 *   of 0.5, then the 10 cols will be played spread over 0.5 a second.  If the timing offset is 1.0, then the 
 *   cols will be spread over the full second.  
 *
 *   Currently depth -> volume is linear - there could be some improvements here.
 *
 *   Note:  If horizontalTimingOffset + verticalTimingOffset > 1, then some sounds will not be heard.
 *
 *
 *
 *   A lot of scope to make things more efficient in this class if necessary
 */
@interface SynestheatreMain : NSObject

@property (nonatomic, readwrite) bool landscapeMode;

@property (nonatomic, readwrite) Configuration* config;

/**
 * Volumes
 */
@property (nonatomic,readonly) NSArray* volumes;
/**
 *  Init the Synestheatre
 *
 *  @param audioController AudioController
 *  @param depthSensor     DepthOnlySensor
 *
 *  @return new instance of SynestheatreMain
 */
- (instancetype)initWithAudioController:(AudioController*)audioController depthSensor:(id<DepthSensor>)depthSensor;

/**
 *  Start sound and depth reading
 */
- (void)start;

/**
 *  Stop sound and depth reading
 */
- (void)stop;

/**
 * Update volumes with new depth data
 */
- (void)depthDataUpdated;

/**
 *  Sets the heartbeat rate (secs) for sound triggering
 *
 *  @param heartbeatInterval heartbeat interval (secs)
 */
- (void)setHeartbeatTempo:(float)heartbeatInterval;

/**
 *  Sets the sub window for depth information
 *
 *  @param height (0 - 1)
 *  @param width  (0 - 1)
 */
- (void)setDepthWindow:(float)height width:(float)width;

/**
 *  Set the  depth range in mm
 *
 *  @param depthInMs depth in mm
 */
- (void)setDepthRange:(float)depthInMm;

/**
 *  Set location of depth sensing in mm
 *
 *  @param distanceInMm of closest sensed range in mm
 */
- (void)setDepthDistance:(float)distanceInMm;

/**
 *  Sets the horizontal timing offset
 *
 *  @param horizontalTimingOffset (0 - 1)
 */
- (void)setHorizontalTimingOffset:(float)horizontalTimingOffset;

/**
 *  Sets the vertical timing offset
 *
 *  @param verticalTimingOffset (0 - 1)
 */
- (void)setVerticalTimingOffset:(float)verticalTimingOffset;

/**
 *  Sets the horizontal focus
 *
 *  @param horizontalFocus (0 - 1)
 */
- (void)setHorizontalFocus:(float)horizontalFocus;

/**
 *  Sets the vertical focus
 *
 *  @param verticalFocus (0 - 1)
 */
- (void)setVerticalFocus:(float)verticalFocus;

/**
 *  Sets the lightness level in B&W mode
 *
 *  @param lightness level (0 - 1)
 */
- (void)setBwLevel:(float)lightness;

- (UIImage*)colourDebugImage;

- (bool)isRunning;
@end
