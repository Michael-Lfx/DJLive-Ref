//
//  ViewController.m
//  offlinerender
//
//  Created by liumiao on 11/17/14.
//  Copyright (c) 2014 Chang Ba. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end
void CheckError(int status,char *msg)
{
    
}
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    graphSampleRate = 44100.0;
    MaxSampleTime   = 0.0;
    UInt32 category = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                                       sizeof(category),
                                       &category);
    [self initializeAUGraph];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) setupStereoStream864 {
    // The AudioUnitSampleType data type is the recommended type for sample data in audio
    // units. This obtains the byte size of the type for use in filling in the ASBD.
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    // Fill the application audio format struct's fields to define a linear PCM,
    // stereo, noninterleaved stream at the hardware sample rate.
    stereoStreamFormat864.mFormatID          = kAudioFormatLinearPCM;
    stereoStreamFormat864.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    stereoStreamFormat864.mBytesPerPacket    = bytesPerSample;
    stereoStreamFormat864.mFramesPerPacket   = 1;
    stereoStreamFormat864.mBytesPerFrame     = bytesPerSample;
    stereoStreamFormat864.mChannelsPerFrame  = 2; // 2 indicates stereo
    stereoStreamFormat864.mBitsPerChannel    = 8 * bytesPerSample;
    stereoStreamFormat864.mSampleRate        = graphSampleRate;
}
- (void)initializeAUGraph
{
    [self setupStereoStream864];
    
    // Setup the AUGraph, add AUNodes, and make connections
    // create a new AUGraph
    NewAUGraph(&mGraph);
    
    // AUNodes represent AudioUnits on the AUGraph and provide an
    // easy means for connecting audioUnits together.
    AUNode filePlayerNode;
    AUNode filePlayerNode2;
    AUNode mixerNode;
    AUNode reverbNode;
    AUNode toneNode;
    AUNode gOutputNode;
    
    // file player component
    AudioComponentDescription filePlayer_desc;
    filePlayer_desc.componentType = kAudioUnitType_Generator;
    filePlayer_desc.componentSubType = kAudioUnitSubType_AudioFilePlayer;
    filePlayer_desc.componentFlags = 0;
    filePlayer_desc.componentFlagsMask = 0;
    filePlayer_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // file player component2
    AudioComponentDescription filePlayer2_desc;
    filePlayer2_desc.componentType = kAudioUnitType_Generator;
    filePlayer2_desc.componentSubType = kAudioUnitSubType_AudioFilePlayer;
    filePlayer2_desc.componentFlags = 0;
    filePlayer2_desc.componentFlagsMask = 0;
    filePlayer2_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Create AudioComponentDescriptions for the AUs we want in the graph
    // mixer component
    AudioComponentDescription mixer_desc;
    mixer_desc.componentType = kAudioUnitType_Mixer;
    mixer_desc.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixer_desc.componentFlags = 0;
    mixer_desc.componentFlagsMask = 0;
    mixer_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Create AudioComponentDescriptions for the AUs we want in the graph
    // Reverb component
    AudioComponentDescription reverb_desc;
    reverb_desc.componentType = kAudioUnitType_Effect;
    reverb_desc.componentSubType = kAudioUnitSubType_Reverb2;
    reverb_desc.componentFlags = 0;
    reverb_desc.componentFlagsMask = 0;
    reverb_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    
    //tone component
    AudioComponentDescription tone_desc;
    tone_desc.componentType = kAudioUnitType_FormatConverter;
    //tone_desc.componentSubType = kAudioUnitSubType_NewTimePitch;
    tone_desc.componentSubType = kAudioUnitSubType_Varispeed;
    tone_desc.componentFlags = 0;
    tone_desc.componentFlagsMask = 0;
    tone_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    
    AudioComponentDescription gOutput_desc;
    gOutput_desc.componentType = kAudioUnitType_Output;
    gOutput_desc.componentSubType = kAudioUnitSubType_GenericOutput;
    gOutput_desc.componentFlags = 0;
    gOutput_desc.componentFlagsMask = 0;
    gOutput_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    //Add nodes to graph
    
    // Add nodes to the graph to hold our AudioUnits,
    // You pass in a reference to the  AudioComponentDescription
    // and get back an  AudioUnit
    AUGraphAddNode(mGraph, &filePlayer_desc, &filePlayerNode );
    AUGraphAddNode(mGraph, &filePlayer2_desc, &filePlayerNode2 );
    AUGraphAddNode(mGraph, &mixer_desc, &mixerNode );
    AUGraphAddNode(mGraph, &reverb_desc, &reverbNode );
    AUGraphAddNode(mGraph, &tone_desc, &toneNode );
    AUGraphAddNode(mGraph, &gOutput_desc, &gOutputNode);
    
    
    //Open the graph early, initialize late
    // open the graph AudioUnits are open but not initialized (no resource allocation occurs here)
    
    AUGraphOpen(mGraph);
    
    //Reference to Nodes
    // get the reference to the AudioUnit object for the file player graph node
    AUGraphNodeInfo(mGraph, filePlayerNode, NULL, &mFilePlayer);
    AUGraphNodeInfo(mGraph, filePlayerNode2, NULL, &mFilePlayer2);
    AUGraphNodeInfo(mGraph, reverbNode, NULL, &mReverb);
    AUGraphNodeInfo(mGraph, toneNode, NULL, &mTone);
    AUGraphNodeInfo(mGraph, mixerNode, NULL, &mMixer);
    AUGraphNodeInfo(mGraph, gOutputNode, NULL, &mGIO);
    
    AUGraphConnectNodeInput(mGraph, filePlayerNode, 0, reverbNode, 0);
    AUGraphConnectNodeInput(mGraph, reverbNode, 0, toneNode, 0);
    AUGraphConnectNodeInput(mGraph, toneNode, 0, mixerNode,0);
    AUGraphConnectNodeInput(mGraph, filePlayerNode2, 0, mixerNode, 1);
    AUGraphConnectNodeInput(mGraph, mixerNode, 0, gOutputNode, 0);
    
    
    UInt32 busCount   = 2;    // bus count for mixer unit input
    
    //Setup mixer unit bus count
    AudioUnitSetProperty (
                                     mMixer,
                                     kAudioUnitProperty_ElementCount,
                                     kAudioUnitScope_Input,
                                     0,
                                     &busCount,
                                     sizeof (busCount)
                                     );
    
    //Enable metering mode to view levels input and output levels of mixer
    UInt32 onValue = 1;
    AudioUnitSetProperty(mMixer,
                                    kAudioUnitProperty_MeteringMode,
                                    kAudioUnitScope_Input,
                                    0,
                                    &onValue,
                                    sizeof(onValue));
    
    // Increase the maximum frames per slice allows the mixer unit to accommodate the
    //    larger slice size used when the screen is locked.
    UInt32 maximumFramesPerSlice = 4096;
    
    AudioUnitSetProperty (
                                     mMixer,
                                     kAudioUnitProperty_MaximumFramesPerSlice,
                                     kAudioUnitScope_Global,
                                     0,
                                     &maximumFramesPerSlice,
                                     sizeof (maximumFramesPerSlice)
                                     );
    
    // set the audio data format of tone Unit
    AudioUnitSetProperty(mTone,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Global,
                         0,
                         &stereoStreamFormat864,
                         sizeof(AudioStreamBasicDescription));
    // set the audio data format of reverb Unit
    AudioUnitSetProperty(mReverb,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Global,
                         0,
                         &stereoStreamFormat864,
                         sizeof(AudioStreamBasicDescription));
    
    // set initial reverb
    AudioUnitParameterValue reverbTime = 2.5;
    AudioUnitSetParameter(mReverb, 4, kAudioUnitScope_Global, 0, reverbTime, 0);
    AudioUnitSetParameter(mReverb, 5, kAudioUnitScope_Global, 0, reverbTime, 0);
    AudioUnitSetParameter(mReverb, 0, kAudioUnitScope_Global, 0, 0, 0);
    
    AudioStreamBasicDescription     auEffectStreamFormat;
    UInt32 asbdSize = sizeof (auEffectStreamFormat);
    memset (&auEffectStreamFormat, 0, sizeof (auEffectStreamFormat ));
    
    // get the audio data format from reverb
    AudioUnitGetProperty(mReverb,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &auEffectStreamFormat,
                                    &asbdSize);
    
    
    auEffectStreamFormat.mSampleRate = graphSampleRate;
    
    // set the audio data format of mixer Unit
    AudioUnitSetProperty(mMixer,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    0,
                                    &auEffectStreamFormat, sizeof(auEffectStreamFormat));
    
    AUGraphInitialize(mGraph);
    
    [self setUpAUFilePlayer];
    [self setUpAUFilePlayer2];  
}
-(OSStatus) setUpAUFilePlayer{
    NSString *songPath = [[NSBundle mainBundle] pathForResource: @"MiAmor" ofType:@"mp3"];
    CFURLRef songURL = ( CFURLRef) [NSURL fileURLWithPath:songPath];
    
    // open the input audio file
    CheckError(AudioFileOpenURL(songURL, kAudioFileReadPermission, 0, &inputFile),
               "setUpAUFilePlayer AudioFileOpenURL failed");
    
    AudioStreamBasicDescription fileASBD;
    // get the audio data format from the file
    UInt32 propSize = sizeof(fileASBD);
    CheckError(AudioFileGetProperty(inputFile, kAudioFilePropertyDataFormat,
                                    &propSize, &fileASBD),
               "setUpAUFilePlayer couldn't get file's data format");
    
    // tell the file player unit to load the file we want to play
    CheckError(AudioUnitSetProperty(mFilePlayer, kAudioUnitProperty_ScheduledFileIDs,
                                    kAudioUnitScope_Global, 0, &inputFile, sizeof(inputFile)),
               "setUpAUFilePlayer AudioUnitSetProperty[kAudioUnitProperty_ScheduledFileIDs] failed");
    
    UInt64 nPackets;
    UInt32 propsize = sizeof(nPackets);
    CheckError(AudioFileGetProperty(inputFile, kAudioFilePropertyAudioDataPacketCount,
                                    &propsize, &nPackets),
               "setUpAUFilePlayer AudioFileGetProperty[kAudioFilePropertyAudioDataPacketCount] failed");
    
    // tell the file player AU to play the entire file
    ScheduledAudioFileRegion rgn;
    memset (&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
    rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    rgn.mTimeStamp.mSampleTime = 0;
    rgn.mCompletionProc = NULL;
    rgn.mCompletionProcUserData = NULL;
    rgn.mAudioFile = inputFile;
    rgn.mLoopCount = -1;
    rgn.mStartFrame = 0;
    rgn.mFramesToPlay = nPackets * fileASBD.mFramesPerPacket;
    
    if (MaxSampleTime < rgn.mFramesToPlay)
    {
        MaxSampleTime = rgn.mFramesToPlay;
    }
    
    CheckError(AudioUnitSetProperty(mFilePlayer, kAudioUnitProperty_ScheduledFileRegion,
                                    kAudioUnitScope_Global, 0,&rgn, sizeof(rgn)),
               "setUpAUFilePlayer1 AudioUnitSetProperty[kAudioUnitProperty_ScheduledFileRegion] failed");
    
    // prime the file player AU with default values
    UInt32 defaultVal = 0;
    
    CheckError(AudioUnitSetProperty(mFilePlayer, kAudioUnitProperty_ScheduledFilePrime,
                                    kAudioUnitScope_Global, 0, &defaultVal, sizeof(defaultVal)),
               "setUpAUFilePlayer AudioUnitSetProperty[kAudioUnitProperty_ScheduledFilePrime] failed");
    
    
    // tell the file player AU when to start playing (-1 sample time means next render cycle)
    AudioTimeStamp startTime;
    memset (&startTime, 0, sizeof(startTime));
    startTime.mFlags = kAudioTimeStampSampleTimeValid;
    
    startTime.mSampleTime = -1;
    CheckError(AudioUnitSetProperty(mFilePlayer, kAudioUnitProperty_ScheduleStartTimeStamp,
                                    kAudioUnitScope_Global, 0, &startTime, sizeof(startTime)),
               "setUpAUFilePlayer AudioUnitSetProperty[kAudioUnitProperty_ScheduleStartTimeStamp]");
    
    return noErr;  
}
-(OSStatus) setUpAUFilePlayer2{
    NSString *songPath = [[NSBundle mainBundle] pathForResource: @"500miles" ofType:@"mp3"];
    CFURLRef songURL = ( CFURLRef) [NSURL fileURLWithPath:songPath];
    
    // open the input audio file
    CheckError(AudioFileOpenURL(songURL, kAudioFileReadPermission, 0, &inputFile2),
               "setUpAUFilePlayer2 AudioFileOpenURL failed");
    
    AudioStreamBasicDescription fileASBD;
    // get the audio data format from the file
    UInt32 propSize = sizeof(fileASBD);
    CheckError(AudioFileGetProperty(inputFile2, kAudioFilePropertyDataFormat,
                                    &propSize, &fileASBD),
               "setUpAUFilePlayer2 couldn't get file's data format");
    
    // tell the file player unit to load the file we want to play
    CheckError(AudioUnitSetProperty(mFilePlayer2, kAudioUnitProperty_ScheduledFileIDs,
                                    kAudioUnitScope_Global, 0, &inputFile2, sizeof(inputFile2)),
               "setUpAUFilePlayer2 AudioUnitSetProperty[kAudioUnitProperty_ScheduledFileIDs] failed");
    
    UInt64 nPackets;
    UInt32 propsize = sizeof(nPackets);
    CheckError(AudioFileGetProperty(inputFile2, kAudioFilePropertyAudioDataPacketCount,
                                    &propsize, &nPackets),
               "setUpAUFilePlayer2 AudioFileGetProperty[kAudioFilePropertyAudioDataPacketCount] failed");
    
    // tell the file player AU to play the entire file
    ScheduledAudioFileRegion rgn;
    memset (&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
    rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    rgn.mTimeStamp.mSampleTime = 0;
    rgn.mCompletionProc = NULL;
    rgn.mCompletionProcUserData = NULL;
    rgn.mAudioFile = inputFile2;
    rgn.mLoopCount = -1;
    rgn.mStartFrame = 0;
    rgn.mFramesToPlay = nPackets * fileASBD.mFramesPerPacket;
    
    
    if (MaxSampleTime < rgn.mFramesToPlay)
    {
        MaxSampleTime = rgn.mFramesToPlay;
    }
    
    CheckError(AudioUnitSetProperty(mFilePlayer2, kAudioUnitProperty_ScheduledFileRegion,
                                    kAudioUnitScope_Global, 0,&rgn, sizeof(rgn)),
               "setUpAUFilePlayer2 AudioUnitSetProperty[kAudioUnitProperty_ScheduledFileRegion] failed");
    
    // prime the file player AU with default values
    UInt32 defaultVal = 0;
    CheckError(AudioUnitSetProperty(mFilePlayer2, kAudioUnitProperty_ScheduledFilePrime,
                                    kAudioUnitScope_Global, 0, &defaultVal, sizeof(defaultVal)),
               "setUpAUFilePlayer2 AudioUnitSetProperty[kAudioUnitProperty_ScheduledFilePrime] failed");
    
    
    // tell the file player AU when to start playing (-1 sample time means next render cycle)
    AudioTimeStamp startTime;
    memset (&startTime, 0, sizeof(startTime));
    startTime.mFlags = kAudioTimeStampSampleTimeValid;
    startTime.mSampleTime = -1;
    CheckError(AudioUnitSetProperty(mFilePlayer2, kAudioUnitProperty_ScheduleStartTimeStamp,
                                    kAudioUnitScope_Global, 0, &startTime, sizeof(startTime)),
               "setUpAUFilePlayer2 AudioUnitSetProperty[kAudioUnitProperty_ScheduleStartTimeStamp]");
    
    return noErr;  
}
- (IBAction)startRender:(id)sender{
    AudioStreamBasicDescription destinationFormat;
    memset(&destinationFormat, 0, sizeof(destinationFormat));
    destinationFormat.mChannelsPerFrame = 2;
    destinationFormat.mFormatID = kAudioFormatMPEG4AAC;
    UInt32 size = sizeof(destinationFormat);
    OSStatus result = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &destinationFormat);
    if(result) printf("AudioFormatGetProperty %ld \n", result);
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    
    
    NSString *destinationFilePath = [[NSString alloc] initWithFormat: @"%@/output.m4a", documentsDirectory];
    CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                            (CFStringRef)destinationFilePath,
                                                            kCFURLPOSIXPathStyle,
                                                            false);
    [destinationFilePath release];
    
    // specify codec Saving the output in .m4a format
    result = ExtAudioFileCreateWithURL(destinationURL,
                                       kAudioFileM4AType,
                                       &destinationFormat,
                                       NULL,
                                       kAudioFileFlags_EraseFile,
                                       &extAudioFile);
    if(result) printf("ExtAudioFileCreateWithURL %ld \n", result);
    CFRelease(destinationURL);
    
    // This is a very important part and easiest way to set the ASBD for the File with correct format.
    AudioStreamBasicDescription clientFormat;
    UInt32 fSize = sizeof (clientFormat);
    memset(&clientFormat, 0, sizeof(clientFormat));
    // get the audio data format from the Output Unit
    CheckError(AudioUnitGetProperty(mGIO,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    0,
                                    &clientFormat,
                                    &fSize),"AudioUnitGetProperty on failed");
    
    // set the audio data format of mixer Unit
    CheckError(ExtAudioFileSetProperty(extAudioFile,
                                       kExtAudioFileProperty_ClientDataFormat,
                                       sizeof(clientFormat),
                                       &clientFormat),
               "ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat failed");
    // specify codec
    UInt32 codec = kAppleHardwareAudioCodecManufacturer;
    CheckError(ExtAudioFileSetProperty(extAudioFile,
                                       kExtAudioFileProperty_CodecManufacturer,
                                       sizeof(codec),
                                       &codec),"ExtAudioFileSetProperty on extAudioFile Faild");
    
    CheckError(ExtAudioFileWriteAsync(extAudioFile, 0, NULL),"ExtAudioFileWriteAsync Failed");
    
    [self pullGenericOutput];
}
-(void)pullGenericOutput{
    AudioUnitRenderActionFlags flags = 0;
    AudioTimeStamp inTimeStamp;
    memset(&inTimeStamp, 0, sizeof(AudioTimeStamp));
    inTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    UInt32 busNumber = 0;
    UInt32 numberFrames = 512;
    inTimeStamp.mSampleTime = 0;
    int channelCount = 2;
    
    NSLog(@"Final numberFrames :%li",numberFrames);
    int totFrms = MaxSampleTime;
    while (totFrms > 0)
    {
        NSLog(@"totFrms %d",totFrms);
        if (totFrms < numberFrames)
        {
            numberFrames = totFrms;
            NSLog(@"Final numberFrames :%li",numberFrames);
        }
        else
        {
            totFrms -= numberFrames;
        }
        AudioBufferList *bufferList = (AudioBufferList*)malloc(sizeof(AudioBufferList)+sizeof(AudioBuffer)*(channelCount-1));
        bufferList->mNumberBuffers = channelCount;
        for (int j=0; j<channelCount; j++)
        {
            AudioBuffer buffer = {0};
            buffer.mNumberChannels = 1;
            buffer.mDataByteSize = numberFrames*sizeof(AudioUnitSampleType);
            buffer.mData = calloc(numberFrames, sizeof(AudioUnitSampleType));
            
            bufferList->mBuffers[j] = buffer;
            
        }
        CheckError(AudioUnitRender(mGIO,
                                   &flags,
                                   &inTimeStamp,
                                   busNumber,
                                   numberFrames,
                                   bufferList),
                   "AudioUnitRender mGIO");
        
        
        
        CheckError(ExtAudioFileWrite(extAudioFile, numberFrames, bufferList),("extaudiofilewrite fail"));
        
        inTimeStamp.mSampleTime += numberFrames;
    }
    
    [self FilesSavingCompleted];
}
-(void)FilesSavingCompleted{
    OSStatus status = ExtAudioFileDispose(extAudioFile);
    printf("OSStatus(ExtAudioFileDispose): %ld\n", status);
}
@end
