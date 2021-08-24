//
//  FlirOneDepthSensor.h
//  Synestheatre
//
//  Created by James on 10/01/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FLIROneSDK/FLIROneSDK.h>
#import "DepthSensor.h"

@interface FlirOneDepthSensor : NSObject <FLIROneSDKImageReceiverDelegate, FLIROneSDKStreamManagerDelegate, DepthSensor>

-(instancetype)initWithMSX:(bool)useMSX;

@end

