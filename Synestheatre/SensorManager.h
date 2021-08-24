//
//  SensorManager.h
//  Synestheatre
//
//  Created by James on 17/01/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DepthSensor.h"

NS_ASSUME_NONNULL_BEGIN

@interface SensorManager : NSObject

- (id<DepthSensor>) getSensor;

@end

NS_ASSUME_NONNULL_END
