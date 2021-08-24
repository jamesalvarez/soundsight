//
//  ViewController.h
//  RealtimeVideoFilter
//
//  Created by Altitude Labs on 23/12/15.
//  Copyright © 2015 Victor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DepthSensor.h"
#import <AVFoundation/AVFoundation.h>

@interface DualCameraDepthSensor : NSObject <DepthSensor,AVCaptureDepthDataOutputDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureDataOutputSynchronizerDelegate>
// See DepthSensor.h
@end

