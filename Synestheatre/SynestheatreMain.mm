//
//  SynestheatreMain.m
//  Synestheatre
//
//  Created by James on 11/08/2016.
//  Copyright © 2016 James. All rights reserved.
//

#import "SynestheatreMain.h"
#import "ConfigurationManager.h"
#import "ColourSpaceUtilities.h"
#include <math.h>

#include <math.h>
#define PIV2 (M_PI+M_PI)
float difangrad(float x, float y)
{
    double arg = fmod(y-x, PIV2);
    if (arg < 0 )  arg  = arg + PIV2;
    if (arg > M_PI) arg  = arg - PIV2;
    
    return fabs(arg);
}

#define LANDSCAPED_INDEX _landscapeMode ? (row * _config.cols) + col : ((_config.cols - 1 - col) * _config.rows) + row

#define MAX3(x,y,z) ( MAX(x,MAX(y,z)) )
#define MIN3(x,y,z) ( MIN(x,MIN(y,z)) )
@interface SynestheatreMain () {
    
    float *_depthData;
    Colour *_colourData;
    
    AudioController *_audioController;
    id<DepthSensor> _depthSensor;
    ConfigurationManager *_ConfigurationManager;
    
    NSTimer* _heartbeat;
    NSTimer* _sensorConnectedDetection;
    
    bool _changedHeartbeat;
    bool _active;
    bool _pause;
    bool _hasDepthData;
    bool _hasColourData;
    
    UIImage* _depthImage;
    UIImage* _debugImage;
}


@end


@implementation SynestheatreMain

- (instancetype)initWithAudioController:(AudioController*)ac depthSensor:(id<DepthSensor>)ds {
    if ( !(self = [super init])) return nil;
    
    _audioController = ac;
    _depthSensor = ds;
    _config = [[Configuration alloc] init];
    
    _pause = true;
    _changedHeartbeat = false;
    _hasDepthData = false;
    
    // Initialize and load a configuration
    _ConfigurationManager = [ConfigurationManager sharedInstance];
    
    if (_ConfigurationManager == nil ) {
        NSLog(@"Could not find any configs");
        return nil;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sensorChanged:)
                                                 name:@"SensorChanged"
                                               object:nil];
        
    return self;
}



- (void)dealloc {
    
    free(_depthData);
    free(_colourData);
}

-(void) sensorChanged:(NSNotification *) notification {
    [self clearVolumes];
}


- (void)start {
    
    if ([self reloadConfig]) {
        [self restartHeartbeat];
        
        [_depthSensor startDepthSensor];
        
        // Do periodic check for sensor conection
        _sensorConnectedDetection = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                                     target:self
                                                                   selector:@selector(checkIfSensorIsConnected:)
                                                                   userInfo:nil
                                                                    repeats:YES];
    } else {
        [self stop];
        
    }
    
}

- (bool)isRunning {
    return _pause == false;
}


- (bool)reloadConfig {
    
    NSLog(@"Reload config - %@", _ConfigurationManager.currentConfig.name);
    
    _pause = true;
    [_audioController stop];

    //NSError* error = nil;
    
    _config = _ConfigurationManager.currentConfig;

    
    
    free(_depthData);
    free(_colourData);
    
    _depthData = (float*)malloc(sizeof(float) * _config.rows * _config.cols);
    _colourData = (Colour*)malloc(sizeof(Colour) * _config.rows * _config.cols);
    
    [self setDepthSensorValues];
    
    [_audioController stop];
    
    bool loadedAudio = [_audioController startWithURLs:_config.filenames andReverb:_config.reverbConfiguration];
    
    if (!loadedAudio) {
        [Toast makeToast:@"Memory error when loading sounds."];
        return false;
    }
    
    if ([[[NSUserDefaults standardUserDefaults]stringForKey:@"voice_feedback"] integerValue] > 0) {
        NSString* utterance = [NSString stringWithFormat:@"Loaded %@ with %@",
                               _ConfigurationManager.currentConfig.name,
                               [_depthSensor getSensorType]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: @"SaySomething" object: utterance];
    }
    _pause = false;
    
    return true;
    
}

-(void)setDepthSensorValues {
    
    
    if (_landscapeMode) {
        [_depthSensor setViewWindowWithRows:_config.rows cols:_config.cols heightScale:_config.depthDataWindowHeight widthScale:_config.depthDataWindowWidth];
    } else {
        [_depthSensor setViewWindowWithRows:_config.cols cols:_config.rows heightScale:_config.depthDataWindowWidth widthScale:_config.depthDataWindowHeight];
    }
}

-(void)checkIfSensorIsConnected:(NSTimer *)timer {

    if (![_depthSensor isSensorConnected]) {
        
        if ([[[NSUserDefaults standardUserDefaults]stringForKey:@"voice_feedback"] integerValue] > 0) {
            NSString* utterance = [NSString stringWithFormat:@"Sensor error: %@ ",
                                   [_depthSensor sensorDisconnectionReason]];
            
            [[NSNotificationCenter defaultCenter] postNotificationName: @"SaySomething" object: utterance];
            
        }
        
    }
}


- (void)stop {
    _pause = true;
    
    if (_heartbeat != nil) {
        [_heartbeat invalidate];
        _heartbeat = nil;
    }
    
    if (_sensorConnectedDetection != nil) {
        [_sensorConnectedDetection invalidate];
        _sensorConnectedDetection = nil;
    }
    
    [_audioController stop];
    [_depthSensor stopDepthSensor];
}


- (void)restartHeartbeat {
    
    if (_heartbeat != nil) {
        [_heartbeat invalidate];
        _heartbeat = nil;
    }
    
    if (_pause) return;
    
    _heartbeat = [NSTimer scheduledTimerWithTimeInterval:_config.heartbeatInterval
                                                  target:self
                                                selector:@selector(onHeartbeat:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)setHeartbeatTempo:(float)heartbeatInterval {
    
    _config.heartbeatInterval = MIN(MAX(heartbeatInterval,SYN_HB_MIN),SYN_HB_MAX);
    _changedHeartbeat = true;
    NSLog(@"Heartbeat: %f -> %f",heartbeatInterval, _config.heartbeatInterval);
}

- (void)setDepthWindow:(float)height width:(float)width {
    _config.depthDataWindowHeight = MIN(MAX(height,SYN_DEPTH_WIN_MIN),SYN_DEPTH_WIN_MAX);
    _config.depthDataWindowWidth = MIN(MAX(width,SYN_DEPTH_WIN_MIN),SYN_DEPTH_WIN_MAX);
    NSLog(@"DWH: %f",_config.depthDataWindowHeight);
    NSLog(@"DWw: %f",_config.depthDataWindowWidth);
    
    [self setDepthSensorValues];
}

- (void)setDepthRange:(float)depthInMm {
    _config.depthRange = MIN(MAX(depthInMm,SYN_DEPTH_MM_MIN),SYN_DEPTH_MM_MAX);
    NSLog(@"Depth: %f",_config.depthRange);
}

- (void)setDepthDistance:(float)distanceInMm {
    _config.depthDistance = MIN(MAX(distanceInMm, SYN_CLOSEST_DEPTH_MM_MIN), SYN_CLOSEST_DEPTH_MM_MAX);
    NSLog(@"Depth distance: %f",_config.depthDistance);
}

- (void)setHorizontalTimingOffset:(float)horizontalTimingOffset {
    _config.horizontalTimingOffset = MIN(MAX(horizontalTimingOffset, SYN_TIMING_MIN), SYN_TIMING_MAX);
    NSLog(@"HT: %f",_config.horizontalTimingOffset);
}
- (void)setVerticalTimingOffset:(float)verticalTimingOffset {
    _config.verticalTimingOffset = MIN(MAX(verticalTimingOffset, SYN_TIMING_MIN), SYN_TIMING_MAX);
    NSLog(@"VT: %f",_config.verticalTimingOffset);
}

- (void)setHorizontalFocus:(float)horizontalFocus {
    _config.horizontalFocus = MIN(MAX(horizontalFocus, SYN_FOCUS_MIN), SYN_FOCUS_MAX);
    NSLog(@"HF: %f",_config.horizontalFocus);
}
- (void)setVerticalFocus:(float)verticalFocus {
    _config.verticalFocus = MIN(MAX(verticalFocus, SYN_FOCUS_MIN), SYN_FOCUS_MAX);
    NSLog(@"VF: %f",_config.verticalFocus);
}

- (void)setBwLevel:(float)lightness {
    
    ColourConfiguration config = _config.colourConfiguration;
    config.bw_level = MIN(MAX(lightness,0),1);
    _config.colourConfiguration = config;
    NSLog(@"B&W: %f",config.bw_level);
}


-(bool)positionIsInFocusForRow:(int)row andCol:(int)col {
    
    
    
    float rowPosition = _config.rows > 1 ? ((float)row / (float)(_config.rows - 1)) : 0;
    float colPosition = _config.cols > 1 ? ((float)col / (float)(_config.cols - 1)) : 0;
    
    bool inRowFocus = MIN(rowPosition, 1 - rowPosition)*2 >= _config.verticalFocus;
    bool inColFocus = MIN(colPosition, 1 - colPosition)*2 >= _config.horizontalFocus;
    
    return inRowFocus && inColFocus;
}

- (void)depthDataUpdated {
    if (_pause) return;
    
    _hasDepthData = [_depthSensor getDepthInMillimeters:_depthData];
    
    _hasColourData = [_depthSensor getColours:_colourData];
    
    if (_hasDepthData || _hasColourData) {
        [self updateVolumes];
    } else {
        [self clearVolumes];
    }
}

-(void)onHeartbeat:(NSTimer *)timer {
    
    if (_pause) return;
    
    [self updateDelays];
    
    if (_changedHeartbeat) {
        _changedHeartbeat = false;
        [self restartHeartbeat];
    }
}

-(void)updateDelays {

    double currentRowOffset = 0.0f;
    double currentColOffset = 0.0f;
    
    double rowSpreadInterval = (_config.heartbeatInterval / _config.rows) * _config.verticalTimingOffset;
    double colSpreadInterval = (_config.heartbeatInterval / _config.cols) * _config.horizontalTimingOffset;
    
    NSMutableArray* delays = [[NSMutableArray alloc] init];
    
    float minDepth = _config.depthDistance;
    float maxDepth = _config.depthRange + _config.depthDistance;
    
    if (_config.depthMode) {
        
        for(int row = 0; row < _config.rows; ++row) {
            for(int col = 0; col < _config.cols; ++col) {
                
                int depthDataIndex = (row * _config.cols) + col;
                
                for(int colour = 0; colour < _config.colours; ++ colour) {
                    float colourDelay = _config.colourConfiguration.colour_timings[colour];
                    float depth = MAX(MIN(maxDepth, _depthData[depthDataIndex]),minDepth);
                    float depthRatio = 1 - ((depth - minDepth) / _config.depthRange);
                    float depthDelay = _config.heartbeatInterval * depthRatio;
                    float delay = currentColOffset + currentRowOffset + depthDelay + colourDelay;
                    [delays addObject:[[NSNumber alloc] initWithFloat:delay]];
                }
                
                currentColOffset += colSpreadInterval;
            }
            
            currentRowOffset += rowSpreadInterval;
            currentColOffset = 0.0f;
        }
    } else {
        for(int row = 0; row < _config.rows; ++row) {
            for(int col = 0; col < _config.cols; ++col) {
                for(int colour = 0; colour < _config.colours; ++ colour) {
                    float colourDelay = _config.colourConfiguration.colour_timings[colour];
                    float delay = currentColOffset + currentRowOffset + colourDelay;
                    [delays addObject:[[NSNumber alloc] initWithFloat:delay]];
                    
                }
                
                currentColOffset += colSpreadInterval;
            }
            
            currentRowOffset += rowSpreadInterval;
            currentColOffset = 0.0f;
        }
    }
    
    
    [_audioController playAtDelays:delays];
}

-(void)clearVolumes {
    NSMutableArray* volumes = [[NSMutableArray alloc] init];
    
    for(int row = 0; row < _config.rows; ++row) {
        for(int col = 0; col < _config.cols; ++col) {
            for(int colour = 0; colour < _config.colours; ++colour) {
                [volumes addObject:[[ NSNumber alloc] initWithFloat:0]];
            }
        }
    }
    [_audioController setNewVolumes:volumes];
}

-(void)updateVolumes {
    NSMutableArray* volumes = [[NSMutableArray alloc] init];

    float minDepth = _config.depthDistance;
    float maxDepth = _config.depthRange + _config.depthDistance;
    float maxDepthVol = _config.maxDepthVolume;
    bool exponentialLoudness = _config.exponentialLoudness;
    
    if([_config.volSource isEqualToString:@"depth"]){
        for(int row = 0; row < _config.rows; ++row) {
            for(int col = 0; col < _config.cols; ++col) {
                
                int index = LANDSCAPED_INDEX;
                
                Colour thisColour = _hasColourData ? _colourData[index] : ColourBlack;
                
                float* c_volumes = (float*)calloc(_config.colours,sizeof(float));
                [self getVolumesForPixel:thisColour volumes:c_volumes];
                
                bool inFocus = [self positionIsInFocusForRow:row andCol:col];
                for(int colour = 0; colour < _config.colours; ++colour) {
                    
                    float vol = c_volumes[colour];
                
                    if(!inFocus) {
                        vol = 0;
                    } else if (_hasDepthData && vol > 0) {
                        
                        float depth = MAX(MIN(maxDepth, _depthData[index]),minDepth);
                 
                        
                        if (depth < 0 || isnan(depth)) {
                            vol *= _config.defaultDepth;
                        } else {
                            float depthRatio = MAX(1 - ((depth - minDepth) / _config.depthRange), maxDepthVol);
                            vol *= depthRatio;
                        }
                        
                    } else if (DEBUG == 1) {
                        vol *= _config.defaultDepth;
                        //(float)arc4random() / UINT32_MAX;
                    }
                    
                    [volumes addObject:[[ NSNumber alloc] initWithFloat:exponentialLoudness ? vol * vol : vol]];
                }
                free(c_volumes);
            }
        }
    } else if ([_config.volSource isEqualToString:@"luminance"]) {
        
        for(int row = 0; row < _config.rows; ++row) {
            for(int col = 0; col < _config.cols; ++col) {
                
                int index = _landscapeMode ? (row * _config.cols) + col : ((_config.cols - 1 - col) * _config.rows) + row;
                
                Colour thisColour = _hasColourData ? _colourData[index] : ColourBlack;
                
                float* c_volumes = (float*)calloc(_config.colours,sizeof(float));
                [self getVolumesForPixel:thisColour volumes:c_volumes];
                
                for(int colour = 0; colour < _config.colours; ++colour) {
                
                    float vol = c_volumes[colour];
                    
                    if (vol > 0) {
                
                        int maxComponent = MAX3(thisColour.r,thisColour.g,thisColour.b);
                        int minComponent = MIN3(thisColour.r,thisColour.g,thisColour.b);
                        
                        int luminance = (maxComponent + minComponent) / 2;
                        
                        bool inFocus = [self positionIsInFocusForRow:row andCol:col];
                        
                        
                        if(inFocus) {
                            vol *= (float)luminance / 255.0f;
                        }
                    }
                    
                    
                    [volumes addObject:[[ NSNumber alloc] initWithFloat:exponentialLoudness ? vol * vol : vol]];
                }
                free(c_volumes);
            }
        }
    } else if ([_config.volSource isEqualToString:@"saturation"]) {
        
        for(int row = 0; row < _config.rows; ++row) {
            for(int col = 0; col < _config.cols; ++col) {
                
                int index = LANDSCAPED_INDEX;
                
                Colour thisColour = _hasColourData ? _colourData[index] : ColourBlack;
                
                float* c_volumes = (float*)calloc(_config.colours,sizeof(float));
                [self getVolumesForPixel:thisColour volumes:c_volumes];
                
                for(int colour = 0; colour < _config.colours; ++colour) {
                    
                    float vol = c_volumes[colour];
                    if (vol > 0) {
                
                        
                        float maxComponent = MAX3(thisColour.r,thisColour.g,thisColour.b);
                        float minComponent = MIN3(thisColour.r,thisColour.g,thisColour.b);
                        float delta = maxComponent - minComponent;
                        float saturation = maxComponent == 0 ? 0 : delta / maxComponent;
                        
                        bool inFocus = [self positionIsInFocusForRow:row andCol:col];
                        
           
                        if(inFocus) {
                            vol *= saturation;
                        }
                    }
                    
                    [volumes addObject:[[ NSNumber alloc] initWithFloat:exponentialLoudness ? vol * vol : vol]];
                }
                free(c_volumes);
                
                
            }
        }
    } else if ([_config.volSource isEqualToString:@"value"]) {
        for(int row = 0; row < _config.rows; ++row) {
            for(int col = 0; col < _config.cols; ++col) {
                
                int index = LANDSCAPED_INDEX;
                
                Colour thisColour = _hasColourData ? _colourData[index] : ColourBlack;
                
                float* c_volumes = (float*)calloc(_config.colours,sizeof(float));
                [self getVolumesForPixel:thisColour volumes:c_volumes];
                
                for(int colour = 0; colour < _config.colours; ++colour) {
                    
                    float vol = c_volumes[colour];
                    
                    if (vol > 0) {
                        
                        float maxComponent = MAX3(thisColour.r,thisColour.g,thisColour.b);
               
                        bool inFocus = [self positionIsInFocusForRow:row andCol:col];
               
                        if(inFocus) {
                            vol *= (float)maxComponent / 255.0f;
                        }
                    }
                    
                    [volumes addObject:[[ NSNumber alloc] initWithFloat:exponentialLoudness ? vol * vol : vol]];
                }
                free(c_volumes);
            }
        }
    } else {
        // All volumes are 1
        for(int row = 0; row < _config.rows; ++row) {
            for(int col = 0; col < _config.cols; ++col) {
                
                int index = LANDSCAPED_INDEX;
                
                Colour thisColour = _hasColourData ? _colourData[index] : ColourBlack;
                
                float* c_volumes = (float*)calloc(_config.colours,sizeof(float));
                [self getVolumesForPixel:thisColour volumes:c_volumes];
                
                bool inFocus = [self positionIsInFocusForRow:row andCol:col];
                for(int colour = 0; colour < _config.colours; ++colour) {
                    
                    float vol = inFocus ? c_volumes[colour] : 0;
                    
                    [volumes addObject:[[ NSNumber alloc] initWithFloat:exponentialLoudness ? vol * vol : vol]];
                }
                free(c_volumes);
            }
        }
    }
    
    _volumes = volumes;

    [_audioController setNewVolumes:volumes];
}



- (void) getVolumesForPixel:(Colour) colour volumes:(float*)volumes {
 
    
    float H;
    float S;
    float L;
    
    RGB2HSL((float) colour.r, (float) colour.g, (float) colour.b, &H, &S, &L);
    
    if (_config.colourConfiguration.bw_mode) {
        int colourIndex = (L > _config.colourConfiguration.bw_level) ? 1 : 0;
        volumes[colourIndex] = 1;
        return;
    } else if (_config.colourConfiguration.boundary_mode) {
        
        // Boundary mode has hard cutoffs based on the specified levels
        int colourIndex = 0;
        
        if (S > _config.colourConfiguration.saturation_threshold) {
            colourIndex = 0;
            for(int i = 0; i <_config.colourConfiguration.n_hue_thresholds; i += 1) {
                if (H < _config.colourConfiguration.hue_thresholds[i]) {
                    colourIndex = i;
                    break;
                }
            }
            
            
        } else {
            colourIndex = _config.colourConfiguration.n_hue_thresholds + _config.colourConfiguration.n_lightness_thresholds;
            
            for(int i = 0; i <_config.colourConfiguration.n_lightness_thresholds; i += 1) {
                if (L < _config.colourConfiguration.lightness_thresholds[i]) {
                    colourIndex = i + _config.colourConfiguration.n_hue_thresholds;
                    break;
                }
            }
        }
        
        volumes[colourIndex] = 1;
        return;
        
    } else {
        // Non boundary mode, treats each level as a
        if (S > _config.colourConfiguration.saturation_threshold) {
            
            int firstIndex = 0, secondIndex;
            
            for(int i = 0; i <_config.colourConfiguration.n_hue_thresholds; i += 1) {
                if (H < _config.colourConfiguration.hue_thresholds[i]) {
                    firstIndex = i;
                    break;
                }
            }
            
            secondIndex = firstIndex == 0 ? _config.colourConfiguration.n_hue_thresholds - 1 : firstIndex - 1;
            
            float distTo1 = difangrad(_config.colourConfiguration.hue_thresholds[firstIndex] * PIV2, H * PIV2);
            float distTo2 = difangrad(_config.colourConfiguration.hue_thresholds[secondIndex] * PIV2, H * PIV2);
            
            float vol1 = distTo2 / (distTo1 + distTo2);
            float vol2 = 1 - vol1;
            
            volumes[firstIndex] = vol1;
            volumes[secondIndex]  = vol2;
            
            return;
            
        } else {
            
            int lightestGreyScaleIndex = _config.colourConfiguration.n_hue_thresholds + _config.colourConfiguration.n_lightness_thresholds;
            int firstIndex = lightestGreyScaleIndex;
            
            for(int i = 0; i <_config.colourConfiguration.n_lightness_thresholds; i += 1) {
                if (L < _config.colourConfiguration.lightness_thresholds[i]) {
                    firstIndex = i;
                    break;
                }
            }
            
            if (firstIndex == 0) {
                float distTo1 = abs(L - _config.colourConfiguration.lightness_thresholds[firstIndex]);
                float distTo2 = abs(L);
                float vol1 = distTo2 / (distTo1 + distTo2);
                float vol2 = 1 - vol1;
                
                volumes[_config.colourConfiguration.n_hue_thresholds + 1] = vol1;
                volumes[_config.colourConfiguration.n_hue_thresholds]  = vol2;
            } else if (firstIndex == lightestGreyScaleIndex) {
                volumes[lightestGreyScaleIndex] = 1;
            } else {
                int secondIndex = firstIndex - 1;
                float distTo1 = abs(L - _config.colourConfiguration.lightness_thresholds[firstIndex]);
                float distTo2 = abs(L - _config.colourConfiguration.lightness_thresholds[secondIndex]);
                float vol1 = distTo2 / (distTo1 + distTo2);
                float vol2 = 1 - vol1;
                volumes[_config.colourConfiguration.n_hue_thresholds + firstIndex + 1] = vol1;
                volumes[_config.colourConfiguration.n_hue_thresholds + secondIndex + 1]  = vol2;
            }
            
            return;
        }
        
    }
    
}

- (UIImage*)colourDebugImage {
    
    return nil;
    
    /*
    if (!_hasColourData) return nil;

    UIImage *newImage = nil;
    int width = _config.cols;
    int height = _config.rows;
    int nrOfColorComponents = 4; //RGBA
    int bitsPerColorComponent = 8;
    int rawImageDataLength = width * height * nrOfColorComponents;
    BOOL interpolateAndSmoothPixels = NO;
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;//kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGDataProviderRef dataProviderRef;
    CGColorSpaceRef colorSpaceRef;
    CGImageRef imageRef;
    
    @try
    {
        UInt32 *rawImageDataBuffer = _colourData;
        
        dataProviderRef = CGDataProviderCreateWithData(NULL, rawImageDataBuffer, rawImageDataLength, nil);
        colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        imageRef = CGImageCreate(width, height, bitsPerColorComponent, bitsPerColorComponent * nrOfColorComponents, width * nrOfColorComponents, colorSpaceRef, bitmapInfo, dataProviderRef, NULL, interpolateAndSmoothPixels, renderingIntent);
        newImage = [[UIImage alloc] initWithCGImage:imageRef scale:1 orientation:UIImageOrientationUp];
    }
    @finally
    {
        CGDataProviderRelease(dataProviderRef);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(imageRef);
    }
    
    return newImage;*/
}


@end
