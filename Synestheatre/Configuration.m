//
//  Configuration.m
//  Synestheatre
//
//  Created by James on 10/08/2018.
//  Copyright © 2018 James. All rights reserved.
//

#import "Configuration.h"
#import "SynestheatreMain.h"
#import "HRTFPreProcessor.h"
#import "PitchPreProcessor.h"

#define SYNTCONFIGERROR(errorMessage) *error = [NSError errorWithDomain:@"synestheatre" \
code:0 \
userInfo:@{ NSLocalizedDescriptionKey: errorMessage}]; \
return false;

#define ASSERTINRANGE(x,max,min,msg) if ((x) < (min) || (x) > (max)) { \
[error appendString:msg];\
}


@implementation Configuration

-(instancetype)init {
    if ( !(self = [super init])) return nil;
    // Set defaults
    _horizontalFocus = 0.0f;
    _verticalFocus = 0.0f;
    _horizontalTimingOffset = 0.0f;
    _verticalTimingOffset = 0.0f;
    _depthDataWindowWidth = 1.0f;
    _depthDataWindowHeight = 1.0f;
    _heartbeatInterval = 1.0f;
    _depthRange = 2500;
    _depthDistance = 0;
    _depthMode = true;
    _cols = 0;
    _rows = 0;
    _colours = 0;
    _defaultDepth = 0.0;
    _volSource = @"depth";
    _orientation = @"landscape";
    _colourTimings = @[];
    _exponentialLoudness = false;
    _maxDepthVolume = 0.0f;
    
    // this is the setup for one colour
    _colourConfiguration.boundary_mode = false;
    _colourConfiguration.saturation_threshold = 1;
    _colourConfiguration.n_hue_thresholds = 0;
    _colourConfiguration.n_lightness_thresholds = 0;
    
    [self loadDefaults];
    return self;
}

-(void)loadDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    _horizontalFocus = [defaults floatForKey:@"horizontal_focus"];
    _verticalFocus = [defaults floatForKey:@"vertical_focus"];
    _horizontalTimingOffset = [defaults floatForKey:@"horizontal_offset"];
    _verticalTimingOffset = [defaults floatForKey:@"vertical_offset"];
    _depthDataWindowWidth = [defaults floatForKey:@"window_width"];
    _depthDataWindowHeight = [defaults floatForKey:@"window_height"];
    _heartbeatInterval = [defaults floatForKey:@"heartbeat_interval"];
    _depthRange = [defaults floatForKey:@"depth_range"];
    _depthDistance = [defaults floatForKey:@"depth_distance"];
    _depthMode = [defaults boolForKey:@"depth_mode"];
    _panGesture = [defaults stringForKey:@"pan_gesture"];
    _twoFingerGesture = [defaults stringForKey:@"two_finger_gesture"];
    _pinchGesture = [defaults stringForKey:@"pinch_gesture"];
    _volSource = [defaults stringForKey:@"vol_source"];
    _defaultDepth = [defaults floatForKey:@"default_depth"];
    _exponentialLoudness = [defaults floatForKey:@"exponential_loudness"];
    _orientation = [defaults stringForKey:@"orientation"];
    _maxDepthVolume = [defaults floatForKey:@"max_depth_vol"];

    
    // this is the setup for one colour
    _colourConfiguration.boundary_mode = false;
    _colourConfiguration.saturation_threshold = 1;
    _colourConfiguration.n_hue_thresholds = 0;
    _colourConfiguration.n_lightness_thresholds = 0;
    
    _reverbConfiguration.wetDryMix = [defaults floatForKey:@"wet-dry"];
    _reverbConfiguration.presetIndex = [defaults floatForKey:@"reverb-preset"];
    
    for(int i = 0; i < MAX_COLOURS; i += 1) {
        _colourConfiguration.colour_timings[i] = 0;
    }
}

- (bool)loadSyntFile:(NSString*)syntFilePath error:(NSError**)error {
    
    // Get JSON Dictionary of selected synt file
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:syntFilePath];
    if (inputStream == nil) { SYNTCONFIGERROR(@"Couldn't get file stream."); }
    
    [inputStream open];
    id jsonObject = [NSJSONSerialization JSONObjectWithStream: inputStream
                                                      options:kNilOptions
                                                        error:error];
    [inputStream close];
    if (*error) { SYNTCONFIGERROR(@"Error parsing synt file - check for valid JSON syntax."); }
    
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        SYNTCONFIGERROR(@"Config file must be dictionary at base level.");
    }
    
    // Take all non optional entries
    _syntJsonDic = (NSDictionary *)jsonObject;
    NSString* rowString = _syntJsonDic[@"rows"];
    NSString* colString = _syntJsonDic[@"cols"];
    NSString* nameString = _syntJsonDic[@"name"];
    
    bool validFormat = rowString != nil && colString != nil && nameString != nil;
    
    if (!validFormat) { SYNTCONFIGERROR(@"Config file does not have all row/col/name entries.");}
    
    // integerValue evaluates to 0 if not a valid integer
    _rows = (int)[rowString integerValue];
    _cols = (int)[colString integerValue];
    _name = nameString;
    
    // Check non optional fields are valid
    validFormat = _rows > 0 && _cols > 0 && [_name length] > 0;
    if (!validFormat) { SYNTCONFIGERROR(@"Config file does not have valid row/col/name entries.");}
    
    // Check sound files directory exists
    
    // Get Documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* soundFilesDirectory = [documentsDirectory stringByAppendingPathComponent:nameString];
    bool isDir;
    bool exists = [[[NSFileManager alloc] init] fileExistsAtPath:soundFilesDirectory isDirectory:&isDir];
    if (!exists || !isDir) {SYNTCONFIGERROR(@"Name parameter does not point to valid dictionary.");}
    

    // Set number of colours: synt files that dont have colours, always just have 1 colour
    NSString* colourString = _syntJsonDic[@"colours"];
    _colours = colourString != nil ? (int)[colourString integerValue] : 1;
    if (_colours == 0) _colours = 1; // prevent user from incorrectly setting 0 colours.
    
    // Do preprocessing if necessary
    NSString* hrtf_process = _syntJsonDic[@"hrtf"];
    NSString* pitch_process = _syntJsonDic[@"pitch"];
    
    
    // First process pitches if necessary (prototype sound file will be 0.wav)
    // This will populate sounds 1 to n_rows - .wav for hrtf to be used.
    if (pitch_process != nil && [pitch_process integerValue] == 1) {
        NSArray* pitches = _syntJsonDic[@"pitches"];
        
        // check number of pitches matcht the number of rows
        if ([pitches count] != _rows) {
            // throw error
            SYNTCONFIGERROR(@"Pitches don't match rows.");
        }
        
        for(int colour = 0; colour < _colours; ++colour) {
            NSString* colourElement = _colours == 1 ? @"" : [NSString stringWithFormat:@"/%d", colour + 1];
            NSString* outputDirectory = [soundFilesDirectory stringByAppendingFormat:@"%@/hrtf/", colourElement];
            
            NSURL* url = [NSURL fileURLWithPath:[soundFilesDirectory stringByAppendingFormat:@"%@/hrtf/0.wav", colourElement]];
            NSError* pitch_error;
            [PitchPreProcessor makePitchFilesFromSoundURL:url
                                                  pitches:pitches
                                          outputDirectory:outputDirectory
                                                    error:&pitch_error];
            
            if (pitch_error) { SYNTCONFIGERROR(@"Error creating pitch file."); }
        }
    }
    
    
    
    if (hrtf_process != nil && [hrtf_process integerValue] == 1) {
        
        // Get angle used to spread sounds
        float angle = 58; // default
        NSString* hrtfAngle = _syntJsonDic[@"hrtf_angle"];
        if (hrtfAngle != nil) {
            angle = MIN(MAX([hrtfAngle floatValue],0),360);
        }
        
        for(int colour = 0; colour < _colours; ++colour) {
            NSString* colourElement = _colours == 1 ? @"" : [NSString stringWithFormat:@"/%d", colour + 1];
            NSString* outputDirectory = [soundFilesDirectory stringByAppendingFormat:@"%@/", colourElement];
            for(int i = 0; i < _rows; i += 1) {
                int startIndex = _cols * i;
                NSURL* url = [NSURL fileURLWithPath:[soundFilesDirectory stringByAppendingFormat:@"%@/hrtf/%d.wav", colourElement, i + 1]];
                
                //no files get created if they already exist - HRTFPreProcessor takes care of that.
                NSError* hrtf_error;
                [HRTFPreProcessor makeHRTFFilesFromSoundURL:url angleDegrees:angle points:_cols startIndex:startIndex outputDirectory:outputDirectory error:&hrtf_error];
                
                if (hrtf_error) { SYNTCONFIGERROR(@"Error creating hrtf file."); }
            }
        }
    }
    
    
    
    NSMutableArray* urls = [[NSMutableArray alloc] init];
    
    int soundFileNumber = 0;
    
    for(int row = 0; row < _rows; ++row) {
        for(int col = 0; col < _cols; ++col) {
            for(int colour = 0; colour < _colours; ++colour) {
                
                NSString* colourElement = _colours == 1 ? @"" : [NSString stringWithFormat:@"/%d", colour + 1];
                
                NSString * soundFileName = [soundFilesDirectory stringByAppendingFormat:@"%@/%d.wav", colourElement, soundFileNumber];
                
                NSURL* url = [NSURL fileURLWithPath:soundFileName];
                
                if (![url checkResourceIsReachableAndReturnError:error]) {
                    NSString* errorMessage = [NSString stringWithFormat:@"Could not find file: %@", url ];
                    SYNTCONFIGERROR(errorMessage)
                }
                
                [urls addObject:url];
            }
            
            soundFileNumber++;
        }
    }
    NSLog(@"Succesfully found all %d sound files", soundFileNumber);
    _filenames = urls;
    
    [self loadDefaults];
    
    NSArray* ct = _syntJsonDic[@"colour_timing"];
    if (ct != nil) {
        int nTimings = (int)[ct count];
        if (nTimings != _colours) {
            NSLog(@"Timings doesn't match number of colours");
        }
        for(int i = 0; i < nTimings; i += 1) {
            NSString* timing = ct[i];
            _colourConfiguration.colour_timings[i] = [timing floatValue];
        }
        
    }
    
    // Set parameters from file (overwriting defaults)
    NSString* horizontal_focus = _syntJsonDic[@"horizontal_focus"];
    NSString* vertical_focus = _syntJsonDic[@"vertical_focus"];
    NSString* horizontal_offset = _syntJsonDic[@"horizontal_offset"];
    NSString* vertical_offset = _syntJsonDic[@"vertical_offset"];
    NSString* window_width = _syntJsonDic[@"window_width"];
    NSString* window_height = _syntJsonDic[@"window_height"];
    NSString* heartbeat_interval = _syntJsonDic[@"heartbeat_interval"];
    NSString* depth_range = _syntJsonDic[@"depth_range"];
    NSString* depth_distance = _syntJsonDic[@"depth_distance"];
    NSString* depth_mode = _syntJsonDic[@"depth_mode"];
    NSString* pan_gesture = _syntJsonDic[@"pan_gesture"];
    NSString* two_finger_gesture = _syntJsonDic[@"two_finger_gesture"];
    NSString* pinch_gesture = _syntJsonDic[@"pinch_gesture"];
    NSString* vol_source = _syntJsonDic[@"vol_source"];
    NSString* default_depth = _syntJsonDic[@"default_depth"];
    NSString* exponential_loudness = _syntJsonDic[@"exponential_loudness"];
    NSString* orientation = _syntJsonDic[@"orientation"];
    NSString* max_depth_vol = _syntJsonDic[@"max_depth_vol"];
    
    if (horizontal_focus != nil){
        NSLog(@"Over-writing horizontal focus");
        _horizontalFocus = [horizontal_focus floatValue];
    }
    
    if (vertical_focus != nil) {
        NSLog(@"Over-writing vertical focus");
        _verticalFocus = [vertical_focus floatValue];
    }
    
    if (horizontal_offset != nil) {
        NSLog(@"Over-writing horizontal offset");
        _horizontalTimingOffset = [horizontal_offset floatValue];
    }
    
    if (vertical_offset != nil) {
        NSLog(@"Over-writing vertical offset");
        _verticalTimingOffset = [vertical_offset floatValue];
    }
    
    if (window_width != nil) {
        NSLog(@"Over-writing window width");
        _depthDataWindowWidth = [window_width floatValue];
    }
    
    if (window_height != nil) {
        NSLog(@"Over-writing window height");
        _depthDataWindowHeight = [window_height floatValue];
    }
    
    if (heartbeat_interval != nil) {
        NSLog(@"Over-writing heartbeat interval");
        _heartbeatInterval = [heartbeat_interval floatValue];
    }
    
    if (depth_range != nil) {
        NSLog(@"Over-writing depth range");
        _depthRange = [depth_range floatValue];
    }
    
    if (depth_distance != nil) {
        NSLog(@"Over-writing depth distance");
        _depthDistance = [depth_distance floatValue];
    }
    
    if (depth_mode != nil) {
        NSLog(@"Over-writing depth mode");
        _depthMode = [depth_mode boolValue];
    }
    
    if (pan_gesture != nil) {
        NSLog(@"Over-writing pan gesture");
        _panGesture = pan_gesture;
    }
    
    if (two_finger_gesture != nil) {
        NSLog(@"Over-writing two finger gesture");
        _twoFingerGesture = two_finger_gesture;
    }
    
    if (pinch_gesture != nil) {
        NSLog(@"Over-writing pinch gesture");
        _pinchGesture  = pinch_gesture;
    }
    
    if (vol_source != nil) {
        NSLog(@"Over-writing vol source");
        _volSource = vol_source;
    }
    
    if (default_depth != nil) {
        NSLog(@"Over-writing default depth");
        _defaultDepth = [default_depth floatValue];
    }
    
    if (exponential_loudness != nil) {
        NSLog(@"Over writing exponetial loudness");
        _exponentialLoudness = [exponential_loudness boolValue];
    }
    

    if (orientation != nil) {
        NSLog(@"Overwriting orientation");
        _orientation = orientation;
    }

    if (max_depth_vol != nil) {
        NSLog(@"Over writing max deoth vol");
        _maxDepthVolume = [max_depth_vol floatValue];
    }
    
    NSDictionary* colourConfig = _syntJsonDic[@"colour_configuration"];
    if (colourConfig != nil) {
        [self setColourConfig:colourConfig];
    }
    
    NSDictionary* reverbConfig = _syntJsonDic[@"reverb_configuration"];
    if (reverbConfig != nil) {
        [self setReverbConfig:reverbConfig];
    }

    NSString* validation = [self validateConfig];
    
    if (![validation isEqualToString:@""]) {
        SYNTCONFIGERROR(validation);
    }
    
    return true;
}


/**
 * Validates the config and returns an empty string if ok, or an error message if not.
 */
-(NSString*)validateConfig {
    
    NSMutableString* error = [[NSMutableString alloc] init];
    
    ASSERTINRANGE(_horizontalFocus,
                  SYN_FOCUS_MAX,SYN_FOCUS_MIN,
                  @"Horizontal Focus out of range\n")
    
    ASSERTINRANGE(_verticalFocus,
                  SYN_FOCUS_MAX,SYN_FOCUS_MIN,
                  @"Vertical Focus out of range\n")
    
    ASSERTINRANGE(_horizontalTimingOffset,
                  SYN_TIMING_MAX,SYN_TIMING_MIN,
                  @"Horizontal Timing Offset out of range\n")
    
    ASSERTINRANGE(_verticalTimingOffset,
                  SYN_TIMING_MAX,SYN_TIMING_MIN,
                  @"Vertical Timing Offset out of range\n")
    
    ASSERTINRANGE(_depthDataWindowWidth,
                  SYN_DEPTH_WIN_MAX,SYN_DEPTH_WIN_MIN,
                  @"Depth Data Window Width out of range\n")
    
    ASSERTINRANGE(_depthDataWindowHeight,
                  SYN_DEPTH_WIN_MAX,SYN_DEPTH_WIN_MIN,
                  @"Depth Data Window Height out of range\n")
    
    ASSERTINRANGE(_heartbeatInterval,
                  SYN_HB_MAX,SYN_HB_MIN,
                  @"Heartbeat Interval out of range\n")
    
    ASSERTINRANGE(_depthRange,
                  SYN_DEPTH_MM_MAX,SYN_DEPTH_MM_MIN
                  ,@"Depth Range out of range\n")
                  
    ASSERTINRANGE(_depthDistance,
                  SYN_CLOSEST_DEPTH_MM_MAX,SYN_CLOSEST_DEPTH_MM_MIN
                  ,@"Cloesest Depth value out of range\n")
                  
    ASSERTINRANGE(_defaultDepth, 1, 0, @"Default depth out of range\n")
    
    ASSERTINRANGE(_maxDepthVolume,
                  1,0,
                  @"Max depth volume out of range\n")
    
    if ([error length] != 0) {
        [error appendString:@"Please fix in settings!"];
    }
    
    return error;
}

-(void)setColourConfig:(NSDictionary*)jsonConfig {
    
    //Check if bw_mode is active
    bool bw_mode = [jsonConfig[@"bw_mode"] boolValue];
    
    if (bw_mode) {
        float bw_level = [jsonConfig[@"bw_level"] floatValue];
        
        _colourConfiguration.bw_mode = true;
        _colourConfiguration.bw_level = bw_level;
        return;
    }
    
    _colourConfiguration.bw_mode = false;
    _colourConfiguration.saturation_threshold = [jsonConfig[@"saturation_threshold"] floatValue];
    NSArray* lightness_thresholds = jsonConfig[@"lightness_thresholds"];
    NSArray* hue_thresholds = jsonConfig[@"hue_thresholds"];
    _colourConfiguration.n_lightness_thresholds = MIN((int)[lightness_thresholds count], MAX_LIGHTNESS_THRESHOLDS);
    _colourConfiguration.n_hue_thresholds = MIN((int)[hue_thresholds count], MAX_HUE_THRESHOLDS);
    
    for(int i = 0; i < _colourConfiguration.n_lightness_thresholds; i += 1) {
        _colourConfiguration.lightness_thresholds[i] = [lightness_thresholds[i] floatValue];
    }
    
    for(int i = 0; i < _colourConfiguration.n_hue_thresholds; i += 1) {
        _colourConfiguration.hue_thresholds[i] = [hue_thresholds[i] floatValue];
    }
    
    _colourConfiguration.boundary_mode = [jsonConfig[@"boundary_mode"] boolValue];
}

-(void)setReverbConfig:(NSDictionary*)jsonConfig {
    
    //Check if bw_mode is active
    _reverbConfiguration.wetDryMix = [jsonConfig[@"wet_dry"] floatValue];
    _reverbConfiguration.presetIndex = (CFIndex)[jsonConfig[@"preset"] intValue];
}

-(void)saveSyntFileWithCurrentSettings {
    
    // Get current synt file for colour configuration
    NSError *error;
    NSMutableDictionary *jsonDic = [_syntJsonDic mutableCopy];
    
    jsonDic[@"rows"] = @(_rows);
    jsonDic[@"cols"] = @(_cols);
    jsonDic[@"colours"] = @(_colours);
    jsonDic[@"name"] = _name;
    jsonDic[@"vol_source"] = _volSource;
    jsonDic[@"horizontal_focus"] = @(_horizontalFocus);
    jsonDic[@"vertical_focus"] = @(_verticalFocus);
    jsonDic[@"horizontal_offset"] = @(_horizontalTimingOffset);
    jsonDic[@"vertical_offset"] = @(_verticalTimingOffset);
    jsonDic[@"window_width"] = @(_depthDataWindowWidth);
    jsonDic[@"window_height"] = @(_depthDataWindowHeight);
    jsonDic[@"heartbeat_interval"] = @(_heartbeatInterval);
    jsonDic[@"depth_range"] = @(_depthRange);
    jsonDic[@"depth_distance"] = @(_depthDistance);
    jsonDic[@"depth_mode"] = @(_depthMode);
    jsonDic[@"default_depth"] = @(_defaultDepth);
    jsonDic[@"exponential_loudness"] = @(_exponentialLoudness);
    jsonDic[@"orientation"] = _orientation;
    jsonDic[@"max_depth_vol"] = @(_maxDepthVolume);
    
    if (_panGesture)
        jsonDic[@"pan_gesture"] = _panGesture;
    
    if (_twoFingerGesture)
        jsonDic[@"two_finger_gesture"] = _twoFingerGesture;
    
    if (_pinchGesture)
        jsonDic[@"pinch_gesture"] = _pinchGesture;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (!jsonData) {
        NSLog(@"%s: error: %@", __func__, error.localizedDescription);
        
    } else {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"custom.synt"];
        NSString *synt = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [synt writeToFile:path atomically:YES encoding:NSUnicodeStringEncoding error:&error];
        
#if TARGET_IPHONE_SIMULATOR
        
        NSLog(@"Saved to Documents Directory: %@", [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]);
#endif
    }
}
@end
