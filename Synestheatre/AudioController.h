//
//  AudioController.h
//  Synestheatre
//
//  Created by James on 11/08/2016.
//  Copyright © 2016 James. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReverbConfiguration.h"

/**
 * 'AudioController' is an objective-C wrapper around the Core Audio c code.
 * It also deals with requesting AVAudioSession and managing various audio events.
 *
 * It should probably be a singleton - but it's not, so only create one.
 */
@interface AudioController : NSObject

/**
 * Is true when audio is loaded and ready to use.
 */
@property (nonatomic, readwrite) bool LoadedAudio;

/**
 *  Negotiates AVAudioSession and starts audio with the given URLS for sound files.
 *  Index of URL in the array corresponds to indexes in other methods for setting delays / volumes
 *
 *  @param urls An NSArray of NSURLs to sound files (only those supported by ExtAudioFile API)
 *
 *  @return success or not
 *
 */
- (bool)startWithURLs:(NSArray *)urls andReverb:(ReverbConfiguration)reverbConfig;


/**
 *  Stops and disposes audio engine.  Do not have to call this when restarting.
 */
-(void)stop;

/**
 *  Sets audio files to play after a certain time (secs)
 *
 *  @param delays NSArray of NSNumbers (floats) of time offsets
 */
-(void)playAtDelays:(NSArray*)delays;

/**
 *  Sets each audio files volume
 *
 *  @param newVolumes NSArray of NSNumbers (floats 0 - 1) for volume
 */
-(void)setNewVolumes:(NSArray*)newVolumes;

@end
