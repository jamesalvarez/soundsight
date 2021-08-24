//
//  AudioController.m
//  Synestheatre
//
//  Created by James on 11/08/2016.
//  Copyright © 2016 James. All rights reserved.
//


#import "AudioController.h"
#import <AVFoundation/AVFoundation.h>
#import "SyntCoreAudio.h"

@implementation AudioController


- (bool)startWithURLs:(NSArray *)urls andReverb:(ReverbConfiguration)reverbConfig {
    
    // Make sure we have cleaned everything up before starting again
    [self stop];
    
    static BOOL setupAudioSession = YES;
    
    if (setupAudioSession) {
    
        NSError *error = nil;
        if ( ![[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error] ) {
            NSLog(@"Couldn't set audio session category: %@", error);
        }
        
        if ( ![[AVAudioSession sharedInstance] setPreferredIOBufferDuration:(128.0/44100.0) error:&error] ) {
            NSLog(@"Couldn't set preferred buffer duration: %@", error);
        }
        
        if ( ![[AVAudioSession sharedInstance] setActive:YES error:&error] ) {
            NSLog(@"Couldn't set audio session active: %@", error);
        }
        
        setupAudioSession = NO;
    }
    
    // Setup configuration for number of sounds
    if (!SyntSetupSounds((UInt32)[urls count])) {
        return false;
    }
    
    // Load the sounds
    UInt32 index = 0;
    for (NSURL* url in urls) {
        bool success = SyntLoadAudioFile((__bridge CFURLRef) url, index);
        
        if (!success) {
            NSLog(@"Error loading file, abandon ship");
            [self stop];
            return false;
        }
        index++;
    }
    
    // Set reverb parameters
    /*
    0 = Small Room
    1 = Medium Room
    2 = Large Room
    3 = Medium Hall
    4 = Large Hall
    5 = Plate
    6 = Medium Chamber
    7 = Large Chamber
    8 = Cathedral
    9 = Large Room 2
    10 = Medium Hall 2
    11 = Medium Hall 3
    12 = Large Hall 2*/
    SynSetupReverbParameters(reverbConfig.wetDryMix, reverbConfig.presetIndex);
    
    // Start audio output
    SyntStartAudioOutput();
    
    _LoadedAudio = true;
    return true;
}


- (void)stop {
    _LoadedAudio = false;
    SyntDisposeAudioOutput();
    SyntDisposeSounds();
}

-(void)playAtDelays:(NSArray*)delays {
    if (!_LoadedAudio) return;
    for (int i = 0; i < delays.count; i++) {
        NSNumber* delay = delays[i];
        // Note 'now' might actually vary within the loop... so accuracy can be improved
        SyntPlayAudioFileSecsFromNow(delay.floatValue, i);
    }
}

-(void)setNewVolumes:(NSArray*)newVolumes {
    if (!_LoadedAudio) return;
    for (int i = 0; i < newVolumes.count; i++) {
        NSNumber* vol = newVolumes[i];
        SyntSetAudioFileVolume(vol.floatValue, i);
    }
}


@end
