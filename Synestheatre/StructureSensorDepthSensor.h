/*
 This file was adapted from an example in the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <UIKit/UIKit.h>
#define HAS_LIBCXX

#ifndef DEBUG
#define DEBUG 0
#endif

#import <Structure/Structure.h>
#import "DepthSensor.h"

/**
 *  'DepthOnlySensor' handles all the Structure sensor stuff.  It also provides a colour frame, 
 *   for debugging and demonstrating to non-blind people.
 */
@interface StructureSensorDepthSensor : NSObject <STSensorControllerDelegate, DepthSensor>
// See DepthSensor.h
@end
