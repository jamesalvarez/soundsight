//
//  SensorManager.m
//  Synestheatre
//
//  Created by James on 17/01/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import "SensorManager.h"

#import "StructureSensorDepthSensor.h"
#import "DualCameraDepthSensor.h"
#import "SynestheatreMain.h"
#import "DepthSensor.h"
#import <ExternalAccessory/ExternalAccessory.h>
#import "SoundSight-Swift.h"


@interface SensorManager () {
    id<DepthSensor> depthSensor;
}

@end

@implementation SensorManager

- (id) init
{
    self = [super init];
    return self;
}


- (id<DepthSensor>) getSensor {
    
    // Force deallocation
    depthSensor =  nil;

    NSString* sensorType = [[NSUserDefaults standardUserDefaults] stringForKey:@"sensor"];
    

    if ([sensorType isEqualToString:@"arkit"]) {
        depthSensor = [[ARKitDepthSensor alloc] init];
    } else if ([sensorType isEqualToString:@"cam"]){
        depthSensor = [[DualCameraDepthSensor alloc] init];
    } else if ([sensorType isEqualToString:@"structure"]){
        depthSensor = [[StructureSensorDepthSensor alloc] init];
    }  else { // auto mode is default
        depthSensor = [self getAutoSensor];
    }
    
        
    [depthSensor setUpdateStatusBlock:^(NSString* msg) {
        [Toast makeToast:msg];
        NSLog(@"Depth Sensor: %@", msg);
    }];
    
    return depthSensor;
    
}

// We have to do this since Flir keeps crashing when plugging in structure sensor
- (id<DepthSensor>) getAutoSensor {
    
    // Temporarily always picking ARKitDepth sensor
    return [[ARKitDepthSensor alloc] init];

    NSArray *accessories = [[EAAccessoryManager sharedAccessoryManager]
                            connectedAccessories];
    
    if ([accessories count] == 0) {
        return [[DualCameraDepthSensor alloc] init];
    }
    
    EAAccessory *accessory = accessories[0];
    
    if ([[accessory name] isEqualToString:@"Structure Sensor"]) {
        return [[StructureSensorDepthSensor alloc] init];
    }
    
    // Fail safe
    return [[DualCameraDepthSensor alloc] init];
}

@end
