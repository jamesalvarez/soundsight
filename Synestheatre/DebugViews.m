//
//  DebugViews.m
//  Synestheatre
//
//  Created by James on 03/08/2018.
//  Copyright © 2018 James. All rights reserved.
//

#import "DebugViews.h"
#import "TransparentLabelView.h"
/**
 * DebugViews: Seperate class to control all drawing of debug images etc.
 */
@interface DebugViews () {
    NSString* _viewMode;
    bool _showDebugText;
}
@end

@implementation DebugViews

+(DebugViews*) sharedManager {
    static DebugViews *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(void) displaySynestheatreConsoleText:(NSString*)text {
    [_synestheatreConsoleTextView setText:text];
}

-(void) displaySensorConsoleText:(NSString*)text {
    [_sensorConsoleTextView setText:text];
}

-(void) displayCentreColour:(UIImage*)colourImage {
    _colourImageView.image = colourImage;
}

-(void) updateSensorImage {
    
    if ([_viewMode isEqualToString:@"vr_mode"]) {
        UIImage* debugImage = [self debugImage];
        _rightImageView.image =  debugImage;
        _leftImageView.image = debugImage;
    } else if ([_viewMode isEqualToString:@"depth_mode"]) {
        UIImage* debugImage = [self debugImage];
        UIImage* sensorImage = [self sensorImage];
        _rightImageView.image =  debugImage;
        _leftImageView.image = sensorImage;
    } else if ([_viewMode isEqualToString:@"cam_mode"]) {
        UIImage* debugImage = [self debugImage];
        UIImage* colourImage = [self colourImage];
        _rightImageView.image =  debugImage;
        _leftImageView.image = colourImage;
    }else if ([_viewMode isEqualToString:@"depth_cam_mode"]) {
        UIImage* colourImage = [self colourImage];
        UIImage* sensorImage = [self sensorImage];
        _rightImageView.image =  colourImage;
        _leftImageView.image = sensorImage;
    }
}

-(void) setupWithParent:(UIView*)parent {
    
    static bool viewsCreated = false;
    
    if (viewsCreated) {
        [NSException raise:@"Attempting to set up views twice" format:@"Attempting to set up views twice"];
    }
    viewsCreated = true;
    
    // Each image is the size of half the screen.  The screen is always landscape, so
    // the width is divided by 2 to split this.
    CGSize imageSize = CGSizeMake(parent.frame.size.width/2, parent.frame.size.height);
    CGRect leftFrame = CGRectMake(0,0, imageSize.width, imageSize.height);
    CGRect rightFrame = CGRectMake(imageSize.width, 0, imageSize.width, imageSize.height);
    CGRect topTextViewFrame = CGRectMake(0, 0, parent.frame.size.width, 50);
    CGRect bottomTextViewFrame = CGRectMake(0, parent.frame.size.height - 50, parent.frame.size.width, 50);
    // Set the BG colour to black
    parent.backgroundColor = [UIColor blackColor];
    
    
    // Create two black image views for each half of the display
    UIGraphicsBeginImageContextWithOptions(imageSize, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [parent.backgroundColor setFill];
    CGContextFillRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *image2 = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // remove all sub views
    [[parent subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    // Create image view on left side of screen
    _leftImageView = [[UIImageView alloc] initWithFrame:leftFrame];
    _leftImageView.contentMode = UIViewContentModeScaleAspectFit;
    _leftImageView.image = image;
    [parent addSubview:_leftImageView];
    
    // Create image view on right side of screen
    _rightImageView = [[UIImageView alloc] initWithFrame:rightFrame];
    _rightImageView.contentMode = UIViewContentModeScaleAspectFit;
    _rightImageView.image = image2;
    [parent addSubview:_rightImageView];
    
    _synestheatreConsoleTextView = [[TransparentLabelView alloc] initWithFrame:topTextViewFrame];
    [parent addSubview:_synestheatreConsoleTextView];
    
    _sensorConsoleTextView = [[TransparentLabelView alloc] initWithFrame:bottomTextViewFrame];
    [parent addSubview:_sensorConsoleTextView];

    // Add a debug colour view
    CGRect cornerFrame = CGRectMake(0,0, 20, 20);
    _colourImageView = [[UIImageView alloc] initWithFrame:cornerFrame];
    [parent addSubview:_colourImageView];
    
    [self reset];
}

-(void) reset {
    _viewMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"view_mode"];
    _showDebugText = [[NSUserDefaults standardUserDefaults] boolForKey:@"debug_text"];
    
    [_sensorConsoleTextView setHidden:!_showDebugText];
    [_synestheatreConsoleTextView setHidden:!_showDebugText];
    [_colourImageView setHidden:!_showDebugText];
}

-(void) clear {
    _rightImageView.image =  nil;
    _leftImageView.image = nil;
    [_leftImageView setNeedsDisplay];
    [_rightImageView setNeedsDisplay];
}

-(UIImage*) colourImage {
    return [_depthSensor getColourImage];
}

-(UIImage*) sensorImage {
    UIImage* image = [_depthSensor getSensorImage];

    if (image == nil) return nil;
    
    //calculate size of rectangle
    CGFloat height = _synestheatreMain.config.depthDataWindowHeight * image.size.height;
    CGFloat width = _synestheatreMain.config.depthDataWindowWidth * image.size.width;
    CGFloat y = (image.size.height - height) / 2;
    CGFloat x = (image.size.width - width) / 2;
    
    // begin a graphics context of sufficient size
    UIGraphicsBeginImageContext(image.size);
    
    // draw original image into the context
    [image drawAtPoint:CGPointZero];
    
    // get the context for CoreGraphics
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // draw rectangle
    [[UIColor whiteColor] setStroke];
    CGContextSetLineWidth(ctx, 1);
    CGContextStrokeRect(ctx, CGRectMake(x, y, width, height));
    
    // make image out of bitmap context
    UIImage* uIImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // free the context
    UIGraphicsEndImageContext();
    
    return uIImage;
}

-(UIImage*) debugImage {
    NSArray* volumes = _synestheatreMain.volumes;
    int _cols = _synestheatreMain.config.cols;
    int _rows = _synestheatreMain.config.rows;
    int _colours = _synestheatreMain.config.colours;
    
    int multipler = 10;
    int m_cols = _cols * multipler;
    int m_rows = _rows * multipler;
    
    unsigned char pixelData[m_cols * m_rows * 4];
    
    for(int row = 0; row < m_rows; ++row) {
        for(int col = 0; col < m_cols; ++col) {
            
            int actualRow = floor(row / multipler);
            int actualCol = floor(col / multipler);
            
            float vol = 0;
            int colourOfPixel = -1;
            
            for(int colour = 0; colour < _colours; ++colour) {
                
                int index = colour + (actualCol * _colours) + (actualRow * _cols * _colours);
                
                NSNumber* volume = volumes[index];
                float floatVol = [volume floatValue];
                
                if (floatVol > vol) {
                    vol = floatVol;
                    colourOfPixel = colour;
                }
            }
            
            int pixelIndex = ((row * m_cols) + col) * 4;
            //NSLog(@"%d", colourOfPixel);
            switch(colourOfPixel) {
                case -1:
                    pixelData[pixelIndex] = 0;
                    pixelData[pixelIndex + 1] = 0;
                    pixelData[pixelIndex + 2] = 0;
                    pixelData[pixelIndex + 3] = 255;
                    break;
                case 0: //red
                    pixelData[pixelIndex] = 0;
                    pixelData[pixelIndex + 1] = 0;
                    pixelData[pixelIndex + 2] = 255 * vol;
                    pixelData[pixelIndex + 3] = 255;
                    break;
                case 1: //yellow
                    pixelData[pixelIndex] = 0;
                    pixelData[pixelIndex + 1] = 255 * vol;
                    pixelData[pixelIndex + 2] = 255 * vol;
                    pixelData[pixelIndex + 3] = 255;
                    break;
                case 2: // green
                    pixelData[pixelIndex] = 0;
                    pixelData[pixelIndex + 1] = 255 * vol;
                    pixelData[pixelIndex + 2] = 0;
                    pixelData[pixelIndex + 3] = 255;
                    break;
                case 3: //blue
                    pixelData[pixelIndex] = 255 * vol;
                    pixelData[pixelIndex + 1] = 0;
                    pixelData[pixelIndex + 2] = 0;
                    pixelData[pixelIndex + 3] = 255;
                    break;
                case 4: // black
                    pixelData[pixelIndex] = 0;
                    pixelData[pixelIndex + 1] = 0;
                    pixelData[pixelIndex + 2] = 0;
                    pixelData[pixelIndex + 3] = 255;
                    break;
                case 5: //grey
                    pixelData[pixelIndex] = 127 *vol;
                    pixelData[pixelIndex + 1] = 127 *vol;
                    pixelData[pixelIndex + 2] = 127 *vol;
                    pixelData[pixelIndex + 3] = 255;
                    break;
                case 6: //white
                    pixelData[pixelIndex] = 255 * vol;
                    pixelData[pixelIndex + 1] = 255 * vol;
                    pixelData[pixelIndex + 2] = 255 * vol;
                    pixelData[pixelIndex + 3] = 255;
                    break;
                case 7:
                    pixelData[pixelIndex] = 127 * vol;
                    pixelData[pixelIndex + 1] = 127 * vol;
                    pixelData[pixelIndex + 2] = 127 * vol;
                    pixelData[pixelIndex + 3] = 255;
                    break;
                case 8:
                    pixelData[pixelIndex] = 0;
                    pixelData[pixelIndex + 1] = 0;
                    pixelData[pixelIndex + 2] = 0;
                    pixelData[pixelIndex + 3] = 255;
                    break;

            }
            
            
        }
    }
    
    void *baseAddress = &pixelData;
    
    size_t bytesPerRow = m_cols * 4;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress, m_cols, m_rows, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage* uiImage = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);

    UIGraphicsEndImageContext();
    return uiImage;
}


@end
