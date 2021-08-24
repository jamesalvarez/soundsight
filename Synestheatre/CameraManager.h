//
//  CameraManager.h
//  Synestheatre
//
//  Created by James on 01/02/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraManager : NSObject

@property (nonatomic,readonly) AVCaptureDepthDataOutput* depthDataOutput;
@property (nonatomic,readonly) AVCaptureVideoDataOutput* colourDataOutput;

-(void) startColorCamera: (id<AVCaptureVideoDataOutputSampleBufferDelegate>) delegate;
-(void) stopColorCamera;

- (void)startDepthSensor: (id<AVCaptureDepthDataOutputDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureDataOutputSynchronizerDelegate>) delegate;
- (void) stopDepthSensor;
- (bool) connected;

+ (bool)queryCameraAuthorizationStatusAndNotifyUserIfNotGranted;
+ (CGImageRef) imageFromSampleBuffer: (CMSampleBufferRef)sampleBuffer;
@end

NS_ASSUME_NONNULL_END
