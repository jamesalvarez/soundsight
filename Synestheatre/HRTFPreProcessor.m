//
//  HRTFPreProcessor.m
//  Synestheatre
//
//  Created by James on 28/11/2018.
//  Copyright © 2018 James. All rights reserved.
//

#import "HRTFPreProcessor.h"
#include <math.h>
#import <AVFoundation/AVFoundation.h>

@interface HRTFPreProcessor() {
    
}
@end

@implementation HRTFPreProcessor

+ (void)makeHRTFFilesFromSoundURL:(NSURL*)url angleDegrees:(int) angleDegrees points:(int)nPoints startIndex:(int)startIndex outputDirectory:(NSString*)outputDirectory error:(NSError * _Nullable *)error {
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    for(int i = 0; i < nPoints; i += 1) {
        NSString* fileName = [NSString stringWithFormat:@"%d.wav", i + startIndex];
        NSString *fullOutputFilename = [NSString stringWithFormat:@"%@/%@",outputDirectory, fileName];
        

        // Skip creating a file if the file already exists
        if ([fileManager fileExistsAtPath:fullOutputFilename]) {
            continue;
        } else {
            NSLog(@"Creating HRTF file: %@", fileName);
        }
        

        float around = ((float)i / (float)(nPoints - 1)) - 0.5; // -0.5 -> +0.5
        float angle_spread = M_PI * (float)angleDegrees / (float)180;
        float this_angle = (angle_spread * around);

        float distance = 4;
        float x = distance * sinf(this_angle);
        float y = distance * cosf(this_angle);
        
        
        [HRTFPreProcessor makeHRTFAudioFile:url point:AVAudioMake3DPoint(x, 0, y) filename:fullOutputFilename error: error];
    }
}


+ (void)makeHRTFAudioFile:(NSURL*)sourceURL point:(AVAudio3DPoint)point filename:(NSString*)outputFilename error:(NSError * _Nullable *)error{
    
    
    AVAudioFile* sourceFile = [[AVAudioFile alloc] initForReading:sourceURL error:error];
    
    if ((*error) != nil) {
        NSLog(@"%@", [(*error) localizedDescription]);
        NSLog(@"Audio file notloaded");
        return;
    }
    
    
    
    AVAudioEngine* engine = [[AVAudioEngine alloc] init];
    const double hardwareSampleRate = [engine.outputNode outputFormatForBus:0].sampleRate;
    AVAudioPlayerNode* player = [[AVAudioPlayerNode alloc] init];
    AVAudioEnvironmentNode* environmentNode = [[AVAudioEnvironmentNode alloc] init];
    [engine attachNode:player];
    [engine attachNode:environmentNode];
    
    AVAudio3DMixingRenderingAlgorithm renderingAlgo = AVAudio3DMixingRenderingAlgorithmHRTFHQ;
    player.renderingAlgorithm = renderingAlgo;
    player.position = point;
    
    environmentNode.reverbBlend = 0.5;
    environmentNode.reverbParameters.enable = true;
    
    /*! @property level
        @abstract Controls the master level of the reverb
        @discussion
            Range:      -40 to 40 dB
            Default:    0.0
    */
    environmentNode.reverbParameters.level = 0.0;
    /*
     AVAudioUnitReverbPresetSmallRoom       = 0,
     AVAudioUnitReverbPresetMediumRoom      = 1,
     AVAudioUnitReverbPresetLargeRoom       = 2,
     AVAudioUnitReverbPresetMediumHall      = 3,
     AVAudioUnitReverbPresetLargeHall       = 4,
     AVAudioUnitReverbPresetPlate           = 5,
     AVAudioUnitReverbPresetMediumChamber   = 6,
     AVAudioUnitReverbPresetLargeChamber    = 7,
     AVAudioUnitReverbPresetCathedral       = 8,
     AVAudioUnitReverbPresetLargeRoom2      = 9,
     AVAudioUnitReverbPresetMediumHall2     = 10,
     AVAudioUnitReverbPresetMediumHall3     = 11,
     AVAudioUnitReverbPresetLargeHall2      = 12
     */
    [environmentNode.reverbParameters loadFactoryReverbPreset: AVAudioUnitReverbPresetLargeHall2];
    
    
    
    AVAudioFormat* sourceFormat = [sourceFile processingFormat];
    AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:sourceFormat.sampleRate channels:1]; //needs to be mono
    AVAudioFormat* outputFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:hardwareSampleRate channels:2];
    
    [engine connect: player to: environmentNode format: format];
    [engine connect: environmentNode to: engine.mainMixerNode format: outputFormat];
    
    [player scheduleFile:sourceFile atTime:nil completionHandler:nil];
    AVAudioFrameCount maxFrames = 4096;
    [engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline format:sourceFormat maximumFrameCount:maxFrames error:error];
    if ((*error) != nil) {
        NSLog(@"No manual rendering mode");
        return;
    }
    
    [engine startAndReturnError:error];
    if ((*error) != nil) {
        NSLog(@"Cant start");
        return;
    }
    
    [player play];
    
    
    
    NSLog(@"Attempting to write to: %@", outputFilename);
    NSURL* outputURL = [[NSURL alloc] initWithString:outputFilename];
    AVAudioFile* outputFile = [[AVAudioFile alloc] initForWriting:outputURL settings:sourceFile.fileFormat.settings error:error];
    
    if ((*error) != nil) {
        NSLog(@"Cant output file");
        return;
    }
    
    AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:engine.manualRenderingFormat frameCapacity:engine.manualRenderingMaximumFrameCount];
    
    while (engine.manualRenderingSampleTime < sourceFile.length) {
        AVAudioFrameCount framesToRender = (AVAudioFrameCount)MIN(buffer.frameCapacity, sourceFile.length - engine.manualRenderingSampleTime);
        AVAudioEngineManualRenderingStatus status = [engine renderOffline:framesToRender toBuffer:buffer error:error];
        
        switch(status) {
            case AVAudioEngineManualRenderingStatusError:
                break;
            case AVAudioEngineManualRenderingStatusSuccess:
                [outputFile writeFromBuffer:buffer error:error];
                break;
            case AVAudioEngineManualRenderingStatusInsufficientDataFromInputNode:
                break;
            case AVAudioEngineManualRenderingStatusCannotDoInCurrentContext:
                break;
        }
    }
    
    [player stop];
    [engine stop];
}

@end
