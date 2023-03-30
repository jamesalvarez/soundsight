

#import "DualCameraDepthSensor.h"

#import "AppDelegate.h"
#import "CameraManager.h"



@interface DualCameraDepthSensor () {
    void (^_updateStatusBlock)(NSString*);
    CameraManager *_cameraManager;
    AVCaptureDepthDataOutput* _depthDataOutput;
    AVCaptureVideoDataOutput* _colourDataOutput;
    PreviewView* _previewView;
    int _rows;
    int _cols;
    float _heightScale;
    float _widthScale;
}

@property AVDepthData *lastDepthData;
@property CGImageRef lastColourData;

@end

@implementation DualCameraDepthSensor

@synthesize newDataBlock;
@synthesize updateStatusBlock;

- (id)init {
    self = [super init];
    _cameraManager = [[CameraManager alloc] init];
    return self;
}

/**
 *  Starts the sensor
 */
-(void)startDepthSensor {
    
    [_cameraManager startDepthSensor:self];
    _depthDataOutput = [_cameraManager depthDataOutput];
    _colourDataOutput = [_cameraManager colourDataOutput];
}


/**
 *  Stops the sensor
 */
-(void)stopDepthSensor {
    [_cameraManager stopDepthSensor];
    _cameraManager = nil;
    _depthDataOutput = nil;
    _colourDataOutput = nil;
}

-(void)setViewWindowWithRows:(int)rows cols:(int)cols heightScale:(float)heightScale widthScale:(float)widthScale {
    _rows = rows;
    _cols = cols;
    _heightScale = heightScale;
    _widthScale = widthScale;
}

-(bool)getDepthInMillimeters:(float*)outArray {
    
    if (_lastDepthData == NULL) return false;
    
    // Depth is in meters
    CVPixelBufferRef pixelBuffer = _lastDepthData.depthDataMap;
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    Float32 *baseAddress = CVPixelBufferGetBaseAddress( pixelBuffer );
    
    if (baseAddress == nil) {
        CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
        return false;
    }
    
    //https://developer.apple.com/videos/play/wwdc2017/507/
    //Use 32 bit when on cpu, 16 on gpu
    //OSType type = CVPixelBufferGetPixelFormatType( pixelBuffer);
    //if (type != kCVPixelFormatType_DepthFloat32) {exit(0);}
    
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
            Float32 depthPixel = baseAddress[depthArrayIndex];
            
            int arrayIndex = (row * _cols) + col;
            
            outArray[arrayIndex] = (float)depthPixel * 1000; // Convert from meters to mm
            
        }
    }
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
    return true;
}

-(bool)getColours:(Colour*)outArray {
    
    if (_lastColourData == nil) return false;
    
    NSUInteger width = CGImageGetWidth(_lastColourData);
    NSUInteger height = CGImageGetHeight(_lastColourData);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
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
    
    const int gridWidth = 10;
    const int gridSize = 2;
    const int limit = gridWidth * gridSize;
    
    //sample using nearest neighbor
    for (int col = 0; col < _cols; ++ col) {
        for (int row = 0; row < _rows; ++row) {
            int nearestX = round(x_left + (x_ratio * col));
            int nearestY = round(y_top + (y_ratio * row));
            
            Colour c = { 0,0,0 };
            int nPixels = 0;
            
            int leftX = MAX(0, nearestX - limit);
            int rightX = MIN((int)width, nearestX + limit);
            int topY = MAX(0,nearestY - limit);
            int bottomY = MIN((int)height, nearestY + limit);
            
            for(int innerX = leftX; innerX <= rightX; innerX += gridWidth) {
                for(int innerY = topY; innerY <= bottomY; innerY += gridWidth) {
                    int depthArrayIndex = innerY  * (int)width + innerX;
                    UInt32 color = pixels[depthArrayIndex];
                    Colour newC = ConvertUint32(color);
                    
                    c.r += newC.r;
                    c.g += newC.g;
                    c.b += newC.b;
                    nPixels += 1;
                    
                }
            }
            
            c.r /= nPixels;
            c.g /= nPixels;
            c.b /= nPixels;
            
            
            int arrayIndex = (row * _cols) + col;
            
            outArray[arrayIndex] = c;
        }
    }
    
    free(pixels);
    return true;
}

#pragma debug images and info

-(UIImage*)getColourImage {
    UIImage* image = [[UIImage alloc] initWithCGImage:_lastColourData];
    return image;
}

-(UIImage*)getSensorImage {
    if (_lastDepthData == nil) return nil;
    CIImage* image = [CIImage imageWithCVPixelBuffer:_lastDepthData.depthDataMap];
    return [UIImage imageWithCIImage:image];
}

-(NSString*) getCentreDebugInfo {
    if (_lastDepthData == NULL) return @"No depth data from dual-cam";
    
    // Depth is in meters
    CVPixelBufferRef pixelBuffer = _lastDepthData.depthDataMap;
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    size_t frame_cols = CVPixelBufferGetWidth(pixelBuffer);
    size_t frame_rows = CVPixelBufferGetHeight(pixelBuffer);
    
    if (frame_cols == 0 || frame_rows == 0) return @"No data";
    
    
    Float32 *baseAddress = CVPixelBufferGetBaseAddress( pixelBuffer );
    long nearestX = frame_cols / 2;
    long nearestY = frame_rows / 2;
    long depthArrayIndex = nearestY  * frame_cols + nearestX;
    Float32 depthPixel = baseAddress[depthArrayIndex];
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0);
    return [NSString stringWithFormat:@"Dual cam depth: %.f mm",depthPixel * 1000];
}

#pragma mark delegate methods

- (void)dataOutputSynchronizer:(AVCaptureDataOutputSynchronizer *)synchronizer didOutputSynchronizedDataCollection:(AVCaptureSynchronizedDataCollection *)synchronizedDataCollection {
    
    //Extract synchronized data
    AVDepthData *depthData = ((AVCaptureSynchronizedDepthData*)[synchronizedDataCollection synchronizedDataForCaptureOutput:_depthDataOutput]).depthData;
    CMSampleBufferRef colourData = ((AVCaptureSynchronizedSampleBufferData*)[synchronizedDataCollection synchronizedDataForCaptureOutput:_colourDataOutput]).sampleBuffer;
    
    // Convert to usable formats
    CGImageRef newImage = [CameraManager imageFromSampleBuffer:colourData];
    
    if (newImage == nil) return;
    
    AVDepthData* convertedDepthData = [depthData depthDataByConvertingToDepthDataType:kCVPixelFormatType_DepthFloat32];
    
    // Dispatch state change on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        CGImageRelease(self->_lastColourData);
        self->_lastDepthData = convertedDepthData;
        self->_lastColourData = newImage;
        self.newDataBlock();
    });
    
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    CGImageRef newImage = [CameraManager imageFromSampleBuffer:sampleBuffer];
    dispatch_async(dispatch_get_main_queue(), ^{
        CGImageRelease(self->_lastColourData);
        self->_lastColourData = newImage;
        self.newDataBlock();
    });
}

- (void)depthDataOutput:(AVCaptureDepthDataOutput *)output didOutputDepthData:(AVDepthData *)depthData timestamp:(CMTime)timestamp connection:(AVCaptureConnection *)connection
{
    AVDepthData* convertedDepthData = [depthData depthDataByConvertingToDepthDataType:kCVPixelFormatType_DepthFloat32];
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_lastDepthData = convertedDepthData;
        self.newDataBlock();
    });
}

-(NSString*) getSensorType {
    return @"Dual camera";
}

-(bool) isSensorConnected {
    return [_cameraManager connected];
}
-(NSString*) sensorDisconnectionReason {
    return @"Built in camera error";
}

-(void)setPreviewView:(PreviewView*)previewView {
    [_cameraManager setPreviewView:previewView];
}

@end


