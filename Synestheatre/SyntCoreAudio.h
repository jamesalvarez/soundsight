//
//  SyntCoreAudio.h
//  Synestheatre
//
//  Created by James on 08/09/2016.
//  Copyright © 2016 James. All rights reserved.
//


#ifndef SyntCoreAudio_h
#define SyntCoreAudio_h

#include <stdio.h>
#include <AudioToolbox/AudioToolbox.h>

/**
 *  SyntCoreAudio is a simple Core Audio engine that loads entire sound files
 *  into memory with ExtAudioFile, and plays them at various time offsets.
 *  Fairly defensive, should have no trouble forgetting to dispose of things etc
 *
 */


/**
*  Sets the reverb parameters - call before SyntStartAudioOutput()
*/
void SynSetupReverbParameters(float dryWetMix, CFIndex presetIndex);

/**
 *  Sets the number of audio files
 *
 *  @param nSoundFiles number of sound files to play simultaneously
 *
 *  @return false if memory error
 */
bool SyntSetupSounds(UInt32 nSoundFiles);


/**
 *  Loads an audio file from url into index
 *
 *  @param url   url of audio file
 *  @param index index
 */
bool SyntLoadAudioFile(CFURLRef url, UInt32 index);


/**
 *  Disposes of all audio files
 */
void SyntDisposeSounds(void);


/**
 *  Start outputing audio
 */
void SyntStartAudioOutput(void);


/**
 *  Stop outputting audio
 */
void SyntDisposeAudioOutput(void);


/**
 *  Set the volume for an audio file
 *
 *  @param volume (0 - 1)
 *  @param index  index
 */
void SyntSetAudioFileVolume(float volume, UInt32 index);


/**
 *  Set the audio file to play now
 *
 *  @param index index
 */
void SyntPlayAudioFileNow(UInt32 index);


/**
 *  Set the audio file to play secs from now
 *
 *  @param secs  time in seconds
 *  @param index index
 */
void SyntPlayAudioFileSecsFromNow(float secs, UInt32 index);


#endif /* SyntCoreAudio_h */
