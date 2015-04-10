

#import "CaptureSessionController.h"

static OSStatus PushCurrentInputBufferIntoAudioUnit(void                       *inRefCon,
													AudioUnitRenderActionFlags *ioActionFlags,
													const AudioTimeStamp       *inTimeStamp,
													UInt32						inBusNumber,
													UInt32						inNumberFrames,
													AudioBufferList            *ioData);

@implementation CaptureSessionController

@synthesize reverbValue=reverbValue_;

#pragma mark ======== Setup and teardown methods =========

- (id)init
{
	self = [super init];
	
	if (self) {
        NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSArray  *paths1 = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *documentsDirectory1 = [paths1 objectAtIndex:0];
        NSString *destinationFilePath = [NSString stringWithFormat: @"%@/AudioRecording.aif", documentsDirectory];
        NSString *destinationFilePath1 = [NSString stringWithFormat: @"%@/AudioRecording1.aif", documentsDirectory1];
        _outputFile = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)destinationFilePath, kCFURLPOSIXPathStyle, false);
        _outputFile1 = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)destinationFilePath1, kCFURLPOSIXPathStyle, false);
    
        [self registerForNotifications];
	}
	
	return self;
}

- (BOOL)setupCaptureSession
{    
	// Find the current default audio input device
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    if (audioDevice && audioDevice.connected) {
        // Get the device name
        NSLog(@"Audio Device Name: %@", audioDevice.localizedName);
    }
	// Create the capture session
	captureSession = [[AVCaptureSession alloc] init];
	
	// Create and add a device input for the audio device to the session
    NSError *error = nil;
	captureAudioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    
    if ([captureSession canAddInput: captureAudioDeviceInput]) {
        [captureSession addInput:captureAudioDeviceInput];
    }
    // Create and add a AVCaptureAudioDataOutput object to the session
    captureAudioDataOutput = [AVCaptureAudioDataOutput new];
    
    if ([captureSession canAddOutput:captureAudioDataOutput]) {
        [captureSession addOutput:captureAudioDataOutput];
    }
    // Create a serial dispatch queue and set it on the AVCaptureAudioDataOutput object
    dispatch_queue_t audioDataOutputQueue = dispatch_queue_create("AudioDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    
    [captureAudioDataOutput setSampleBufferDelegate:self queue:audioDataOutputQueue];
    dispatch_release(audioDataOutputQueue);
	
#pragma - graph
    // AVFoundationは現在AVCaptureAudioDataOutputdoesのアウトプットフォーマットを設定する方法を提供していません。
    // それ故OSXとは違い、あなたがディレイユニットを単に使用したりAVCaptureAudioDataOutputを持つ場合、サンプルを返します、ディレイユニットがセッティングメソッドを使って摂取できる方法で。iosではコンバーターユニットを使う必要があります、グラフ中のディレイユニットに沿って。我々はグラフを開始停止しないこと、そしてアウトプットユニットを使わないことに気を止めてください。
    //我々がやっていることは二つのユニットをつなぎ、コールバックをよんだときディレイを引き出す、という事です。
    //選択した場合、現在のAVCaptureAudioDataOutput形式でデータをコンバータへ配信し、ディレイの為にフォーマットを変換し、そして我々が録音するため、アウトプットのバッファリストにデータを配信したい処理を実行します。
    
	// Create an AUGraph of the converter audio unit and the delay effect audio unit, the resulting effect is added to the audio when it is written to the file

    AUNode delayNode;
    AUNode reverbNode; //
    AUNode converterNode;
    AUNode genericOutNode;
    AUNode mixerNode;
    
    
    // create a new AUGraph
	OSStatus err = NewAUGraph(&auGraph);
    if (err) { printf("NewAUGraph Failed! %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }
    
    // delay effect
    CAComponentDescription delay_EffectAudioUnitDescription(kAudioUnitType_Effect,
                                                            kAudioUnitSubType_Delay,
                                                            kAudioUnitManufacturer_Apple);
    //reverb
    CAComponentDescription reverb_desc(kAudioUnitType_Effect,
                                       kAudioUnitSubType_Reverb2,
                                       kAudioUnitManufacturer_Apple);
    // converter
    CAComponentDescription converter_desc(kAudioUnitType_FormatConverter,
                                          kAudioUnitSubType_AUConverter,
                                          kAudioUnitManufacturer_Apple);
    // genericOut
    CAComponentDescription genericOut_desc(kAudioUnitType_Output,
                                         kAudioUnitSubType_GenericOutput,
                                         kAudioUnitManufacturer_Apple
                                         );
    CAComponentDescription mixer_desc(kAudioUnitType_Mixer,
                                      kAudioUnitSubType_MultiChannelMixer,
                                      kAudioUnitManufacturer_Apple);
    
    // add nodes to graph
    err = AUGraphAddNode(auGraph,
                         &delay_EffectAudioUnitDescription,
                         &delayNode);
    if (err) { printf("AUGraphNewNode 2 result %lu %4.4s\n", (unsigned long)err, (char*)&err); return NO; }
    err = AUGraphAddNode(auGraph,
                         &reverb_desc,
                         &reverbNode);
    if (err) { printf("AUGraphNewNode 0 result %lu %4.4s\n", (unsigned long)err, (char*)&err); return NO; }
    err = AUGraphAddNode(auGraph,
                         &converter_desc,
                         &converterNode);
	if (err) { printf("AUGraphNewNode 3 result %lu %4.4s\n", (unsigned long)err, (char*)&err); return NO; }
    err = AUGraphAddNode(auGraph,
                         &genericOut_desc,
                         &genericOutNode);
    if (err) { printf("AUGraphNewNode 0 result %lu %4.4s\n", (unsigned long)err, (char*)&err); return NO; }
    err = AUGraphAddNode(auGraph,
                         &mixer_desc,
                         &mixerNode);
    if (err) { printf("AUGraphNewNode 0 result %lu %4.4s\n", (unsigned long)err, (char*)&err); return NO; }
    // connect a node's output to a node's input
    // au converter -> reverb -> delay ->output
    
    err = AUGraphConnectNodeInput(auGraph, converterNode, 0, mixerNode, 0);
	if (err) { printf("AUGraphConnectNodeInput result %lu %4.4s\n", (unsigned long)err, (char*)&err); return NO; }
//    err = AUGraphConnectNodeInput(auGraph, genericOutNode, 0, mixerNode, 1);
//    if (err) { printf("AUGraphConnectNodeInput result %lu %4.4s\n", (unsigned long)err, (char*)&err); return NO; }
    err = AUGraphConnectNodeInput(auGraph, mixerNode, 0, reverbNode, 0);
    if (err) { printf("AUGraphConnectNodeInput result %lu %4.4s\n", (unsigned long)err, (char*)&err); return NO; }
	err = AUGraphConnectNodeInput(auGraph, reverbNode, 0, delayNode, 0);
    if (err) { printf("AUGraphConnectNodeInput result %lu %4.4s\n", (unsigned long)err, (char*)&err); return NO; }
    
    // open the graph -- オーディオユニットを開きますが、初期化はしません。(no resource allocation occurs here)
	err = AUGraphOpen(auGraph);
	if (err) { printf("AUGraphOpen result %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }
	
    // 登録したノードからユニットのインスタンスを得ます。
    err = AUGraphNodeInfo(auGraph, converterNode, NULL, &converterAudioUnit);
    if (err) { printf("AUGraphNodeInfo result %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }
    err = AUGraphNodeInfo(auGraph, delayNode, NULL, &delayAudioUnit);
    if (err) { printf("AUGraphNodeInfo result %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }
    err = AUGraphNodeInfo(auGraph,
                          reverbNode,
                          NULL,
                          &reverbUnit);
    if (err) { printf("AUGraphNodeInfo result %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }
    err = AUGraphNodeInfo(auGraph,
                          genericOutNode,
                          NULL,
                          &genericOutUnit);
    if (err) { printf("AUGraphNodeInfo result %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err);
        return NO; }
    err = AUGraphNodeInfo(auGraph,
                          mixerNode,
                          NULL,
                          &mixerUnit);
    if (err) { printf("AUGraphNodeInfo result %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err);
        return NO; }
#pragma - callback to Node
    // コンバーターユニットのインプットにコールバックをセットします。オーディオアウトプットのキャプチャーから受け取ったオーディオバッファーを供給します。
    //Set a callback on the converter audio unit that will supply the audio buffers received from the capture audio data output
    AURenderCallbackStruct renderCallbackStruct;
    renderCallbackStruct.inputProc = PushCurrentInputBufferIntoAudioUnit;
    renderCallbackStruct.inputProcRefCon = (__bridge void *)self; //ARCが有効な場合、CFStringRefのようなC言語のオブジェクトから、Objective-Cのオブジェクトにキャストするには__bridgeキャストを行う必要があります。
    
    err = AUGraphSetNodeInputCallback(auGraph,
                                      converterNode,
                                      0, //input number
                                      &renderCallbackStruct);
    if (err) { printf("AUGraphSetNodeInputCallback result %ld %08X %4.4s\n", (long)err, (unsigned int)err, (char*)&err); return NO; }
	
    // add an observer for the interupted property, we simply log the result
    [captureSession addObserver:self forKeyPath:@"interrupted" options:NSKeyValueObservingOptionNew context:nil];
    [captureSession addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:nil];
    
	// Start the capture session - This will cause the audio data output delegate method didOutputSampleBuffer
    // to be called for each new audio buffer recieved from the input device
	[self startCaptureSession];
    
    return YES;
}

// if we need to we call this to dispose of the previous capture session
// and create a new one, add our input and output and go
- (BOOL)resetCaptureSession
{
    if (captureSession) {
        [captureSession removeObserver:self forKeyPath:@"interrupted" context:nil];
        [captureSession removeObserver:self forKeyPath:@"running" context:nil];
    
        [captureSession release];
        captureSession = nil;
    }
    
    // Create the capture session
	captureSession = [[AVCaptureSession alloc] init];
    
    if ([captureSession canAddInput: captureAudioDeviceInput]) {
        [captureSession addInput:captureAudioDeviceInput];
    }
    if ([captureSession canAddOutput:captureAudioDataOutput]) {
        [captureSession addOutput:captureAudioDataOutput];
    }
    // add an observer for the interupted property, we simply log the result
    [captureSession addObserver:self forKeyPath:@"interrupted" options:NSKeyValueObservingOptionNew context:nil];
    [captureSession addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:nil];
    
    return YES;
}

// teardown
- (void)dealloc
{
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:UIApplicationWillResignActiveNotification
//                                                  object:nil];
//    
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:UIApplicationDidBecomeActiveNotification
//                                                  object:nil];
    
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionRouteChangeNotification
                                               object:[AVAudioSession sharedInstance]];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVCaptureSessionRuntimeErrorNotification
                                               object:nil];
    
    [captureSession removeObserver:self forKeyPath:@"interrupted" context:nil];
	[captureSession removeObserver:self forKeyPath:@"running" context:nil];
    
    [captureSession release];
	[captureAudioDeviceInput release];
    [captureAudioDataOutput setSampleBufferDelegate:nil queue:NULL];
	[captureAudioDataOutput release];
	
	if (_outputFile) { CFRelease(_outputFile); _outputFile = NULL; }
    if (_outputFile1) { CFRelease(_outputFile1); _outputFile1= NULL; }
	
	if (extAudioFile)
        ExtAudioFileDispose(extAudioFile);
    if (extAudioFile1)
        ExtAudioFileDispose(extAudioFile1);
    
	if (auGraph) {
		if (didSetUpAudioUnits)
			AUGraphUninitialize(auGraph);
		DisposeAUGraph(auGraph);
	}
    
    if (currentInputAudioBufferList) free(currentInputAudioBufferList);
    if (outputBufferList) delete outputBufferList;
	
	[super dealloc];
}

#pragma mark ======== Audio capture methods =========

/*
 AVCaptureSessionによってキャプチャーされたフレームを含むCMSampleBufferRefオブジェクトを受信したときにAVCaptureAudioDataOutputによって呼ばれます。
 それぞれのCMSampleBufferRefはエンコードされたマルチフレームをデフォルトフォーマットで保有しています。これがすべての処理が行われる場所です。
 グラフとフォーマットの初期化と設定をして初めて,継続的な供給されるオーディオのレンダリングとが行われ、録音する場合は手動で、ファイルへの書き出しが行われます
*/
//すこし長いがキャプチャーしている間ずっと呼ばれている関数

- (void)captureOutput:(AVCaptureOutput *)captureOutput
        didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
	OSStatus err = noErr;
	
#pragma - get and set the Format
    // Get the sample buffer's AudioStreamBasicDescription which will be used to set the input format of the audio unit and ExtAudioFile
    //以下三行はCMSampleBufferRefのstreamBasicDescriptionを取り出す一連の動作です
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    CAStreamBasicDescription sampleBufferASBD(*CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription));
    if (kAudioFormatLinearPCM != sampleBufferASBD.mFormatID) { NSLog(@"Bad format or bogus ASBD!"); return; }
    
    if ((sampleBufferASBD.mChannelsPerFrame != currentInputASBD.mChannelsPerFrame) || (sampleBufferASBD.mSampleRate != currentInputASBD.mSampleRate)) {
        NSLog(@"AVCaptureAudioDataOutput Audio Format:");
        sampleBufferASBD.Print();
        /* 
         Although in iOS AVCaptureAudioDataOutput as of iOS 6 will output 16-bit PCM only by default, the sample rate will depend on the hardware and the
         current route and whether you've got any 30-pin audio microphones plugged in and so on. By default, you'll get mono and AVFoundation will request 44.1 kHz,
         but if the audio route demands a lower sample rate, AVFoundation will deliver that instead. Some 30-pin devices present a stereo stream,
         in which case AVFoundation will deliver stereo. If there is a change for input format after initial setup, the audio units receiving the buffers needs
         to be reconfigured with the new format. This also must be done when a buffer is received for the first time.
        */
        currentInputASBD = sampleBufferASBD;
        currentRecordingChannelLayout = (AudioChannelLayout *)CMAudioFormatDescriptionGetChannelLayout(formatDescription, NULL);
        
        if (didSetUpAudioUnits) { //didSetUpAudioUnitsはデフォルトではNO
            // The audio units were previously set up, so they must be uninitialized now
            err = AUGraphUninitialize(auGraph);
            NSLog(@"AUGraphUninitialize failed (%ld)", (long)err);
			
        if (outputBufferList) delete outputBufferList;
            outputBufferList = NULL;
        } else {
            didSetUpAudioUnits = YES;
        }
        
        // set the input stream format, this is the format of the audio for the converter input bus
        //得られた情報から、ユニットのフォーマットをセットします。
        err = AudioUnitSetProperty(converterAudioUnit,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   0,
                                   &currentInputASBD,
                                   sizeof(currentInputASBD));
		//グラフのアウトプットのフォーマットもセットします。（各ユニットのフォーマットをあわせる）
		if (noErr == err) {
            CAStreamBasicDescription outputFormat(currentInputASBD.mSampleRate,
                                                  currentInputASBD.mChannelsPerFrame,
                                                  CAStreamBasicDescription::kPCMFormatFloat32,
                                                  false);
            NSLog(@"AUGraph Output Audio Format:");
            outputFormat.Print();
            
            graphOutputASBD = outputFormat;
            
            // in an au graph, each nodes output stream format (including sample rate) needs to be set explicitly
            // this stream format is propagated to its destination's input stream format
            //アウトプットのフォーマットと各ユニットのフォーマットを一致させている模様
            // set the output stream format of the converter
            err = AudioUnitSetProperty(converterAudioUnit,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Output,
                                       0,
                                       &graphOutputASBD,
                                       sizeof(graphOutputASBD));
            if (noErr == err)
            // set the output stream format of the delay
            err = AudioUnitSetProperty(delayAudioUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Output,
                                           0,
                                           &graphOutputASBD,
                                           sizeof(graphOutputASBD));
            
            err = AudioUnitSetProperty(reverbUnit,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Output,
                                       0,
                                       &graphOutputASBD,
                                       sizeof(graphOutputASBD));
            err = AudioUnitSetProperty(genericOutUnit,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Output,
                                       0,
                                       &graphOutputASBD,
                                       sizeof(graphOutputASBD));
            err = AudioUnitSetProperty(mixerUnit,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Output,
                                       0,
                                       &graphOutputASBD,
                                       sizeof(graphOutputASBD));
        }
        
        reverbValue_ = [[reverbValue alloc] initWithReverbUnit:reverbUnit];
        
#pragma  - initialize the graph
        // Initialize the graph
		if (noErr == err)
			err = AUGraphInitialize(auGraph);
        
        CAShow(auGraph);
    }

#pragma - time stamp section for continious rendering
    //ユニットを通ったアウトプットのバッファからオーディオフレームを取り出します。
    CMItemCount numberOfFrames = CMSampleBufferGetNumSamples(sampleBuffer); // corresponds to the number of CoreAudio audio frames
		
    // In order to render continuously, the effect audio unit needs a new time stamp for each buffer
    // Use the number of frames for each unit of time continuously incrementing
    //絶え間なく読み込みをするため、エフェクトユニットが各バッファーに新しい時間の目印を必要とします。
    //それには各ユニットが連続で増加させているフレームの数を使います。
    currentSampleTime += (double)numberOfFrames;
    
    AudioTimeStamp timeStamp;
    //memset関数は初期化用の関数ではなく、第一引数に指定したバッファに対し、
    //第二引数で指定した文字を、第三引数で指定したサイズ分埋めることができます。
    memset(&timeStamp, 0, sizeof(AudioTimeStamp)); //つまり初期化している
    timeStamp.mSampleTime = currentSampleTime;
    timeStamp.mFlags |= kAudioTimeStampSampleTimeValid;		
    
    AudioUnitRenderActionFlags flags = 0;
    
    // Create an output AudioBufferList as the destination for the AU rendered audio
    if (NULL == outputBufferList) {
        outputBufferList = new AUOutputBL(graphOutputASBD, numberOfFrames); //自分でcast
    }
    outputBufferList->Prepare(numberOfFrames);
    
    /*
     サンプルバッファー（最初に書くユニットを通って出る音）からバッファリストを作って、インプット（書き込む予定の）のバッファリストの変数にアサインします。下述のPushCurrentInputBufferIntoAudioUnitというレンダーコールバックがこの変数にアクセス出来る
     Get an audio buffer list from the sample buffer and assign it to the currentInputAudioBufferList instance variable.
     The the audio unit render callback called PushCurrentInputBufferIntoAudioUnit can access this value by calling the
     currentInputAudioBufferList method.
    */
    
    // CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer requires a properly allocated AudioBufferList struct
    currentInputAudioBufferList = CAAudioBufferList::Create(currentInputASBD.mChannelsPerFrame);
    
    size_t bufferListSizeNeededOut;
    CMBlockBufferRef blockBufferOut = nil;
    
    err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer,
                                                                  &bufferListSizeNeededOut,
                                                                  currentInputAudioBufferList,
                                                                  CAAudioBufferList::CalculateByteSize(currentInputASBD.mChannelsPerFrame),
                                                                  kCFAllocatorSystemDefault,
                                                                  kCFAllocatorSystemDefault,
                                                                  kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                  &blockBufferOut);
    
    if (noErr == err) {
        // Tell the effect audio unit to render -- This will synchronously call PushCurrentInputBufferIntoAudioUnit, which will
        // feed currentInputAudioBufferList into the effect audio unit
        
        err = AudioUnitRender(delayAudioUnit, &flags, &timeStamp, 0, numberOfFrames, outputBufferList->ABL());
        err = AudioUnitRender(reverbUnit, &flags, &timeStamp, 0, numberOfFrames, outputBufferList->ABL());
        err = AudioUnitRender(genericOutUnit, &flags, &timeStamp, 0, numberOfFrames, outputBufferList->ABL());
        err = AudioUnitRender(mixerUnit, &flags, &timeStamp, 0, numberOfFrames, outputBufferList->ABL());
        if (err) {
            // kAudioUnitErr_TooManyFramesToProcess may happen on a route change if CMSampleBufferGetNumSamples
            // returns more than 1024 (the default) number of samples. This is ok and on the next cycle this error should not repeat
            NSLog(@"AudioUnitRender failed! (%d)", (int)err);
        }
        
        CFRelease(blockBufferOut);
        CAAudioBufferList::Destroy(currentInputAudioBufferList);
        currentInputAudioBufferList = NULL;
    } else {
        NSLog(@"CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer failed! (%ld)", (long)err);
    }

    if (noErr == err) {
        @synchronized(self) {   //割り込みをさせない、同時アクセスをブロックするディレクティブ
            if (extAudioFile) {
                err = ExtAudioFileWriteAsync(extAudioFile, numberOfFrames, outputBufferList->ABL());
            }
            if (extAudioFile1) {
                err = ExtAudioFileWriteAsync(extAudioFile1, numberOfFrames, outputBufferList->ABL());
            }
        }// @synchronized
        if (err) {
            NSLog(@"ExtAudioFileWriteAsync failed! (%ld)", (long)err);
        }
    }
}

/*
 ユニットから出てキャプチャーされているアウトプットにアクセスするのにPushCurrentInputBufferIntoAudioUnitが使われています。Used by PushCurrentInputBufferIntoAudioUnit() to access the current audio buffer list
 that has been output by the AVCaptureAudioDataOutput.
*/
- (AudioBufferList *)currentInputAudioBufferList
{
	return currentInputAudioBufferList;
}

#pragma mark ======== AVCapture Session & Recording =========

- (void)startCaptureSession
{
    static UInt8 retry = 0;
    
    // this sample always attempts to keep the capture session running without tearing it all down,
    // which means we may be trying to start the capture session while it's still
    // in some interim interrupted state (after a phone call for example) which will usually
    // get cleared up after a very short delay handle by a simple retry mechanism
    // if we still can't start, then resort to releasing the previous capture session and creating a new one
    if (captureSession.isInterrupted) {
        if (retry < 3) {
            retry++;
            NSLog(@"Capture Session interrupted try starting again...");
            [self performSelector:@selector(startCaptureSession) withObject:self afterDelay:2]; //多分何らかの妨害中は自身を繰り返すという処理
            return;
        } else {
            NSLog(@"Resetting Capture Session");
            BOOL result = [self resetCaptureSession];
            if (NO == result) {
                // this is bad, and means we can never start...should never see this
                NSLog(@"FAILED in resetCaptureSession! Cannot restart capture session!");
                return;
            }
        }
    }
    
    if (!captureSession.running) {
        NSLog(@"startCaptureSession");
        [captureSession startRunning];
        
        retry = 0;
    }
}

- (void)stopCaptureSession
{
    if (captureSession.running) {
        NSLog(@"stopCaptureSession");
        [captureSession stopRunning];
    }
}

- (void)startRecording
{
    if (!self.isRecording) {
        OSErr err = kAudioFileUnspecifiedError;
        @synchronized(self) {
            if (!extAudioFile) {
                /*
                 Start recording by creating an ExtAudioFile and configuring it with the same sample rate and
                 channel layout as those of the current sample buffer.
                 ExtAudioFileを作って、現在のサンプルバッファーとフォーマットを合わせたら録音を開始します。
                */
                
                // recording format is the format of the audio file itself
                CAStreamBasicDescription recordingFormat(currentInputASBD.mSampleRate,
                                                         currentInputASBD.mChannelsPerFrame,
                                                         CAStreamBasicDescription::kPCMFormatInt16,
                                                         true);
                recordingFormat.mFormatFlags |= kAudioFormatFlagIsBigEndian;
                
                NSLog(@"Recording Audio Format:");
                recordingFormat.Print();
                       
                err = ExtAudioFileCreateWithURL(_outputFile, //URL - 大事
                                                kAudioFileAIFFType,
                                                &recordingFormat,
                                                currentRecordingChannelLayout,
                                                kAudioFileFlags_EraseFile,
                                                &extAudioFile);
                if (noErr == err)
                    // client format is the output format from the delay unit
                    err = ExtAudioFileSetProperty(extAudioFile,
                                                  kExtAudioFileProperty_ClientDataFormat,
                                                  sizeof(graphOutputASBD),
                                                  &graphOutputASBD);
                    
                if (noErr != err) {
                    if (extAudioFile) ExtAudioFileDispose(extAudioFile);
                    extAudioFile = NULL;
                }
            }
        } // @synchronized
        
        if (noErr == err) {
            self.recording = YES;
            NSLog(@"Recording Started");
        } else {
            NSLog(@"Failed to setup audio file! (%ld)", (long)err);
        }
    }
}
- (void)startRecording2
{
    if (!self.isRecording1) {
        OSErr err = kAudioFileUnspecifiedError;
        @synchronized(self) {
            if (!extAudioFile1) {
                
                CAStreamBasicDescription recordingFormat(currentInputASBD.mSampleRate,
                                                         currentInputASBD.mChannelsPerFrame,
                                                         CAStreamBasicDescription::kPCMFormatInt16,
                                                         true);
                recordingFormat.mFormatFlags |= kAudioFormatFlagIsBigEndian;
                
                NSLog(@"Recording Audio Format:");
                recordingFormat.Print();
                
                err = ExtAudioFileCreateWithURL(_outputFile1, //URL - 大事
                                                kAudioFileAIFFType,
                                                &recordingFormat,
                                                currentRecordingChannelLayout,
                                                kAudioFileFlags_EraseFile,
                                                &extAudioFile1);
                if (noErr == err)
                    // client format is the output format from the delay unit
                    err = ExtAudioFileSetProperty(extAudioFile1,
                                                  kExtAudioFileProperty_ClientDataFormat,
                                                  sizeof(graphOutputASBD),
                                                  &graphOutputASBD);
                
                if (noErr != err) {
                    if (extAudioFile1) ExtAudioFileDispose(extAudioFile1);
                    extAudioFile1 = NULL;
                }
            }
        } // @synchronized
        
        if (noErr == err) {
            self.recording1 = YES;
            NSLog(@"Recording Started");
        } else {
            NSLog(@"Failed to setup audio file! (%ld)", (long)err);
        }
    }
}

- (void)stopRecording
{
    if (self.isRecording) {
        OSStatus err = kAudioFileNotOpenError;
        @synchronized(self) {
            if (extAudioFile) {
                // Close the file by disposing the ExtAudioFile
                err = ExtAudioFileDispose(extAudioFile);
                extAudioFile = NULL;
            }
        } // @synchronized
        AudioUnitReset(delayAudioUnit, kAudioUnitScope_Global, 0); //3/24追加
        //AudioUnitReset(reverbUnit, kAudioUnitScope_Global, 0);
        
        self.recording = NO;
        NSLog(@"Recording Stopped (%ld)", (long)err);
    }
}
- (void)stopRecording2
{
    if (self.isRecording1) {
        OSStatus err = kAudioFileNotOpenError;
        @synchronized(self) {
            if (extAudioFile1) {
                // Close the file by disposing the ExtAudioFile
                err = ExtAudioFileDispose(extAudioFile1);
                extAudioFile1 = NULL;
            }
        } // @synchronized
        AudioUnitReset(delayAudioUnit, kAudioUnitScope_Global, 0); //3/24追加
        //AudioUnitReset(reverbUnit, kAudioUnitScope_Global, 0);
        
        self.recording1 = NO;
        NSLog(@"Recording Stopped (%ld)", (long)err);
    }
}

#pragma mark ======== Observers =========

// observe state changes from the capture session, we log interruptions but activate the UI via notification when running
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"interrupted"] ) {
        NSLog(@"CaptureSesson is interrupted %@", (captureSession.isInterrupted) ? @"Yes" : @"No");
    }
    
    if ([keyPath isEqualToString:@"running"] ) {
        NSLog(@"CaptureSesson is running %@", (captureSession.isRunning) ? @"Yes" : @"No");
        if (captureSession.isRunning) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CaptureSessionRunningNotification" object:nil];
        }
    }
}

#pragma mark ======== Notifications =========

// notifications for standard things we want to know about
- (void)registerForNotifications
{
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(willResignActive)
//                                                 name:UIApplicationWillResignActiveNotification
//                                               object:nil];
//    
//	[[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(didBecomeActive)
//                                                 name:UIApplicationDidBecomeActiveNotification
//                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(routeChangeHandler:)
                                                 name:AVAudioSessionRouteChangeNotification 
                                               object:[AVAudioSession sharedInstance]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(captureSessionRuntimeError:)
                                                 name:AVCaptureSessionRuntimeErrorNotification 
                                               object:nil];
}

// log any runtime erros from the capture session
- (void)captureSessionRuntimeError:(NSNotification *)notification
{
    NSError *error = [notification.userInfo objectForKey: AVCaptureSessionErrorKey];
    
    NSLog(@"AVFoundation error %ld", (long)[error code]);
}

// log route changes
- (void)routeChangeHandler:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey: AVAudioSessionRouteChangeReasonKey] intValue];
    
    if (AVAudioSessionRouteChangeReasonNewDeviceAvailable == reasonValue || AVAudioSessionRouteChangeReasonOldDeviceUnavailable == reasonValue) {
       	NSLog(@"CaptureSessionController routeChangeHandler called:");
        (reasonValue == AVAudioSessionRouteChangeReasonNewDeviceAvailable) ? NSLog(@"     NewDeviceAvailable") :
                                                                             NSLog(@"     OldDeviceUnavailable");
    }
}

// need to stop capture session and close the file if recording on resign
- (void)willResignActive
{
    NSLog(@"CaptureSessionController willResignActive");
    
    [self stopCaptureSession];
    
    if (self.isRecording) {
        [self stopRecording];
    }
    if (self.isRecording1) {
        [self stopRecording2];
    }

}

// we want to start the capture session again automatically on active
- (void)didBecomeActive
{
    NSLog(@"CaptureSessionController didBecomeActive");
    
    [self startCaptureSession];
}

@end

#pragma mark ======== AudioUnit render callback =========

/*
 AudioUnitRender()が呼ばれるときならいつでもエフェクトユニットによって同時に呼ばれます。
 Synchronously called by the effect audio unit whenever AudioUnitRender() is called.
 Used to feed the audio samples output by the ATCaptureAudioDataOutput to the AudioUnit.
 */
static OSStatus PushCurrentInputBufferIntoAudioUnit(void *							inRefCon,
													AudioUnitRenderActionFlags *	ioActionFlags,
													const AudioTimeStamp *			inTimeStamp,
													UInt32							inBusNumber,
													UInt32							inNumberFrames,
													AudioBufferList *				ioData)
{
	CaptureSessionController *self = (__bridge CaptureSessionController *)inRefCon;
	AudioBufferList *currentInputAudioBufferList = [self currentInputAudioBufferList];
	UInt32 bufferIndex, bufferCount = currentInputAudioBufferList->mNumberBuffers;
	
	if (bufferCount != ioData->mNumberBuffers) return kAudioFormatUnknownFormatError;
	
	// Fill the provided AudioBufferList with the data from the AudioBufferList output by the audio data output
    //これがオーディオアウトプットのバッファリストからユニットへバッファを橋渡ししている箇所
	for (bufferIndex = 0; bufferIndex < bufferCount; bufferIndex++) {
		ioData->mBuffers[bufferIndex].mDataByteSize = currentInputAudioBufferList->mBuffers[bufferIndex].mDataByteSize;
		ioData->mBuffers[bufferIndex].mData = currentInputAudioBufferList->mBuffers[bufferIndex].mData;
		ioData->mBuffers[bufferIndex].mNumberChannels = currentInputAudioBufferList->mBuffers[bufferIndex].mNumberChannels;
	}
	
	return noErr;
}