//
// MTPlayer.m
//
// AD5RX Morse Trainer
// Copyright (c) 2008 Jon Nall
// All rights reserved.
//
// LICENSE
// This file is part of AD5RX Morse Trainer.
// 
// AD5RX Morse Trainer is free software: you can redistribute it and/or
// modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
// 
// AD5RX Morse Trainer is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with AD5RX Morse Trainer.  If not, see <http://www.gnu.org/licenses/>.




#import "MTPlayer.h"
//#import "MTFifoSource.h"
//#import "MTNoiseSource.h"
//#import "MTQRMSource.h"

#include "../CoreAudioUtilityClasses/CoreAudio/PublicUtility/CAAudioBufferList.h"

///#define OFFLINE_REND
#define REVERB_EFFECT

#define CHECK_ERR(err, msg) \
if((err) != noErr)\
{\
    NSLog(@"ERROR: Error 0x%x (%d) occurred during AU operation: %@", (err), (err), (msg));\
}

FILE* mix_dump = NULL;

static const NSUInteger cwMixerElement = 0;
static const NSUInteger noiseMixerElement = 1;
static const NSUInteger baseQRMElement = 2;

@interface MTPlayer (Private)
    -(void)initGraph;
    -(void)setVolume:(AudioUnitElement)theElement withValue:(AudioUnitParameterValue)theValue;
    -(void)CWComplete:(id)object;
    -(void)textTracker:(id)object;


@end

@implementation MTPlayer

-(id)init
{
	if([super init] != nil)
	{
		[self initGraph];
		
		isStopped = YES;
		isPaused = NO;
        isPlaying = NO;
        
		cwPlayer = [[MTSourcePlayer alloc] initWithAU:cwUnit];		

#if 0
		// Setup Noise Source
        noisePlayer = [[MTSourcePlayer alloc] initWithAU:noiseUnit];
        
        MTNoiseSource* noiseSource = [[MTNoiseSource alloc] init];
        if([[NSUserDefaults standardUserDefaults] boolForKey:kPrefWhiteNoise] == YES)
        {
            [noiseSource goWhite];
        }
            
        [noiseSource reset];
        [noisePlayer setSource:noiseSource];
		
        // Setup QRM Source
		for(NSUInteger i = 0; i < kMaxQRMStations; ++i)
		{
			qrmPlayer[i] = [[MTSourcePlayer alloc] initWithAU:qrmUnit[i]];

            MTQRMSource* qrmSource = [[MTQRMSource alloc] initWithID:i];
            [qrmSource reset];
            [qrmPlayer[i] setSource:qrmSource];
		}
                
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(CWComplete:)
                                                     name:kNotifSoundPlayerComplete
                                                   object:cwPlayer];
	
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textTracker:)
                                                     name:kNotifTextWasPlayed
                                                   object:cwPlayer];
                
		[self setQRMStations:0];
		[self setNoise:0.0];
#endif
	}
	
	return self;
}

-(void)playCW:(id<MTSoundSource>)theSource
{
	isStopped = NO;
    isPaused = NO;
    isPlaying = YES;
    
    [cwPlayer setEnabled:YES];
    [cwPlayer start];
    
#ifdef OFFLINE_REND
    AudioUnitRenderActionFlags flags = 0;
    AudioTimeStamp inTimeStamp;
    memset(&inTimeStamp, 0, sizeof(AudioTimeStamp));
    inTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    UInt32 busNumber = 0;
    UInt32 numberFrames = 512;
    inTimeStamp.mSampleTime = 0;
    int channelCount = 2;
    
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *destinationFilePath = [[NSString alloc] initWithFormat: @"%@/mix.pcm", documentsDirectory];
    
    const char* dump_file = [destinationFilePath UTF8String];
    mix_dump = fopen(dump_file, "wb");
    
    for (int i = 0; i < 10000; i++) {
        
        AudioBufferList *bufferList = NULL;
#if 0   // mono
        bufferList = CAAudioBufferList::Create(1);
        
        bufferList->mBuffers[0].mData = malloc(numberFrames*sizeof(AudioUnitSampleType));
        bufferList->mBuffers[0].mDataByteSize = numberFrames*sizeof(AudioUnitSampleType);
        bufferList->mBuffers[0].mNumberChannels = 1;//streamFormat.mChannelsPerFrame;
#else   // stereo
        bufferList = CAAudioBufferList::Create(2/*streamFormat.mChannelsPerFrame*/);
        
        for (UInt32 index = 0; index < bufferList->mNumberBuffers; index++)
        {
            bufferList->mBuffers[index].mData = malloc(numberFrames*sizeof(AudioUnitSampleType));
            bufferList->mBuffers[index].mDataByteSize = numberFrames*sizeof(AudioUnitSampleType);
            bufferList->mBuffers[index].mNumberChannels = 1;
        }
#endif
        
        OSStatus error = noErr;
        error = AudioUnitRender(outputUnit,
                                &flags,
                                &inTimeStamp,
                                busNumber,
                                numberFrames,
                                bufferList);
        // usleep(5*1000);
        if (error != noErr) {
            return;
        }
        inTimeStamp.mSampleTime += numberFrames;
        
        for (int j = 0; j < numberFrames; j++) {
            //float l_val = *(float*)bufferList->mBuffers[0].mData + (2 * j);
            //float r_val = *(float*)bufferList->mBuffers[1].mData + (2 * j);
            fwrite((float*)bufferList->mBuffers[0].mData + j, 4, 1, mix_dump);
            fwrite((float*)bufferList->mBuffers[1].mData + j, 4, 1, mix_dump);
        }
        
        //fwrite(bufferList->mBuffers[0].mData, 4, numberFrames, mix_dump);
    }
    
    fclose(mix_dump);
    
#else
	OSStatus error = AUGraphStart(graph);
#endif
    
	CAShow(graph);
}	

-(BOOL)stopped
{
	return isStopped;
}

-(void)stop
{
    isPaused = NO;
    isPlaying = NO;
	isStopped = YES;
	AUGraphStop(graph);
	
	[cwPlayer stop];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifSoundPlayerComplete object:self];
}

-(BOOL)playing
{
    return isPlaying;
}

-(void)play
{
    if(![self paused])
    {
        NSLog(@"Internal Error -- Bad state in MTPlayer::play");
        // NSRunAlertPanel(@"Internal Error", @"Internal Error -- Bad state in MTPlayer::play", @"Quit", nil, nil);
        exit(1);
    }
    
    isStopped = NO;
    isPaused = NO;
    isPlaying = YES;
    
    AUGraphStart(graph);    
}

-(BOOL)paused
{
    return isPaused;
}

-(void)pause
{
    if(![self playing])
    {
        NSLog(@"Internal Error -- Bad state in MTPlayer::pause");
        // NSRunAlertPanel(@"Internal Error", @"Internal Error -- Bad state in MTPlayer::pause", @"Quit", nil, nil);
        exit(1);
    }
        
    isStopped = NO;
    isPlaying = NO;
    isPaused = YES;
    
    AUGraphStop(graph);    
}

@end

@implementation MTPlayer (Private)
-(void)initGraph
{
    OSStatus err = noErr;
    
	NewAUGraph(&graph);
	
	AudioComponentDescription cd;
	cd.componentManufacturer = kAudioUnitManufacturer_Apple;
	cd.componentFlags = 0;
	cd.componentFlagsMask = 0;
	
	// Default Output
	AUNode outputNode;
    cd.componentType = kAudioUnitType_Output;
#ifdef OFFLINE_REND
    cd.componentSubType = kAudioUnitSubType_GenericOutput;
#else
    cd.componentSubType = kAudioUnitSubType_RemoteIO;
#endif
	AUGraphAddNode(graph, &cd, &outputNode);
    
	// Mixer
	AUNode mixerNode;
	cd.componentType = kAudioUnitType_Mixer;
	cd.componentSubType = kAudioUnitSubType_MultiChannelMixer;
	AUGraphAddNode(graph, &cd, &mixerNode);
	err = AUGraphConnectNodeInput(graph, mixerNode, 0, outputNode, 0);
    
    // Reverb
    AUNode reverbUnitNode;
#ifdef REVERB_EFFECT
    cd.componentType = kAudioUnitType_Effect;
    cd.componentSubType = kAudioUnitSubType_Reverb2;
#else
    cd.componentType = kAudioUnitType_FormatConverter;
    cd.componentSubType = kAudioUnitSubType_NewTimePitch; // kAudioUnitSubType_Varispeed
#endif
    AUGraphAddNode(graph, &cd, &reverbUnitNode);
    err = AUGraphConnectNodeInput(graph, reverbUnitNode, 0, mixerNode, cwMixerElement);
    
	// CW
    AUNode cwConverterNode;
    cd.componentType = kAudioUnitType_FormatConverter;
    cd.componentSubType = kAudioUnitSubType_AUConverter;
    AUGraphAddNode(graph, &cd, &cwConverterNode);
    err = AUGraphConnectNodeInput(graph, cwConverterNode, 0, reverbUnitNode, cwMixerElement);
    
	AUNode cwNode;
	cd.componentType = kAudioUnitType_Generator;
	cd.componentSubType = kAudioUnitSubType_ScheduledSoundPlayer;
	AUGraphAddNode(graph, &cd, &cwNode);
	AUGraphConnectNodeInput(graph, cwNode, 0, cwConverterNode, 0);
    
	AUGraphOpen(graph);
	
    AUGraphNodeInfo(graph, cwConverterNode, 0, &cwConverterUnit);
    AUGraphNodeInfo(graph, reverbUnitNode, 0, &reverbUnit);
	AUGraphNodeInfo(graph, cwNode, 0, &cwUnit);
	AUGraphNodeInfo(graph, mixerNode, 0, &mixerUnit);
	AUGraphNodeInfo(graph, outputNode, 0, &outputUnit);
    
#ifdef REVERB_EFFECT
    err = AudioUnitSetParameter(reverbUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, 100.f, 0);
#else
    err = AudioUnitSetParameter(reverbUnit, kVarispeedParam_PlaybackRate, kAudioUnitScope_Global, 0, 4.0f, 0);
#endif
	
	AudioStreamBasicDescription aa;
	UInt32 size = sizeof(aa);
	err = AudioUnitGetProperty(cwUnit,
                                               kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &aa, &size);
	CHECK_ERR(err, @"Getting StreamFormat Property from cwUnit");
	
	// Get Info from cwUnit and modify the channels to be 1 and the correct
    // sample rate. Then apply that to everything else.
	aa.mChannelsPerFrame = 2;
    aa.mSampleRate = kSampleRate;
    
	err = AudioUnitSetProperty(cwUnit, 
							   kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &aa, size);
	CHECK_ERR(err, @"Setting StreamFormat Property for cwUnit/Output");
    
	err = AudioUnitSetProperty(cwConverterUnit, 
							   kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &aa, size);
	CHECK_ERR(err, @"Setting StreamFormat Property for cwConverterUnit/Input");
    
    err = AudioUnitSetProperty(reverbUnit,
                               kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &aa, size);
    CHECK_ERR(err, @"Setting StreamFormat Property for cwConverterUnit/Input");

	err = AudioUnitSetProperty(outputUnit, 
							   kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &aa, size);
	CHECK_ERR(err, @"Setting StreamFormat Property for outputUnit/Input");
	
	AUGraphInitialize(graph);
    // CAShow(graph);
    
}

-(void)setVolume:(AudioUnitElement)theElement withValue:(AudioUnitParameterValue)theValue
{
#if 0
	OSStatus err = AudioUnitSetParameter(mixerUnit, kStereoMixerParam_Volume, kAudioUnitScope_Input, theElement, theValue, 0);
	
	NSString* errMsg = [NSString stringWithFormat:
						@"Setting volume of mixer input %d to %f", theElement, theValue];
	CHECK_ERR(err, errMsg);
#endif
}


-(void)CWComplete:(id)object
{
    NSNotification* notification = object;
	NSLog(@"CW COMPLETE! [%@]", [[notification object] name]);
	
#if 0
	if(![self stopped])
	{
		[self stop];
	}
#endif
}

-(void)textTracker:(id)object
{
    // Re-Post for UI objects that don't have access to SoundPlayers
    NSNotification* notification = object;
    [[NSNotificationCenter defaultCenter] postNotificationName:[notification name]
                                                        object:self
                                                      userInfo:[notification userInfo]];
}

@end
