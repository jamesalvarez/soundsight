//
//  SyntCoreAudio.c
//  Synestheatre
//
//  Created by James on 08/09/2016.
//  Copyright © 2016 James. All rights reserved.
//

#include "SyntCoreAudio.h"

#define SYNT_SAMPLE_RATE 44100
#define SYNT_CHANNELS 2
#define SYNT_SAMPLE_SIZE sizeof(Float32)
#define SYNT_RAMPSSTEP_POS 0.01
#define SYNT_RAMPSSTEP_NEG -SYNT_RAMPSSTEP_POS

#pragma mark - consts & static globals -

typedef SInt64 SyntFrameIndex;

#define SYNTFRAMEINDEX_MAX LONG_MAX;

// A struct to hold data and playback status

typedef struct SyntAudioFile {
    AudioBufferList *bufferList;
    UInt32 frames;
    SyntFrameIndex frameStarted;
    SyntFrameIndex nextFrameToStart;
    float volume;
    float targetVolume; //will ramp volume towards target volume
} SyntAudioFile;

// A struct to hold information about output status

typedef struct SyntAudioOutput {
    AudioUnit reverbUnit;
    AudioUnit outputUnit;
    AudioUnit converterUnit;
} SyntAudioOutput;



AudioStreamBasicDescription const syntAudioDescription = {
    .mSampleRate        = SYNT_SAMPLE_RATE,
    .mFormatID          = kAudioFormatLinearPCM,
    .mFormatFlags       = kAudioFormatFlagIsFloat,
    .mBytesPerPacket    = SYNT_SAMPLE_SIZE * SYNT_CHANNELS,
    .mFramesPerPacket   = 1,
    .mBytesPerFrame     = SYNT_CHANNELS * SYNT_SAMPLE_SIZE,
    .mChannelsPerFrame  = SYNT_CHANNELS,
    .mBitsPerChannel    = 8 * SYNT_SAMPLE_SIZE, //8 bits per byte, 1 sample per channel
    .mReserved          = 0
};


static SyntAudioOutput syntAudioOuput;
static SyntAudioFile* syntAudioFiles;
static UInt32 syntNumberOfFiles;
static SyntFrameIndex syntCurrentFrame = 0;
static uint totalBufferSizeBytes = 0;
#pragma mark - render functions -

static OSStatus SyntRenderProc(void *inRefCon,
                               AudioUnitRenderActionFlags *ioActionFlags,
                               const AudioTimeStamp *inTimeStamp,
                               UInt32 inBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList * ioData) {
    

    Float32 *outputData = (Float32*)ioData->mBuffers[0].mData;
    UInt32 nSamples = inNumberFrames * SYNT_CHANNELS;
    
    for (UInt32 sample = 0; sample < nSamples; ++sample) {
        (outputData)[sample] = 0;
    }
    
    for (UInt32 playerIndex = 0; playerIndex < syntNumberOfFiles; ++playerIndex) {
        SyntAudioFile *audioPlayer = &syntAudioFiles[playerIndex];
        SyntFrameIndex currentFrame = syntCurrentFrame - audioPlayer->frameStarted;
        UInt32 maxFrames = audioPlayer->frames;
        Float32 *inputData = (Float32*)audioPlayer->bufferList->mBuffers[0].mData;
        Float32 volume = audioPlayer->volume;
        
        for (UInt32 frame = 0; frame < inNumberFrames; ++frame) {
            if (currentFrame > -1 && currentFrame < maxFrames) {
                UInt32 outSample = frame * 2;
                UInt32 inSample = (UInt32)currentFrame * 2;
                (outputData)[outSample] += (inputData)[inSample] * volume ;
                (outputData)[outSample+1] += (inputData)[inSample + 1] * volume;
            }
            currentFrame++;
        }
        
        //adjust volume towards target if necessary
        Float32 volDifference = audioPlayer->targetVolume - audioPlayer->volume;
        if (volDifference > SYNT_RAMPSSTEP_POS) {
            audioPlayer->volume += SYNT_RAMPSSTEP_POS;
        } else if (volDifference < SYNT_RAMPSSTEP_NEG) {
            audioPlayer->volume += SYNT_RAMPSSTEP_NEG;
        } else {
            audioPlayer->volume = audioPlayer->targetVolume;
        }
        
        //trigger sound if its time
        if (syntCurrentFrame >= audioPlayer->nextFrameToStart) {
            audioPlayer->frameStarted = audioPlayer->nextFrameToStart;
            audioPlayer->nextFrameToStart = SYNTFRAMEINDEX_MAX;
        }

    }
    
    syntCurrentFrame += inNumberFrames;
    
    return noErr;
}

// generic error handler - if err is nonzero, prints error message and exits program.
static void CheckError(OSStatus error, const char *operation) {
    if (error == noErr) return;
    
    char str[20];
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    
    fprintf(stderr, "Error: %s (%s)\n", operation, str);
    
    exit(1);
}

void SyntPlayAudioFileNow(UInt32 index) {
    SyntPlayAudioFileSecsFromNow(0, index);
}

void SyntPlayAudioFileSecsFromNow(float secs, UInt32 index) {
    if (index >= syntNumberOfFiles) {
        printf("Invalid index for Audio File");
        return;
    }
    
    SyntFrameIndex delayInFrames = secs * SYNT_SAMPLE_RATE;
    syntAudioFiles[index].nextFrameToStart = syntCurrentFrame + delayInFrames;
}

void SyntSetAudioFileVolume(float volume, UInt32 index) {
    
    if (index >= syntNumberOfFiles) {
        printf("Invalid index for Audio File");
        return;
    }
    
    syntAudioFiles[index].targetVolume = volume;
}

void SyntDisposeAudioFile(UInt32 index) {
    
    if (index >= syntNumberOfFiles) {
        printf("Invalid index for Audio File");
        return;
    }
    
    if (index == 0) {
        printf("o)");
    }
    
    if (syntAudioFiles == NULL) return; //all files disposed
    
    SyntAudioFile *audioPlayer = &syntAudioFiles[index];
    
    if (audioPlayer == NULL) return; //already disposed
    
    AudioBufferList * bufferList = audioPlayer->bufferList;
    if (bufferList != NULL) {
        for ( int j=0; j<bufferList->mNumberBuffers; j++ ) {
            if (bufferList->mBuffers[j].mData != NULL) {
                free(bufferList->mBuffers[j].mData);
                bufferList->mBuffers[j].mData = NULL;
            }
            
        }
        free(audioPlayer->bufferList);
        audioPlayer->bufferList = NULL;
    }
    audioPlayer->frameStarted = 0;
    audioPlayer->frames = 0;
    audioPlayer->volume = 0;
    
}

void SyntDisposeAllAudioFiles() {
    for (UInt32 playerIndex = 0; playerIndex < syntNumberOfFiles; ++playerIndex) {
        SyntDisposeAudioFile(playerIndex);
    }
    totalBufferSizeBytes = 0;
}

void SyntDisposeSounds() {
    if (syntAudioFiles != NULL) {
        SyntDisposeAllAudioFiles();
        free(syntAudioFiles);
        syntAudioFiles = NULL;
    }
}

bool SyntSetupSounds(UInt32 nSoundFiles) {
    SyntDisposeSounds();
    
    syntAudioFiles = (SyntAudioFile*)calloc(nSoundFiles, sizeof(SyntAudioFile));
    
    if (syntAudioFiles) {
        syntNumberOfFiles = nSoundFiles;
        return true;
    } else {
        syntNumberOfFiles = 0;
        return false;
    }
    
}

static float reverbWetDryMix = 50;
static CFIndex reverbPresetIndex = 0;

void SynSetupReverbParameters(float dryWetMix, CFIndex presetIndex) {

    reverbWetDryMix = dryWetMix;
    reverbPresetIndex = presetIndex;
}


bool SyntLoadAudioFile(CFURLRef url, UInt32 index) {
    
    if (index >= syntNumberOfFiles) {
        printf("Invalid index for Audio File");
        return false;
    }
    
    SyntDisposeAudioFile(index);
    
    SyntAudioFile *audioPlayer = &syntAudioFiles[index];
    
    ExtAudioFileRef audioFile;
    OSStatus status;
    
    // Open file
    status = ExtAudioFileOpenURL(url, &audioFile);
    
    CheckError(status,"Could not open audio file");
    
    // Get file data format
    AudioStreamBasicDescription fileAudioDescription;
    UInt32 size = sizeof(fileAudioDescription);
    status = ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileDataFormat, &size, &fileAudioDescription);
    
    
    // Apply our format
    
    status = ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(syntAudioDescription), &syntAudioDescription);
    
    
    // Determine length in frames (in original file's sample rate)
    UInt64 fileLengthInFrames;
    size = sizeof(fileLengthInFrames);
    status = ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileLengthFrames, &size, &fileLengthInFrames);
    
    // Calculate the true length in frames, given the original and target sample rates
    fileLengthInFrames = ceil(fileLengthInFrames * (syntAudioDescription.mSampleRate / fileAudioDescription.mSampleRate));
    
    // Prepare buffer
    
    int numberOfBuffers = syntAudioDescription.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? syntAudioDescription.mChannelsPerFrame : 1;
    int channelsPerBuffer = syntAudioDescription.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? 1 : syntAudioDescription.mChannelsPerFrame;
    int bytesPerBuffer = syntAudioDescription.mBytesPerFrame * (int)fileLengthInFrames;
    
    
    // Check total memory use
    totalBufferSizeBytes += bytesPerBuffer * numberOfBuffers;
    if (totalBufferSizeBytes > 1610612736) { //1.5GB
        fprintf(stderr, "Too big memory usage in bytes: %d \n", totalBufferSizeBytes);
        ExtAudioFileDispose(audioFile); //out of memory?
        return false;
    }
    
    
    
    uint sizeOfBuffer = sizeof(AudioBufferList) + (numberOfBuffers-1)*sizeof(AudioBuffer);
    AudioBufferList *bufferList = calloc(sizeOfBuffer,1);

    
    if ( !bufferList ) {
        ExtAudioFileDispose(audioFile); //out of memory?
        return false;
    }
    
    bufferList->mNumberBuffers = numberOfBuffers;
    for ( int i=0; i<numberOfBuffers; i++ ) {
        if ( bytesPerBuffer > 0 ) {
            bufferList->mBuffers[i].mData = calloc(bytesPerBuffer, 1);
            if ( !bufferList->mBuffers[i].mData ) {
                for ( int j=0; j<i; j++ ) {
                    free(bufferList->mBuffers[j].mData);
                    bufferList->mBuffers[j].mData = NULL;
                }
                free(bufferList);
                bufferList = NULL;
                ExtAudioFileDispose(audioFile); //out of memory?
                return false;
            }
        } else {
            bufferList->mBuffers[i].mData = NULL;
        }
        bufferList->mBuffers[i].mDataByteSize = bytesPerBuffer;
        bufferList->mBuffers[i].mNumberChannels = channelsPerBuffer;
    }
    
    
    
    // Perform read in multiple small chunks (otherwise ExtAudioFileRead crashes when performing sample rate conversion)
    UInt32 readFrames = 0;
    
    // Create a stack copy of the given audio buffer list and offset mData pointers, with offset in bytes
    char scratchBufferList_bytes[sizeof(AudioBufferList)+(sizeof(AudioBuffer)*(bufferList->mNumberBuffers-1))];
    memcpy(scratchBufferList_bytes, bufferList, sizeof(scratchBufferList_bytes));
    
    AudioBufferList * scratchBufferList = (AudioBufferList*)scratchBufferList_bytes;
    
    for ( int i=0; i<scratchBufferList->mNumberBuffers; i++ ) {
        scratchBufferList->mBuffers[i].mData = (char*)scratchBufferList->mBuffers[i].mData;
    }
    
    while ( readFrames < fileLengthInFrames) {
        UInt32 framesLeftToRead = (UInt32)fileLengthInFrames - readFrames;
        UInt32 framesToRead = (16384 < framesLeftToRead) ? 16384 : framesLeftToRead;
        
        scratchBufferList->mNumberBuffers = bufferList->mNumberBuffers;
        for ( int i=0; i<bufferList->mNumberBuffers; i++ ) {
            scratchBufferList->mBuffers[i].mNumberChannels = bufferList->mBuffers[i].mNumberChannels;
            scratchBufferList->mBuffers[i].mData = bufferList->mBuffers[i].mData + (readFrames * syntAudioDescription.mBytesPerFrame);
            scratchBufferList->mBuffers[i].mDataByteSize = framesToRead * syntAudioDescription.mBytesPerFrame;
        }
        
        
        // Perform read
        status = ExtAudioFileRead(audioFile, &framesToRead, scratchBufferList);
        
        
        
        if ( framesToRead == 0 ) {
            // Termination condition
            break;
        }
        
        readFrames += framesToRead;
    }
    
    
    // Clean up
    ExtAudioFileDispose(audioFile);
    
    
    //bufferList and readFrames are the audio we loaded
    audioPlayer->bufferList = bufferList;
    audioPlayer->frames = readFrames;
    return true;
}

void SyntStartAudioOutput() {
    
    SyntDisposeAudioOutput();
    
    /*
     * Get converter
     */
    
    AudioComponentDescription convertercd;
    convertercd.componentType = kAudioUnitType_FormatConverter;
    convertercd.componentSubType = kAudioUnitSubType_AUConverter;
    convertercd.componentManufacturer = kAudioUnitManufacturer_Apple;
    convertercd.componentFlags = 0;
    convertercd.componentFlagsMask = 0;

    AudioComponent converter = AudioComponentFindNext(NULL, &convertercd);
    CheckError(AudioComponentInstanceNew(converter, &syntAudioOuput.converterUnit),
               "Couldn't open converter");
    
    /*
     * Get Reverb
     */
    AudioComponentDescription reverbcd = {
        .componentType = kAudioUnitType_Effect,
        .componentSubType = kAudioUnitSubType_Reverb2,
        .componentManufacturer = kAudioUnitManufacturer_Apple,
        .componentFlags = 0,
        .componentFlagsMask = 0
    };
    
    AudioComponent reverb = AudioComponentFindNext (NULL, &reverbcd);
    CheckError (AudioComponentInstanceNew(reverb, &syntAudioOuput.reverbUnit),
                "Couldn't open component for reverb");
    
    

    
    /*
    * Get output component
    */
    AudioComponentDescription outputcd = {
        .componentType = kAudioUnitType_Output,
        .componentSubType = kAudioUnitSubType_RemoteIO,
        .componentManufacturer = kAudioUnitManufacturer_Apple,
        .componentFlags = 0,
        .componentFlagsMask = 0
    };
    
    AudioComponent comp = AudioComponentFindNext (NULL, &outputcd);
    CheckError (AudioComponentInstanceNew(comp, &syntAudioOuput.outputUnit),
                "Couldn't open component for outputUnit");
    
    
    /*
     * Connections
     */
    
    AudioUnitConnection connection;
    connection.sourceAudioUnit    = syntAudioOuput.converterUnit;
    connection.sourceOutputNumber = 0;
    connection.destInputNumber    = 0;

    AudioUnitSetProperty (
                          syntAudioOuput.reverbUnit,          // connection destination
                          kAudioUnitProperty_MakeConnection,  // property key
                          kAudioUnitScope_Input,              // destination scope
                          0,                // destination element
                          &connection,                // connection definition
                          sizeof (connection)
                          );
    
    AudioUnitConnection connection2;
    connection2.sourceAudioUnit    = syntAudioOuput.reverbUnit;
    connection2.sourceOutputNumber = 0;
    connection2.destInputNumber    = 0;

    AudioUnitSetProperty (
                          syntAudioOuput.outputUnit,          // connection destination
                          kAudioUnitProperty_MakeConnection,  // property key
                          kAudioUnitScope_Input,              // destination scope
                          0,                // destination element
                          &connection2,                // connection definition
                          sizeof (connection2)
                          );
    
     
     /*
    * Stream formats
    */
    
    // Set the stream format
    CheckError(AudioUnitSetProperty(syntAudioOuput.converterUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &syntAudioDescription, sizeof(syntAudioDescription)),
               "kAudioUnitProperty_StreamFormat");


    
     AudioStreamBasicDescription absd = {0};
     UInt32 size =  sizeof(AudioStreamBasicDescription);
     AudioUnitGetProperty(syntAudioOuput.converterUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output,0, &absd, &size);
     
    printf("");
    /*
    * Reverb parameters
    */
    
    /* Show PRESETS
    CFArrayRef presets = NULL;
    UInt32 sop = sizeof(presets);
    AudioUnitGetProperty(syntAudioOuput.reverbUnit,
                               kAudioUnitProperty_FactoryPresets,
                               kAudioUnitScope_Global,
                               0,
                               &presets,
                               &sop);

    CFIndex c = CFArrayGetCount(presets);
    
    for (CFIndex i = 0; i < c; i += 1) {
        AUPreset* p1 = (AUPreset*) CFArrayGetValueAtIndex(presets, i);
        
        printf("%s\n", CFStringGetCStringPtr(p1->presetName, kCFStringEncodingUTF8));
    }
    
    
    
    CFRelease(presets);
     
    Small Room
    Medium Room
    Large Room
    Medium Hall
    Large Hall
    Plate
    Medium Chamber
    Large Chamber
    Cathedral
    Large Room 2
    Medium Hall 2
    Medium Hall 3
    Large Hall 2
     
     
    
    */
    // set the decay time at 0 Hz to 5 seconds
    //AudioUnitSetParameter(syntAudioOuput.reverbUnit, kAudioUnitScope_Global, 0, kReverb2Param_DecayTimeAt0Hz, reverbDecayTime, 0);
    
    
    
    AUPreset current;
    current.presetNumber = (SInt32)reverbPresetIndex;

    CFArrayRef presets;
    UInt32 sz = sizeof (CFArrayRef);

    if (AudioUnitGetProperty (syntAudioOuput.reverbUnit, kAudioUnitProperty_FactoryPresets,
                              kAudioUnitScope_Global, 0, &presets, &sz) == noErr)
    {
        const AUPreset* p = (const AUPreset*) CFArrayGetValueAtIndex (presets, reverbPresetIndex);
        current.presetName = p->presetName;
        CFRelease (presets);
        
        printf("Found preset: %s\n", CFStringGetCStringPtr(p->presetName, kCFStringEncodingUTF8));
    }

    AudioUnitSetProperty (syntAudioOuput.reverbUnit, kAudioUnitProperty_PresentPreset,
                          kAudioUnitScope_Global, 0, &current, sizeof (AUPreset));
    
    
    // set reverb dry wet mix
    AudioUnitSetParameter(syntAudioOuput.reverbUnit, kAudioUnitScope_Global, 0, kReverb2Param_DryWetMix, reverbWetDryMix, 0);
    /*
    * Rendercallback
    */
    
    // register render callback
    AURenderCallbackStruct input;
    input.inputProc = SyntRenderProc;
    input.inputProcRefCon = &syntAudioOuput.converterUnit;
    CheckError(AudioUnitSetProperty(syntAudioOuput.converterUnit,
                                    kAudioUnitProperty_SetRenderCallback,
                                    kAudioUnitScope_Input,
                                    0,
                                    &input,
                                    sizeof(input)),
               "AudioUnitSetProperty failed");
    
    UInt32 framesPerSlice = 4096;
    CheckError(AudioUnitSetProperty(syntAudioOuput.converterUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Input, 0, &framesPerSlice, sizeof(framesPerSlice)),
               "AudioUnitSetProperty(kAudioUnitProperty_MaximumFramesPerSlice");
    
    // initialize units
    CheckError (AudioUnitInitialize(syntAudioOuput.converterUnit),
    "Couldn't initialize converter unit");
    CheckError (AudioUnitInitialize(syntAudioOuput.reverbUnit),
    "Couldn't initialize reverb unit");
    CheckError (AudioUnitInitialize(syntAudioOuput.outputUnit),
                "Couldn't initialize output unit");
    
    // start playing
    CheckError (AudioOutputUnitStart(syntAudioOuput.outputUnit), "Couldn't start output unit");
    
    /* Code which gets an absd
    AudioStreamBasicDescription absd = {0};
    UInt32 size =  sizeof(AudioStreamBasicDescription);
    AudioUnitGetProperty(syntAudioOuput.outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &absd, &size);*/
    printf("Done");
    
}

void SyntDisposeAudioOutput() {
    if (syntAudioOuput.outputUnit != NULL) {
        AudioOutputUnitStop(syntAudioOuput.outputUnit);
        AudioUnitUninitialize(syntAudioOuput.converterUnit);
        AudioUnitUninitialize(syntAudioOuput.reverbUnit);
        AudioUnitUninitialize(syntAudioOuput.outputUnit);
        AudioComponentInstanceDispose(syntAudioOuput.outputUnit);
        AudioComponentInstanceDispose(syntAudioOuput.reverbUnit);
        AudioComponentInstanceDispose(syntAudioOuput.converterUnit);
        syntAudioOuput.outputUnit = NULL;
        syntAudioOuput.reverbUnit = NULL;
        syntAudioOuput.converterUnit = NULL;
    }
}
