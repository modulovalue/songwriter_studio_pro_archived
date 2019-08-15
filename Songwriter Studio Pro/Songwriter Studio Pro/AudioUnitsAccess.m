#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>
#import <AVFoundation/AVFoundation.h>
#import "SongwriterStudioPro-Swift.h"
#import "Songwriter Studio Pro-Bridging-Header.h"
#include <mach/mach_time.h>
#include <stdio.h>
#include <math.h>

//const int LOG_N = 9; // Typically this would be at least 10 (i.e. 1024pt FFTs)
//const int N = 1 << LOG_N;

bool playing = false;

typedef struct {
    AudioUnit rioUnit;
    AudioStreamBasicDescription asbd;
} EffectState;

EffectState effectState;

Playlist* mPlaylist;

int speakerOutput;
int recordOutput;

FFTSetup fftSetup;

static void checkError(OSStatus error, const char *operation) {
    if(error == noErr) return;
    char errorString[20];
    // See if it appears to be a 4-char-code
    *(UInt32 *) (errorString + 1) = CFSwapInt32HostToBig(error);
    if(isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else {
        // No, format it as an integer
        sprintf(errorString, "%d", (int)error);
    }
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
}


static OSStatus InputModulatingRenderCallback (void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {

    Float32 *samplesArray = malloc(sizeof(Float32) * inNumberFrames);
    EffectState *effectState = (EffectState*) inRefCon;

    // Just copy samples
    checkError(AudioUnitRender(effectState->rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData), "Couldn't render from RemoteIO unit");

    // Walk the samples
    SInt16 sample = 0;
    UInt32 bytesPerChannel = effectState->asbd.mBytesPerFrame / effectState->asbd.mChannelsPerFrame;

    Float32 const *samplesPlayback = [mPlaylist pullSamplesWithSize:inNumberFrames];

    for (int bufCount = 0; bufCount < ioData->mNumberBuffers; bufCount++) {
        AudioBuffer buf = ioData->mBuffers[bufCount];
        int currentFrame = 0;
        while ( currentFrame < inNumberFrames ) {


            for (int currentChannel = 0; currentChannel < buf.mNumberChannels; currentChannel++) {
                memcpy(&sample, buf.mData + (currentFrame * effectState->asbd.mBytesPerFrame) + (currentChannel * bytesPerChannel), sizeof(SInt16));
                Float32 recordingOut = 0;
                switch (recordOutput) {
                    case 0: // mute
                        recordingOut = 0;
                        break;
                    case 1: // mic
                        recordingOut = (Float32) sample / (Float32) SHRT_MAX;
                        break;
                    case 2: // recording
                        recordingOut = samplesPlayback[currentFrame];
                        break;
                    case 3: // recording and mic
                        recordingOut = samplesPlayback[currentFrame];
                        recordingOut += (Float32) sample / (Float32) SHRT_MAX;
                        break;
                    default:
                        break;
                }
                samplesArray[currentFrame] = recordingOut;
            }

//            vDSP_fft_zrip(fftSetup, &recordingOut, 1, LOG_N, FFT_FORWARD);
//            vDSP_fft_zrip(fftSetup, &recordingOut, 1, LOG_N, FFT_INVERSE);

            for (int currentChannel = 0; currentChannel < buf.mNumberChannels; currentChannel++) {
                memcpy(&sample, buf.mData + (currentFrame * effectState->asbd.mBytesPerFrame) + (currentChannel * bytesPerChannel), sizeof(SInt16));
                Float32 speakerOut = 0;
                switch (speakerOutput) {
                    case 0: // mute
                        speakerOut = 0;
                        break;
                    case 1: // mic
                        speakerOut = (Float32) sample / (Float32) SHRT_MAX;
                        break;
                    case 2: // recording
                        speakerOut = samplesPlayback[currentFrame];
                        break;
                    case 3: // recording and mic
                        speakerOut = samplesPlayback[currentFrame];
                        speakerOut += (Float32) sample / (Float32) SHRT_MAX;
                        break;
                    default:
                        break;
                }
                sample = (Float32) SHRT_MAX * speakerOut;
                memcpy(buf.mData + (currentFrame * effectState->asbd.mBytesPerFrame) + (currentChannel * bytesPerChannel), &sample, sizeof(SInt16));
            }

            currentFrame++;
        }
        if (mPlaylist.firstPull > 0) {
            mPlaylist.firstPull -= 1;
        } else {
            [mPlaylist pushSamplesWithSamples:samplesArray size:inNumberFrames];
        }
    }

    free(samplesArray);
    return noErr;
}

void startSample(Playlist* playlist) {

//    if (fftSetup == NULL) {
//        fftSetup = vDSP_create_fftsetup(LOG_N, kFFTRadix2);
//    }

    mPlaylist = playlist;
    if(playing == false) {
        playing = true;

        // Describe audio component
        AudioComponentDescription acd;
        acd.componentType           = kAudioUnitType_Output;
        acd.componentSubType        = kAudioUnitSubType_RemoteIO;
        acd.componentManufacturer   = kAudioUnitManufacturer_Apple;
        acd.componentFlags          = 0;
        acd.componentFlagsMask      = 0;

        // Get component
        AudioComponent rioComponent = AudioComponentFindNext(NULL, &acd);
        checkError(AudioComponentInstanceNew(rioComponent, &effectState.rioUnit), "Coundn't get RIO unit instance");

        // Enable IO for playback
        UInt32 flag = 1;
        AudioUnitElement kOutputBus = 0;
        checkError(AudioUnitSetProperty(effectState.rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, kOutputBus, &flag, sizeof(flag)), "Couldn't enable RIO output");
        // Enable IO for recording
        AudioUnitElement kInputBus = 1;
        checkError(AudioUnitSetProperty(effectState.rioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, kInputBus, &flag, sizeof(flag)), "Couldn't enable RIO input");

//      get hardware samplerate
//        Float64 hardwareSampleRate; UInt32 propSize = sizeof (hardwareSampleRate); CheckError(AudioSessionGetProperty( kAudioSessionProperty_CurrentHardwareSampleRate, &propSize, &hardwareSampleRate), "Couldn't get hardwareSampleRate"); NSLog (@"hardwareSampleRate = %f", hardwareSampleRate);

        effectState.asbd.mSampleRate          = [mPlaylist getSampleRate];
        effectState.asbd.mFormatID            = kAudioFormatLinearPCM;
        effectState.asbd.mFormatFlags         = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked | kAudioFormatFlagsNativeEndian;
        effectState.asbd.mFramesPerPacket     = 1;
        effectState.asbd.mBytesPerPacket      = 2;
        effectState.asbd.mBytesPerFrame       = 2;
        effectState.asbd.mChannelsPerFrame    = 1;
        effectState.asbd.mBitsPerChannel      = 16;
//        effectState.asbd.mReserved            = 0;

        // Apply format
        checkError(AudioUnitSetProperty(effectState.rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, kInputBus, &effectState.asbd, sizeof(effectState.asbd)), "Couldn't set the ASBD for RIO on output scrope/bus 1");
        checkError(AudioUnitSetProperty(effectState.rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, kOutputBus, &effectState.asbd, sizeof(effectState.asbd)), "Coudn't set the ASBD for RIO on input scope/bus 0");

// ---------------------------------------------

        // Set output callback
        AURenderCallbackStruct callbackStruct;
        callbackStruct.inputProc = InputModulatingRenderCallback;
        callbackStruct.inputProcRefCon = &effectState;

//        checkError(AudioQueueNewInput(&effectState.asbd, InputModulatingRenderCallback, &effectState, NULL, NULL, 0, &callbackStruct), "AudioQueueNewInput failed");
        
        checkError(AudioUnitSetProperty(effectState.rioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, kOutputBus, &callbackStruct, sizeof(callbackStruct)), "Couldn't set RIO's render callback on bus 0");

        // start rio unit
        
        checkError(AudioUnitInitialize(effectState.rioUnit), "Couldn't initialize the RIO unit");
        checkError(AudioOutputUnitStart(effectState.rioUnit), "Couldn't start the RIO unit");
        
    }
}

void initSampling() {
    // SETTING THE OUTPUT TO THE IPHONE SPEAKER
    AVAudioSession *session = [AVAudioSession sharedInstance];

    BOOL success;
    NSError *error;
    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions: AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    if (!success) {
        NSLog(@"AVAudioSession error setting category:%@",error);
    }
}

void stopSample() {
    if(playing == true) {
        playing = false;
//        AudioOutputUnitStop(effectState.rioUnit);
//        AudioUnitUninitialize(effectState.rioUnit);
        AudioComponentInstanceDispose(effectState.rioUnit);
    } else {
        printf("\n Cant't stop, not playing \n");
    }
}

void setSpeakerState(int state) {
    speakerOutput = state;
}

void setRecordState(int state) {
    recordOutput = state;
}
