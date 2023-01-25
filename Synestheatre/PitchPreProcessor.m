//
//  PitchPreProcessor.m
//  Synestheatre
//
//  Created by James on 11/07/2019.
//  Copyright © 2019 James. All rights reserved.
//

#import "PitchPreProcessor.h"
#include <math.h>
#import <AVFoundation/AVFoundation.h>

@implementation PitchPreProcessor

+ (void)makePitchFilesFromSoundURL:(NSURL*)url pitches:(NSArray*)pitches outputDirectory:(NSString*)outputDirectory error:(NSError * _Nullable *)error {
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    for(int i = 0; i < [pitches count]; i += 1) {
        NSString* fileName = [NSString stringWithFormat:@"%d.wav", i + 1];
        NSString *fullOutputFilename = [NSString stringWithFormat:@"%@/%@",outputDirectory, fileName];
        
        
        // Skip creating a file if the file already exists
        if ([fileManager fileExistsAtPath:fullOutputFilename]) {
            continue;
        } else {
            NSLog(@"Creating Pitch file: %@", fileName);
        }
        
        
        float pitch = [pitches[i] floatValue];
        
        [PitchPreProcessor makePitchedAudioFile:url pitch:pitch filename:fullOutputFilename error: error];
    }
}


+ (void)makePitchedAudioFile:(NSURL*)sourceURL pitch:(float)pitch filename:(NSString*)outputFilename error:(NSError * _Nullable *)error {
    
    
    AVAudioFile* sourceFile = [[AVAudioFile alloc] initForReading:sourceURL error:error];
    
    if ((*error) != nil) {
        NSLog(@"%@", [(*error) localizedDescription]);
        NSLog(@"Audio file notloaded");
        return;
    }
    
    
    
    AVAudioEngine* engine = [[AVAudioEngine alloc] init];
    
    AVAudioPlayerNode* player = [[AVAudioPlayerNode alloc] init];
    AVAudioUnitTimePitch* timePitch = [[AVAudioUnitTimePitch alloc] init];
    [timePitch setPitch:pitch];
    [engine attachNode:player];
    [engine attachNode:timePitch];

    //const double hardwareSampleRate = [engine.outputNode outputFormatForBus:0].sampleRate;
    AVAudioFormat* sourceFormat = [sourceFile processingFormat];
    //AVAudioFormat* outputFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:hardwareSampleRate channels:2];
    
    [engine connect: player to: timePitch format: sourceFormat];
    [engine connect: timePitch to: engine.mainMixerNode format: sourceFormat];
    
    [player scheduleFile:sourceFile atTime:nil completionHandler:nil];
    AVAudioFrameCount maxFrames = 4096;
    [engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline format:sourceFormat maximumFrameCount:maxFrames error:error];
    if ((*error) != nil) {
        NSLog(@"No manual rendering mode");
        NSLog(@"%@",[*error localizedDescription]);
        return;
    }
    
    [engine startAndReturnError:error];
    if ((*error) != nil) {
        NSLog(@"Cant start");
        NSLog(@"%@",[*error localizedDescription]);
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
