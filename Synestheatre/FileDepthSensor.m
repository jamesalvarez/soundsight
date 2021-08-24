//
//  FileDepthSensor.m
//  Synestheatre
//
//  Created by James on 22/03/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import "FileDepthSensor.h"
#import <AVFoundation/AVFoundation.h>

@interface FileDepthSensor() {
    AVQueuePlayer *_player;
    AVPlayerItem *_playerItem;
    AVPlayerLooper *_looper;
    UIImage* _loadedImage;
    NSTimer* _timer;
    int _rows;
    int _cols;
    float _heightScale;
    float _widthScale;
    bool _pictureMode;
    bool _movieMode;
}

@end

@implementation FileDepthSensor

@synthesize newDataBlock;

@synthesize updateStatusBlock;

- (NSString *)getCentreDebugInfo {
    return @"";
}

- (UIImage *)getColourImage {
    return _loadedImage;
}

- (bool)getColours:(Colour *)outArray {
    
    if (!_loadedImage) return false;
    
    CGImageRef _image = [_loadedImage CGImage];
    
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
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    
    double x_ratio = _widthScale * (width - 1) / (_cols - 1);
    double y_ratio = _heightScale * (height - 1) / (_rows - 1);
    
    double x_left = (width - (width * _widthScale)) / 2;
    double y_top = (height - (height * _heightScale)) / 2;
    
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

- (bool)getDepthInMillimeters:(float *)outArray {
   
    //sample using nearest neighbor
    for (int col = 0; col < _cols; col += 1) {
        for (int row = 0; row < _rows; row += 1) {
            int mirrorRow = _rows - row - 1;
            int arrayIndex = (mirrorRow * _cols) + col;
            outArray[arrayIndex] = 0;
        }
    }
    
    return true;
}

- (UIImage *)getSensorImage {
    return _loadedImage;
}

- (void)setViewWindowWithRows:(int)rows cols:(int)cols heightScale:(float)heightScale widthScale:(float)widthScale {
    _rows = rows;
    _cols = cols;
    _heightScale = heightScale;
    _widthScale = widthScale;
}

- (void)startDepthSensor {
    _pictureMode = false;
    _movieMode = false;
    NSURL* url = [[NSUserDefaults standardUserDefaults] URLForKey:@"selected_file"];
    
    // First try loading image
    
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSLog(@"Loading %@", url);
    _loadedImage = nil;
    _loadedImage = [UIImage imageWithData:data];
    
    if (_loadedImage) {
        _pictureMode = true;
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                  target:self
                                                selector:@selector(onPictureTick:)
                                                userInfo:nil
                                                 repeats:YES];
        return;
    }
    
    // Next try loading video
    _playerItem = nil;
    _playerItem = [AVPlayerItem playerItemWithURL:url];
    
    if (_playerItem) {
        _movieMode = true;
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 / 20
                                                  target:self
                                                selector:@selector(onMovieTick:)
                                                userInfo:nil
                                                 repeats:YES];
        _player = [[AVQueuePlayer alloc] init];
        

        _looper = [AVPlayerLooper playerLooperWithPlayer:_player templateItem:_playerItem];
        
        [_player play];
    }
    
    
    
}

- (UIImage *)currentItemScreenShot
{
    
    CMTime time = [[_player currentItem] currentTime];
    AVAsset *asset = [[_player currentItem] asset];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    if ([imageGenerator respondsToSelector:@selector(setRequestedTimeToleranceBefore:)] && [imageGenerator respondsToSelector:@selector(setRequestedTimeToleranceAfter:)]) {
        [imageGenerator setRequestedTimeToleranceBefore:kCMTimeZero];
        [imageGenerator setRequestedTimeToleranceAfter:kCMTimeZero];
    }
    CGImageRef imgRef = [imageGenerator copyCGImageAtTime:time
                                               actualTime:NULL
                                                    error:NULL];
    if (imgRef == nil) {
        if ([imageGenerator respondsToSelector:@selector(setRequestedTimeToleranceBefore:)] && [imageGenerator respondsToSelector:@selector(setRequestedTimeToleranceAfter:)]) {
            [imageGenerator setRequestedTimeToleranceBefore:kCMTimePositiveInfinity];
            [imageGenerator setRequestedTimeToleranceAfter:kCMTimePositiveInfinity];
        }
        imgRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    }
    UIImage *image = [[UIImage alloc] initWithCGImage:imgRef];
    CGImageRelease(imgRef);

    return image;
}

- (void)onPictureTick:(NSTimer*)timer {
    newDataBlock();
}

- (void)onMovieTick:(NSTimer*)timer {
    _loadedImage = [self currentItemScreenShot];
    newDataBlock();
}

- (void)stopDepthSensor {
    [_timer invalidate];
    _timer = nil;

}

-(NSString*) getSensorType {
    return _pictureMode ? @"Picture mode" : @"Movie mode";
}

-(bool) isSensorConnected {
    return _pictureMode || _movieMode;
}
-(NSString*) sensorDisconnectionReason {
    return @"Media unable to load or no media selected.";
}

@end
