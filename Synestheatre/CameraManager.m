//
//  CameraManager.m
//  Synestheatre
//
//  Created by James on 01/02/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import "CameraManager.h"
#import "Toast.h"

void BufferReleaseCallback(void *releaseRefCon, const void *baseAddress){
    free ((Float32*)baseAddress);
}

@interface CameraManager () {
    PreviewView *_previewView;
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_captureDevice;
    AVCaptureDataOutputSynchronizer *_synchronizer;
    id<AVCaptureVideoDataOutputSampleBufferDelegate> _delegate;
}

@end

@implementation CameraManager

-(void)setPreviewView:(PreviewView*)previewView {
    _previewView = previewView;
}

-(void) startColorCamera: (id<AVCaptureVideoDataOutputSampleBufferDelegate>) delegate
{
    if (_delegate == delegate && _captureSession && [_captureSession isRunning])
        return;
    
    if (_delegate != delegate || _captureSession == nil) {
        _delegate = delegate;
        [self setupColorCamera];
    }
    
    // Start streaming color sample buffers.
    [_captureSession startRunning];
}

- (void)startDepthSensor: (id<AVCaptureDepthDataOutputDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureDataOutputSynchronizerDelegate>) delegate
{
    if (![CameraManager queryCameraAuthorizationStatusAndNotifyUserIfNotGranted]) {
        return;
    }

    // Select the back camera with Lidar
    _captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInLiDARDepthCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];

    NSError *error = nil;
    AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];

    bool hasDualCamera = true;

    if (!captureDeviceInput)
    {
        NSLog(@"%@", [NSString stringWithFormat:@"Unable to obtain lidar capture device input, error: %@", error]);

        // Select the back camera with Dual Camera
        _captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];

        captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];

        if (!captureDeviceInput)
        {
            NSLog(@"%@", [NSString stringWithFormat:@"Unable to obtain dual cam capture device input, error: %@", error]);
            hasDualCamera = false;

            // Just use camera
            _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

            captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];

            if (!captureDeviceInput)
            {
                NSLog(@"%@", [NSString stringWithFormat:@"Unable to obtain capture device input, error: %@", error]);
                return;
            }
        }
    }
    
    
    // create the capture session
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    
    // begin configure capture session
    [_captureSession beginConfiguration];
    
    // connect the video device input and video data and still image outputs
    [_captureSession addInput:captureDeviceInput];
    
    if (hasDualCamera) {
        // create and configure depth data output
        _depthDataOutput = [[AVCaptureDepthDataOutput alloc] init];
        _depthDataOutput.filteringEnabled = TRUE;
        _depthDataOutput.alwaysDiscardsLateDepthData = TRUE;
        
        
        // create the dispatch queue for handling capture session delegate method calls
        [_depthDataOutput setDelegate:delegate callbackQueue:dispatch_get_main_queue()];
        
        if (![_captureSession canAddOutput:_depthDataOutput])
        {
            NSLog(@"Cannot add depth data output");
            _captureSession = nil;
            return;
        }
        
        [_captureSession addOutput:_depthDataOutput];
        
        AVCaptureConnection *connection = [_depthDataOutput connectionWithMediaType:AVMediaTypeDepthData];
        if (connection != nil) {
            [connection setEnabled:TRUE];
        } else {
            NSLog(@"No connection");
        }
    }
    
    _colourDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_colourDataOutput setVideoSettings:@{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)}];
    [_colourDataOutput setSampleBufferDelegate:delegate queue:dispatch_get_main_queue()];
    [_captureSession addOutput:_colourDataOutput];
    
    
    if (hasDualCamera) {
        _synchronizer = [[AVCaptureDataOutputSynchronizer alloc] initWithDataOutputs: @[_depthDataOutput, _colourDataOutput]];
        [_synchronizer setDelegate:delegate queue:dispatch_get_main_queue()];
        
        // get the current format
        AVCaptureDeviceFormat* currentFormat = _captureDevice.activeDepthDataFormat;
        NSLog(@"%@",currentFormat.description);
    }
    
    // Enforce 20 FPS capture rate.
    if([_captureDevice lockForConfiguration:&error])
    {
        [_captureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 20)];
        [_captureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 20)];
        [_captureDevice unlockForConfiguration];
    }
    
    
    [_captureSession commitConfiguration];
    
    [_previewView setSession:_captureSession];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // then start everything
        [self->_captureSession startRunning];
    });

}

-(void)stopDepthSensor {
    
    [_captureSession stopRunning];
    _captureSession = nil;
    _synchronizer = nil;
    _depthDataOutput = nil;
    _colourDataOutput = nil;
    _captureDevice = nil;
}

- (bool) connected  {
    return _captureSession != nil && [_captureSession isRunning];
}

+ (bool)queryCameraAuthorizationStatusAndNotifyUserIfNotGranted {
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized)
        return true;
    if (status == AVAuthorizationStatusDenied) {
        //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options: @{} completionHandler:nil];
        [Toast makeToast:@"This app needs camera permission to work!"];
        return false;
    }
    
    NSLog(@"Not authorized to use the camera!");
    
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                     completionHandler:^(BOOL granted) {
                         if (!granted) {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 NSLog(@"User denied camera access!");

                             });
                         }
                     }];
    
    return false;
}

- (void)setupColorCamera
{
    // Stop current session.
    if (_captureSession)
        [self stopColorCamera];
    
    // Ensure that camera access was properly granted.
    if (![CameraManager queryCameraAuthorizationStatusAndNotifyUserIfNotGranted]) return;
    
    // Set up the capture session.
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession beginConfiguration];
    
    
    // Capture color frames at VGA resolution.
    [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    // Create a video device.
    _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    assert(_captureDevice != nil);
    
    NSError *error = nil;
    
    // Use auto-exposure, and auto-white balance and set the focus to infinity.
    
    if([_captureDevice lockForConfiguration:&error])
    {
        // Allow exposure to change
        if ([_captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
            [_captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        
        // Allow white balance to change
        if ([_captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
            [_captureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        
        // Set focus at the maximum position allowable (e.g. "near-infinity") to get the
        // best color/depth alignment.
        [_captureDevice setFocusModeLockedWithLensPosition:1.0f completionHandler:nil];
        
        [_captureDevice unlockForConfiguration];
    }
    
    // Create the video capture device input.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    
    if (error)
    {
        NSLog(@"Cannot initialize AVCaptureDeviceInput");
        assert(0);
    }
    
    // Add the input to the capture session.
    [_captureSession addInput:input];
    
    //  Create the video data output.
    AVCaptureVideoDataOutput* dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    // We don't want to process late frames.
    [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    // Use kCVPixelFormatType_420YpCbCr8BiPlanarFullRange format.
    [dataOutput setVideoSettings:@{ (NSString*)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA) }];
    
    // Dispatch the capture callbacks on the main thread, where OpenGL calls can be made synchronously.
    [dataOutput setSampleBufferDelegate:_delegate queue:dispatch_get_main_queue()];
    
    // Add the output to the capture session.
    [_captureSession addOutput:dataOutput];
    
    // Enforce 20 FPS capture rate.
    if([_captureDevice lockForConfiguration:&error])
    {
        [_captureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, 20)];
        [_captureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, 20)];
        [_captureDevice unlockForConfiguration];
    }
    
    // Read in Apple Intrinsics, if required
    AVCaptureConnection *conn = [dataOutput connectionWithMediaType:AVMediaTypeVideo];
    conn.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeOff;

    if (@available(iOS 11_0, *))
    {
        if (conn.isCameraIntrinsicMatrixDeliverySupported)
            conn.cameraIntrinsicMatrixDeliveryEnabled = YES;
    }

    
    [_captureSession commitConfiguration];
}


- (void)stopColorCamera
{
    if ([_captureSession isRunning])
    {
        [_captureSession stopRunning];
    }
    
    _captureSession = nil;
    _captureDevice = nil;
}

// Create a CGImage from sample buffer data
+ (CGImageRef) imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    // Helpful for debugging when this goes wrong
    //CMFormatDescriptionRef descr = CMSampleBufferGetFormatDescription(sampleBuffer);
    //bool isReady = CMSampleBufferDataIsReady(sampleBuffer);
    //bool isValid = CMSampleBufferIsValid(sampleBuffer);
    
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    if (imageBuffer == nil) {
        NSLog(@"Error getting image buffer - CameraManager - imageFromSampleBuffer");
        return nil;
    }
    
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little
                                                 | kCGImageAlphaPremultipliedFirst);
    
    // Create a copied CGImage image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    // Unlock the pixel buffer, Free up the context and color space
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    return quartzImage;
}


@end
