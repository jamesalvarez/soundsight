//
//  FlirOneDepthSensor.m
//  Synestheatre
//
//  Created by James on 10/01/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import "FlirOneDepthSensor.h"
#import "Toast.h"

@interface FlirOneDepthSensor() {
    bool _connected;
    bool _active;
    bool _useMSX;
    
    int _rows;
    int _cols;
    float _heightScale;
    float _widthScale;
}

@property (nonatomic) FLIROneSDKImageOptions options;

@property (strong, nonatomic) UIImage *thermalImage;
@property (strong, nonatomic) UIImage *radiometricImage;
@property (strong, nonatomic) UIImage *visualYCbCrImage;
@property (strong, nonatomic) NSData *thermalData;
@property (nonatomic) CGSize thermalSize;
@end

@implementation FlirOneDepthSensor

@synthesize newDataBlock;
@synthesize updateStatusBlock;

-(instancetype)initWithMSX:(bool)useMSX {
    if ( !(self = [super init])) return nil;
    
    _connected = false;
    _useMSX = useMSX;
    
    NSLog(@"Flir SDK Version %@",[FLIROneSDK version]);
    
    //set the options to MSX blended and float kelvin
    // MSX blended is for debug image, float kelvin is for actual data
    if (_useMSX) {
        self.options = FLIROneSDKImageOptionsBlendedMSXRGBA8888Image  |
        FLIROneSDKImageOptionsThermalRadiometricKelvinImageFloat;
    } else {
        self.options = FLIROneSDKImageOptionsBlendedMSXRGBA8888Image | FLIROneSDKImageOptionsThermalRadiometricKelvinImageFloat |
        FLIROneSDKImageOptionsVisualYCbCr888Image;
    }
    
    [[FLIROneSDKStreamManager sharedInstance] addDelegate:self];
    [[FLIROneSDKStreamManager sharedInstance] setFrameDropEnabled:YES];

    return self;
}

- (void)dealloc {
    [[FLIROneSDKStreamManager sharedInstance] removeDelegate:self];
}

-(bool)canConnect {
    return _connected;
}

-(void)setViewWindowWithRows:(int)rows cols:(int)cols heightScale:(float)heightScale widthScale:(float)widthScale {
    _rows = rows;
    _cols = cols;
    _heightScale = heightScale;
    _widthScale = widthScale;
}

- (bool)getDepthInMillimeters:(float *)outArray {
    
    if (!_connected || self.thermalData == nil || !_active) return false;
    
    float *tempDataFloat = (float *)[self.thermalData bytes];
    if (tempDataFloat == nil) return false;
    
    // data is rotated
    float width = self.thermalSize.width;
    float height = self.thermalSize.height;
    
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
    for (int col = 0; col < _cols; col += 1) {
        for (int row = 0; row < _rows; row += 1) {
            
            
            int nearestX = round(x_left + (x_ratio * col));
            int nearestY = round(y_top + (y_ratio * row));
            size_t index = (nearestX * width) + nearestY;
            
            // Temperature is in kelvin C = K - 273,15
            // Lets assume most temps useful are from 0 to 50,
            // with anything over that beign dangrously close
            // Then we want 50 tobe 0mm, 0 to be 3000mm
            // mm = -60* C + 3000
            float temp = ((tempDataFloat[index] - 273.15) * -60) + 3000;

            int mirrorRow = _rows - row - 1;
            int arrayIndex = (mirrorRow * _cols) + col;
            
            outArray[arrayIndex] = temp;
        }
    }
    
    return true;
}

- (bool)getColours:(Colour *)outArray {
    if (!_connected || !_active) return false;
    
    
    CGImageRef _image;
    
    if (_useMSX) {
        if (!_thermalImage) return false;
        _image = [_thermalImage CGImage];
    } else {
        if (!_visualYCbCrImage) return false;
        _image = [_visualYCbCrImage CGImage];
    }
    
    // Prevent crashes
    if (!_image) return false;
  
    NSUInteger width = CGImageGetWidth(_image);
    NSUInteger height = CGImageGetHeight(_image);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    UInt32 * pixels = (UInt32 *) calloc(height * width, sizeof(UInt32));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), _image);
    
    // Cleanup
    //CGImageRelease(_image);
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



-(UIImage*)getColourImage {
    
    if (!_active) return nil;
    
    if (_useMSX) {
        return self.thermalImage;
    } else {
        return self.visualYCbCrImage;
    }
    
}

- (UIImage *)getSensorImage {
    
    if (!_active) return nil;
    return self.thermalImage;
}

- (void)startDepthSensor {
    _active = true;
    [[FLIROneSDKStreamManager sharedInstance] setImageOptions:self.options];
    
}

- (void)stopDepthSensor {
    _active = false;
    [[FLIROneSDKStreamManager sharedInstance] setImageOptions:0];
}


/**
 Triggered just after the FLIR ONE device has established communication. This is the first event received when a device connects. You MUST be connected to the FLIR ONE device in order to receive frames or any information from the device. If your application is not receiving this event insure that the project dependencies are set up correctly and that the device is working.
 */
- (void) FLIROneSDKDidConnect {
    _connected = true;
    NSLog(@"FLIROneSDKDidConnect");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SensorChanged" object:self];
}

/**
 Triggered just after FLIR ONE device has lost communication. This will only fire if connectivity was previously established.
 */
- (void) FLIROneSDKDidDisconnect {
    _connected = false;
    NSLog(@"FLIROneSDKDidDisconnect");
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"SensorChanged" object:self];
}

/** Recieve blended image for debug image prurposes */
- (void)FLIROneSDKDelegateManager:(FLIROneSDKDelegateManager *)delegateManager didReceiveBlendedMSXRGBA8888Image:(NSData *)msxImage imageSize:(CGSize)size sequenceNumber:(NSInteger)sequenceNumber {
    if (!_active) return;
    
    FlirOneDepthSensor * __weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *image = [FLIROneSDKUIImage imageWithFormat:FLIROneSDKImageOptionsBlendedMSXRGBA8888Image andData:msxImage andSize:size];
        weakSelf.thermalImage = [weakSelf rotateImage90Degrees: image];
    });
}

/** Recieve camera info for colour cat purproses
 This format is the visual data from the camera, adjusted to better align with the thermal stream, and is in portrait orientation. The data is row major, with each pixel composed of Y, Cb, and Cr bytes.
 */
- (void)FLIROneSDKDelegateManager:(FLIROneSDKDelegateManager *)delegateManager didReceiveVisualYCbCr888Image:(NSData *)visualYCbCr888Image imageSize:(CGSize)size sequenceNumber:(NSInteger)sequenceNumber {
    if (!_active) return;
    
    FlirOneDepthSensor * __weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *image = [FLIROneSDKUIImage imageWithFormat:FLIROneSDKImageOptionsVisualYCbCr888Image andData:visualYCbCr888Image andSize:size];
        weakSelf.visualYCbCrImage = [weakSelf rotateImage90Degrees: image];
    });
}

/** Recieve raw temp data in kelvin */
- (void)FLIROneSDKDelegateManager:(FLIROneSDKDelegateManager *)delegateManager didReceiveRadiometricDataFloat:(NSData *)radiometricData imageSize:(CGSize)size sequenceNumber:(NSInteger)sequenceNumber {
    if (!_active) return;
    
    FlirOneDepthSensor * __weak weakSelf = self;
    @synchronized(self) {
        weakSelf.thermalData = radiometricData;
        weakSelf.thermalSize = size;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.newDataBlock();
    });
}

/** The images come out at a 90 degree rotation, and need to be rotated back*/
- (UIImage *)rotateImage90Degrees:(UIImage*)oldImage {
    
    CGSize rotatedSize = CGSizeMake(oldImage.size.height, oldImage.size.width);
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    // Rotate the image context
    CGContextRotateCTM(bitmap, -(M_PI / 2));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-oldImage.size.width / 2, -oldImage.size.height / 2, oldImage.size.width, oldImage.size.height), [oldImage CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


-(NSString*) getCentreDebugInfo {
    
    if (!_connected || self.thermalData == nil || !_active) return @"No data from Fir sensor";
    
    float *tempDataFloat = (float *)[self.thermalData bytes];
    if (tempDataFloat == nil) return false;
    
    // get centre pixel
    int frame_rows = self.thermalSize.width;
    int centreX = self.thermalSize.width / 2;
    int centreY = self.thermalSize.height / 2;
    size_t index = (centreX * frame_rows) + centreY;
    
    float temp = tempDataFloat[index] - 273.15;

    
    
    return [NSString stringWithFormat:@"Centre Temp: %.01f C", temp];
}

-(NSString*) getSensorType {
    return @"Flir One";
}

-(bool) isSensorConnected {
    return _connected;
}
-(NSString*) sensorDisconnectionReason {
    return @"Waiting for Flir to connect.";
}

@end
