//
//  SensorManager.m
//  Synestheatre
//
//  Created by James on 17/01/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import "SensorManager.h"

#import "DualCameraDepthSensor.h"
#import "SynestheatreMain.h"
#import "DepthSensor.h"
#import <ExternalAccessory/ExternalAccessory.h>


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
    

    if ([sensorType isEqualToString:@"cam"]){
        depthSensor = [[DualCameraDepthSensor alloc] init];
    }  else { // auto mode is default
        depthSensor = [self getAutoSensor];
    }
    
        
    [depthSensor setUpdateStatusBlock:^(NSString* msg) {
        [Toast makeToast:msg];
        NSLog(@"Depth Sensor: %@", msg);
    }];
    
    return depthSensor;
    
}

- (id<DepthSensor>) getAutoSensor {
    
    return [[DualCameraDepthSensor alloc] init];

    NSArray *accessories = [[EAAccessoryManager sharedAccessoryManager]
                            connectedAccessories];
    
    if ([accessories count] == 0) {
        return [[DualCameraDepthSensor alloc] init];
    }

    // Currently there are no other sensors this version supports, but otherwise here they would go.

    // Fail safe
    return [[DualCameraDepthSensor alloc] init];
}

@end
