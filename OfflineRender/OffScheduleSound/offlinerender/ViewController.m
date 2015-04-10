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
void CheckError(OSStatus error, const char *operation) {
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
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    graphSampleRate = 44100.0;
//    MaxSampleTime   = 0.0;
//    UInt32 category = kAudioSessionCategory_MediaPlayback;
//    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
//                                       sizeof(category),
//                                       &category);
    
    
    // [self initializeAUGraph];
    
    player = [[MTPlayer alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#if 0
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
    cwPlayer = [[MTSourcePlayer alloc] initWithAU:mFilePlayer];
    
    [self setupStereoStream864];
    
    // Setup the AUGraph, add AUNodes, and make connections
    // create a new AUGraph
    NewAUGraph(&mGraph);
    
    // AUNodes represent AudioUnits on the AUGraph and provide an
    // easy means for connecting audioUnits together.
    AUNode filePlayerNode;
    AUNode converterNode;
    AUNode mixerNode;
    AUNode gOutputNode;
    
    
    AudioComponentDescription gOutput_desc;
    gOutput_desc.componentType = kAudioUnitType_Output;
    gOutput_desc.componentSubType = kAudioUnitSubType_GenericOutput;
    gOutput_desc.componentFlags = 0;
    gOutput_desc.componentFlagsMask = 0;
    gOutput_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    CheckError(AUGraphAddNode(mGraph, &gOutput_desc, &gOutputNode), "add gOutputNode");
    
    // Create AudioComponentDescriptions for the AUs we want in the graph
    // mixer component
    AudioComponentDescription mixer_desc;
    mixer_desc.componentType = kAudioUnitType_Mixer;
    mixer_desc.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixer_desc.componentFlags = 0;
    mixer_desc.componentFlagsMask = 0;
    mixer_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    CheckError(AUGraphAddNode(mGraph, &mixer_desc, &mixerNode ), "add mixerNode");
    CheckError(AUGraphConnectNodeInput(mGraph, mixerNode, 0, gOutputNode, 0), "connect mixerNode->gOutputNode");
    
    // convert desc
    AudioComponentDescription convert_desc;
    convert_desc.componentType = kAudioUnitType_FormatConverter;
    convert_desc.componentSubType = kAudioUnitSubType_AUConverter;
    convert_desc.componentFlags = 0;
    convert_desc.componentFlagsMask = 0;
    convert_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    CheckError(AUGraphAddNode(mGraph, &convert_desc, &converterNode), "add converterNode");
    CheckError(AUGraphConnectNodeInput(mGraph, converterNode, 0, mixerNode, cwMixerElement), "connect converterNode->mixerNode");
    
    // file player component
    AudioComponentDescription filePlayer_desc;
    filePlayer_desc.componentType = kAudioUnitType_Generator;
    filePlayer_desc.componentSubType = kAudioUnitSubType_ScheduledSoundPlayer/*kAudioUnitSubType_AudioFilePlayer*/;
    filePlayer_desc.componentFlags = 0;
    filePlayer_desc.componentFlagsMask = 0;
    filePlayer_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    CheckError(AUGraphAddNode(mGraph, &filePlayer_desc, &filePlayerNode), "add filePlayerNode");
    CheckError(AUGraphConnectNodeInput(mGraph, filePlayerNode, 0, converterNode, 0), "connect converterNode->mixerNode");
    
    AUGraphOpen(mGraph);
    
    //Reference to Nodes
    // get the reference to the AudioUnit object for the file player graph node
    AUGraphNodeInfo(mGraph, converterNode, 0, &mConvert);
    AUGraphNodeInfo(mGraph, filePlayerNode, NULL, &mFilePlayer);
    AUGraphNodeInfo(mGraph, mixerNode, NULL, &mMixer);
    AUGraphNodeInfo(mGraph, gOutputNode, NULL, &mGIO);

    
    AudioStreamBasicDescription aa;
    UInt32 size = sizeof(aa);
    CheckError(AudioUnitGetProperty(mFilePlayer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &aa, &size), "Getting StreamFormat Property from cwUnit");
    
    // Get Info from cwUnit and modify the channels to be 1 and the correct
    // sample rate. Then apply that to everything else.
    
#if 0
    // Get Info from cwUnit and modify the channels to be 1 and the correct
    // sample rate. Then apply that to everything else.
    aa.mChannelsPerFrame = 1;
    aa.mSampleRate = kSampleRate;
#endif
    
    CheckError(AudioUnitSetProperty(mFilePlayer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &aa, size), "Setting StreamFormat Property for cwUnit/Output");
    
    CheckError(AudioUnitSetProperty(mConvert, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &aa, size), "Setting StreamFormat Property for cwConverterUnit/Input");
    
    
    
    CheckError(AudioUnitSetProperty(mGIO, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &aa, size), "Setting StreamFormat Property for outputUnit/Input");
    
    CheckError(AUGraphInitialize(mGraph), "AUGraphInitialize");
}
#endif

- (IBAction)startRender:(id)sender{
    
    [self startSending];
    // [self pullGenericOutput];
    // CheckError(AUGraphStart(mGraph), "AUGraphStart");
}

-(void)startSending
{
    [player stop];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSUInteger baseFreq = [defaults integerForKey:kPrefTonePitch];
    NSUInteger actualWPM = [defaults integerForKey:kPrefActualWPM];
    NSUInteger effectiveWPM = [defaults integerForKey:kPrefEffectiveWPM];
    NSString* phrase = [defaults stringForKey:kPrefWPMPhrase];
    NSUInteger minutes = [defaults integerForKey:kPrefMinutesOfCopy];
    
#if 0
    TextAnalysis analysis = [MTTimeUtils analyzeText:phrase
                                       withActualWPM:actualWPM
                                    withEffectiveWPM:effectiveWPM];
    
    NSUInteger numQRMStations = [defaults integerForKey:kPrefNumQRMStations];
    
    const double noiseLevel = [defaults doubleForKey:kPrefNoiseLevel];
    const double signalStrength = [defaults doubleForKey:kPrefSignalStrength];
    
    // Create correct sound source
    id<MTSoundSource> soundSource = nil;
    {
        const NSUInteger type = [defaults integerForKey:kPrefSourceType];
        switch(type)
        {
            case kSourceTypeCustom:
            {
                NSArray* chars = [defaults arrayForKey:kPrefCharSet];
                soundSource = [[MTRandomCWSource alloc] initWithCharset:chars
                                                          withFrequency:baseFreq
                                                         withSampleRate:kSampleRate
                                                          withAmplitude:signalStrength
                                                           withAnalysis:analysis];
                break;
            }
            case kSourceTypeURL:
            {
                NSString* textURLString = [defaults stringForKey:kPrefTextFile];
                
                if(textURLString == nil)
                {
                    // TBD: Alert
                    NSBeep();
                    NSLog(@"Internal ERROR -- option should have been disabled");
                }
                else
                {
                    NSURL* textURL = [NSURL URLWithString:textURLString];
                    soundSource = [[MTURLSource alloc] initWithURL:textURL
                                                     withFrequency:baseFreq
                                                    withSampleRate:kSampleRate
                                                     withAmplitude:signalStrength
                                                      withAnalysis:analysis];
                }
                break;
            }
            default:
            {
                NSLog(@"Internal ERROR: Unexpected source type: %lu", (unsigned long)type);
            }
        }
    }
    
    if(soundSource == nil)
    {
        // Don't play anything -- an error occurred and the subsystem should
        // have alerted the user.
        return;
    }
    
    //[soundSource dumpAU:@"/Users/nall/data.au"];
    
    [player setQRMStations:numQRMStations];
    [player setNoise:noiseLevel];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textTracker:)
                                                 name:kNotifTextWasPlayed
                                               object:player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cwComplete:)
                                                 name:kNotifSoundPlayerComplete
                                               object:player];
#endif
    [player playCW:nil];
    // [self pullGenericOutput];
#if 0
    {
        NSInvocationOperation* theOp = [[NSInvocationOperation alloc]
                                        initWithTarget:self
                                        selector:@selector(manageSessionTime:)
                                        object:[NSNumber numberWithUnsignedInt:minutes]];
        
        [[MTOperationQueue operationQueue] addOperation:theOp];		
    }
#endif
}

-(void)pullGenericOutput{
    AudioUnitRenderActionFlags flags = kAudioUnitRenderAction_OutputIsSilence;
    AudioTimeStamp inTimeStamp;
    memset(&inTimeStamp, 0, sizeof(AudioTimeStamp));
    inTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    UInt32 busNumber = 0;
    UInt32 numberFrames = 512;
    inTimeStamp.mSampleTime = 0;
    int channelCount = 2;
    
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
    while (1) {
        CheckError(AudioUnitRender(mGIO,
                                   &flags,
                                   &inTimeStamp,
                                   busNumber,
                                   numberFrames,
                                   bufferList),
                   "AudioUnitRender mGIO");
    }
    
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
        
        
        inTimeStamp.mSampleTime += numberFrames;
    }
    
    [self FilesSavingCompleted];
}

-(void)FilesSavingCompleted{
    // OSStatus status = ExtAudioFileDispose(extAudioFile);
    // printf("OSStatus(ExtAudioFileDispose): %ld\n", status);
}
@end

