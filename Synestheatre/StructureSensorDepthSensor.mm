/*
 This file was adapted from an example in the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "StructureSensorDepthSensor.h"
#import <Structure/StructureSLAM.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
#import <algorithm>
#import "Toast.h"
#import "CameraManager.h"

@interface StructureSensorDepthSensor () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    
    CameraManager *_cameraManager;
    STSensorController *_sensorController;
    STDepthToRgba *_converter;
    STDepthFrame *_currentDepthFrame;
    CGImageRef _lastColourData;
    uint8_t *_coloredDepthBuffer;
    uint8_t *_colorImageBuffer;

    bool _active;
    bool _connected;
    
    int _rows;
    int _cols;
    float _heightScale;
    float _widthScale;
}

@end





@implementation StructureSensorDepthSensor

@synthesize newDataBlock;
@synthesize updateStatusBlock;

-(instancetype)init {
    if ( !(self = [super init])) return nil;
    
    _converter = [[STDepthToRgba alloc] initWithOptions: @{ kSTDepthToRgbaStrategyKey :
         [[NSNumber alloc] initWithInteger: STDepthToRgbaStrategyRedToBlueGradient]}];
    _cameraManager = [[CameraManager alloc] init];
    _currentDepthFrame = nil;
    _coloredDepthBuffer = nil;
    _lastColourData = nil;
    _active = false;
    _connected = false;
    return self;
}

-(void)startDepthSensor {
    _active = true;
    _sensorController = [STSensorController sharedController];
    _sensorController.delegate = self;
    [self connectAndStartStreaming];
}


-(void)stopDepthSensor {
    _active = false;
    _sensorController.delegate = nil;
    [_cameraManager stopColorCamera];
    [_sensorController stopStreaming];
}

-(void)setViewWindowWithRows:(int)rows cols:(int)cols heightScale:(float)heightScale widthScale:(float)widthScale {
    _rows = rows;
    _cols = cols;
    _heightScale = heightScale;
    _widthScale = widthScale;
}

- (void)dealloc
{
    free(_coloredDepthBuffer);
    free(_colorImageBuffer);
}


-(bool)canConnect {
    STSensorControllerInitStatus result = [_sensorController initializeSensorConnection];
    
    bool didSucceed =
    result == STSensorControllerInitStatusSuccess
    || result == STSensorControllerInitStatusAlreadyInitialized;
    
    if (!didSucceed) {
        NSString* errorMsg = @"Unknown Error";
        if (result == STSensorControllerInitStatusSensorNotFound)
            errorMsg = @"[Debug] No Structure Sensor found!";
        else if (result == STSensorControllerInitStatusOpenFailed)
            errorMsg = @"[Error] Structure Sensor open failed.";
        else if (result == STSensorControllerInitStatusSensorIsWakingUp)
            errorMsg = @"[Debug] Structure Sensor is waking from low power.";
        else if (result != STSensorControllerInitStatusSuccess)
            errorMsg = [NSString stringWithFormat: @"[Debug] Structure Sensor failed to init with status %d.", (int)result];
        //[Toast sendToast:errorMsg];
        NSLog(@"%@", errorMsg);
    }
    
    return didSucceed;
}

- (BOOL)connectAndStartStreaming
{
    if (!_active || !self.canConnect) return false;
    
    // Start the color camera, setup if needed.
    [_cameraManager startColorCamera: self];
    
    // Set sensor stream quality.
    STStreamConfig streamConfig = STStreamConfigDepth320x240;
    
    // Request that we receive depth frames with synchronized color pairs.
    // After this call, we will start to receive frames through the delegate methods.
    
    NSError* error = nil;
    
    BOOL optionsAreValid = [_sensorController
                            startStreamingWithOptions:@{
                                kSTStreamConfigKey : @(streamConfig),
                                kSTFrameSyncConfigKey:@(STFrameSyncDepthAndRgb),
                                kSTHoleFilterEnabledKey:@TRUE }
                            error:&error ];
    
    if (!optionsAreValid)
    {
        NSString * e = [NSString stringWithFormat:@"Error during streaming start: %@", [error localizedDescription]];
        NSLog(@"%@", e);
        
        [Toast makeToast:e];
        return false;
    }
        
   
    [Toast makeToast:@"Sensor Connected"];
    _connected = true;
    return true;
}

//------------------------------------------------------------------------------

#pragma mark -
#pragma mark Structure SDK + AV Capture Delegate Methods

- (void)sensorDidDisconnect {
    NSLog(@"Structure Sensor disconnected!");
    [self stopDepthSensor];
    _connected = false;
}

- (void)sensorDidConnect {
    NSLog(@"Structure Sensor connected!");
    _connected = true;
}
- (void)sensorDidLeaveLowPowerMode {}
- (void)sensorBatteryNeedsCharging {}

- (void)sensorDidStopStreaming:(STSensorControllerDidStopStreamingReason)reason {
    NSLog(@"Structure Sensor stopped streaming!");
    _connected = false;
    // Stop the color camera when we're not streaming from the Structure Sensor.
    [self stopDepthSensor];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    // Pass the sample buffer to the driver.
    [_sensorController frameSyncNewColorBuffer:sampleBuffer];
}

/*
- (void)sensorDidOutputDepthFrame:(STDepthFrame *)depthFrame {
    // Dispatch state change on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_currentDepthFrame = depthFrame;
        self.newDataBlock();
    });
}*/

// This synchronized API will only be called when two frames match.
// Typically, timestamps are within 1ms of each other.
- (void)sensorDidOutputSynchronizedDepthFrame:(STDepthFrame *)depthFrame
                                   colorFrame:(STColorFrame *)colorFrame {
    // Dispatch state change on main thread
    CGImageRef newImage = [CameraManager imageFromSampleBuffer:colorFrame.sampleBuffer];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_currentDepthFrame = depthFrame;
        if (self->_lastColourData != nil) {
            CGImageRelease(self->_lastColourData);
            self->_lastColourData = nil;
        }
        
        self->_lastColourData = newImage;
        self.newDataBlock();
    });
}


//------------------------------------------------------------------------------

#pragma mark -
#pragma mark Rendering




-(UIImage*)getSensorImage
{
    if (_currentDepthFrame == NULL) return NULL;
    
    size_t cols = _currentDepthFrame.width;
    size_t rows = _currentDepthFrame.height;
    
    _coloredDepthBuffer = [_converter convertDepthFrameToRgba:_currentDepthFrame];
  
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGBitmapInfo bitmapInfo;
    bitmapInfo = (CGBitmapInfo)kCGImageAlphaNoneSkipLast;
    bitmapInfo |= kCGBitmapByteOrder32Big;
    
    NSData *data = [NSData dataWithBytes:_coloredDepthBuffer length:cols * rows * 4];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data); //toll-free ARC bridging
    
    CGImageRef imageRef = CGImageCreate(cols,                       //width
                                        rows,                        //height
                                        8,                           //bits per component
                                        8 * 4,                       //bits per pixel
                                        cols * 4,                    //bytes per row
                                        colorSpace,                  //Quartz color space
                                        bitmapInfo,                  //Bitmap info (alpha channel?, order, etc)
                                        provider,                    //Source of data for bitmap
                                        NULL,                        //decode
                                        false,                       //pixel interpolation
                                        kCGRenderingIntentDefault);  //rendering intent
    
    // Assign CGImage to UIImage
    UIImage* image = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

-(UIImage*)getColourImage {
    UIImage* image = [[UIImage alloc] initWithCGImage:_lastColourData];
    return image;
}

//------------------------------------------------------------------------------

#pragma mark -
#pragma mark Depth and Colour

-(bool)getDepthInMillimeters:(float*)outArray   {
    
    if (_currentDepthFrame == NULL) {
        return false;
    }
    
    size_t width = _currentDepthFrame.width;
    size_t height = _currentDepthFrame.height;
    
    const float* depthValues = _currentDepthFrame.depthInMillimeters;
    
    //for some reason the depth sensor outputs a few missing pixels on the right
    //it should be (width - 1) to get the last pixel on the right, but these
    //all give missing values ... so -5 takes us just slightly left of this dark
    //patch.
    double x_ratio;
    double y_ratio;
    
    double x_left;
    double y_top;
    
    // Case when only one col or row
    if (_cols == 1) {
        x_ratio = 0;
        x_left = width / 2;
    } else {
        x_ratio = _widthScale * (width - 5) / (_cols - 1);
        x_left = (width - (width * _widthScale)) / 2;
    }
    
    if (_rows == 1) {
        y_ratio = 0;
        y_top = height / 2;
    } else {
        y_ratio = _heightScale * (height - 5) / (_rows - 1);
        y_top = (height - (height * _heightScale)) / 2;
    }
    
    
    
    //sample using nearest neighbor
    for (int col = 0; col < _cols; ++ col) {
        for (int row = 0; row < _rows; ++row) {
            int nearestX = round(x_left + (x_ratio * col));
            int nearestY = round(y_top + (y_ratio * row));
            
            size_t index = (nearestY * width) + nearestX;
            float depth = depthValues[index];
            
            int arrayIndex = (row * _cols) + col;
            
            outArray[arrayIndex] = depth;
            
        }
    }
    
    return true;
}

-(NSString*) getCentreDebugInfo {
    if (_currentDepthFrame == NULL) return @"No depth data from structure sensor";
    
    const float* depthValues = _currentDepthFrame.depthInMillimeters;
    size_t frame_cols = _currentDepthFrame.width;
    size_t frame_rows = _currentDepthFrame.height;
    
    long nearestX = frame_cols / 2;
    long nearestY = frame_rows / 2;
    size_t index = (nearestY * frame_cols) + nearestX;
    float depth = depthValues[index];
    return [NSString stringWithFormat:@"Structure sensor depth: %.f mm",depth];
}

-(bool)getColours:(Colour*)outArray {
    
    if (_lastColourData == nil) return false;
    
    NSUInteger width = CGImageGetWidth(_lastColourData);
    NSUInteger height = CGImageGetHeight(_lastColourData);
    NSUInteger bytesPerRow = CGImageGetBytesPerRow(_lastColourData);
    NSUInteger bitsPerComponent = CGImageGetBitsPerComponent(_lastColourData);
    
    UInt32 * pixels = (UInt32 *) calloc(height * width, sizeof(UInt32));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), _lastColourData);
    
    // Cleanup
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    
    double x_ratio;
    double y_ratio;
    
    double x_left;
    double y_top;
    
    // Case when only one col or row
    if (_cols == 1) {
        x_ratio = 0;
        x_left = width / 2;
    } else {
        x_ratio = _widthScale * (width - 1) / (_cols - 1);
        x_left = (width - (width * _widthScale)) / 2;
    }
    
    if (_rows == 1) {
        y_ratio = 0;
        y_top = height / 2;
    } else {
        y_ratio = _heightScale * (height - 1) / (_rows - 1);
        y_top = (height - (height * _heightScale)) / 2;
    }
    
    //sample using nearest neighbor
    for (int col = 0; col < _cols; ++ col) {
        for (int row = 0; row < _rows; ++row) {
            int nearestX = round(x_left + (x_ratio * col));
            int nearestY = round(y_top + (y_ratio * row));
            
            int depthArrayIndex = nearestY  * (int)width + nearestX;
            UInt32 color = pixels[depthArrayIndex];
            
            int arrayIndex = (row * _cols) + col;
            
            outArray[arrayIndex] = ConvertUint32(color);
        }
    }
    
    
    free(pixels);
    return true;
}

-(NSString*) getSensorType {
    return @"Structure sensor";
}

-(bool) isSensorConnected {
    return _connected;
}
-(NSString*) sensorDisconnectionReason {
    
    STSensorControllerInitStatus result = [_sensorController initializeSensorConnection];
    
    bool didSucceed =
    result == STSensorControllerInitStatusSuccess
    || result == STSensorControllerInitStatusAlreadyInitialized;
    
    if (!didSucceed) {
        NSString* errorMsg = @"Unknown Error";
        if (result == STSensorControllerInitStatusSensorNotFound)
            errorMsg = @"No Structure Sensor found!";
        else if (result == STSensorControllerInitStatusOpenFailed)
            errorMsg = @"Structure Sensor open failed.";
        else if (result == STSensorControllerInitStatusSensorIsWakingUp)
            errorMsg = @"Structure Sensor is waking from low power.";
        else if (result != STSensorControllerInitStatusSuccess)
            errorMsg = [NSString stringWithFormat: @"Structure Sensor failed to init with status %d.", (int)result];
    
    
        return errorMsg;
    }
    
    return @"";
}


@end
