//
//  PreviewView.m
//  Synestheatre
//
//  Created by James on 27/09/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import "PreviewView.h"
#import "SynestheatreMain.h"

@interface DepthArrayLayerDelegate : NSObject <CALayerDelegate> {
    SynestheatreMain* _synestheatreMain;
}
- (void)setSynestheatre:(SynestheatreMain*)synestheatreMain;

@end

@interface PreviewView () {
    CALayer*  _depthArrayLayer;
    DepthArrayLayerDelegate* _depthArrayDelegate;
}

@end


@implementation PreviewView

+ (Class)layerClass { return [AVCaptureVideoPreviewLayer class]; }

- (instancetype)initWithCoder:(NSCoder *)coder
{
    NSLog(@"Adding sub layer");
    self = [super initWithCoder:coder];
    if (self) {
        _depthArrayDelegate = [[DepthArrayLayerDelegate alloc] init];
        _depthArrayLayer = [[CALayer alloc] init];
        _depthArrayLayer.delegate = _depthArrayDelegate;
        _depthArrayLayer.backgroundColor = [UIColor clearColor].CGColor;
        _depthArrayLayer.frame = CGRectMake(10, 24, 100, 100);
        _depthArrayLayer.shadowOffset = CGSizeMake(0, 3);
        _depthArrayLayer.shadowRadius = 4.0;
        _depthArrayLayer.shadowColor = [UIColor blackColor].CGColor;
        _depthArrayLayer.shadowOpacity = 0.8;
        _depthArrayLayer.cornerRadius = 2.0;
        _depthArrayLayer.borderColor = [UIColor blackColor].CGColor;
        _depthArrayLayer.borderWidth = 1.0;
        _depthArrayLayer.masksToBounds = YES;
        [self.layer addSublayer:_depthArrayLayer];
        [_depthArrayLayer setNeedsDisplay];
        
    }
    return self;
}

- (void)update {
    [_depthArrayLayer setNeedsDisplay];
}

- (AVCaptureVideoPreviewLayer*)videoPreviewLayer {
    return (AVCaptureVideoPreviewLayer*)self.layer;
}

- (void)setSession:(AVCaptureSession*)session {
    self.videoPreviewLayer.session = session;
    self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

- (void)setSynestheatre:(SynestheatreMain*)synestheatreMain {
    [_depthArrayDelegate setSynestheatre:synestheatreMain];
}

@end



@implementation DepthArrayLayerDelegate

- (void)setSynestheatre:(SynestheatreMain*)synestheatreMain {
    _synestheatreMain = synestheatreMain;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context {
    
    CGRect bounds = layer.bounds;
    
    CGFloat alpha = 0.5;
    CGColorRef bgColor = [UIColor colorWithWhite:0 alpha:alpha].CGColor;
    CGContextSetFillColorWithColor(context, bgColor);
    CGContextFillRect(context, layer.bounds);
    
    
    NSArray* volumes = _synestheatreMain.volumes;
    int _cols = _synestheatreMain.config.cols;
    int _rows = _synestheatreMain.config.rows;
    int _colours = _synestheatreMain.config.colours;
    
    CGFloat unitWidth = bounds.size.width / _cols;
    CGFloat unitHeight = bounds.size.height / _rows;
    
    
    for(int row = 0; row < _rows; ++row) {
        for(int col = 0; col < _cols; ++col) {
                        
            float vol = 0;
            int colourOfPixel = -1;
            
            // decide which colour the pixel is
            for(int colour = 0; colour < _colours; ++colour) {
                
                int index = colour + (col * _colours) + (row * _cols * _colours);
                
                NSNumber* volume = volumes[index];
                float floatVol = [volume floatValue];
                
                if (floatVol > vol) {
                    vol = floatVol;
                    colourOfPixel = colour;
                }
            }
            
            //draw rect
            CGFloat x = col * unitWidth;
            CGFloat y = row * unitHeight;
            CGRect drawRect = CGRectMake(x, y, unitWidth, unitHeight);
            
            CGColorRef color = [UIColor colorWithWhite:vol alpha:alpha].CGColor;
            CGContextSetFillColorWithColor(context, color);
            CGContextFillRect(context, drawRect);
            
        }
    }
    
    
    
}
@end
