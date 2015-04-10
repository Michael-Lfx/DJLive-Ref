

#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "reverbValue.h"

// CoreAudio Public Utility
#include "CAStreamBasicDescription.h"
#include "CAComponentDescription.h"
#include "CAAudioBufferList.h"
#include "AUOutputBL.h"

@interface CaptureSessionController : NSObject <AVCaptureAudioDataOutputSampleBufferDelegate> {
@private
    AVCaptureSession            *captureSession;
    AVCaptureDeviceInput        *captureAudioDeviceInput;
    AVCaptureAudioDataOutput    *captureAudioDataOutput;
	
    AUGraph                     auGraph;
    AudioUnit					converterAudioUnit;
	AudioUnit					delayAudioUnit;
    AudioUnit                   reverbUnit;
    AudioUnit                   genericOutUnit;
    AudioUnit                   mixerUnit;
    AudioChannelLayout          *currentRecordingChannelLayout;
    ExtAudioFileRef             extAudioFile;
    ExtAudioFileRef             extAudioFile1;
	
    AudioStreamBasicDescription currentInputASBD;
    AudioStreamBasicDescription graphOutputASBD;
	AudioBufferList				*currentInputAudioBufferList;
    AUOutputBL                  *outputBufferList;
    
	double						currentSampleTime;
	BOOL						didSetUpAudioUnits;
@public
    reverbValue *reverbValue_;
    
    
}

@property(atomic, getter=isRecording) BOOL recording;
@property(atomic, getter=isRecording1) BOOL recording1;
@property                             CFURLRef outputFile;
@property                             CFURLRef outputFile1;

- (BOOL)setupCaptureSession;
- (void)startCaptureSession;
- (void)stopCaptureSession;
- (void)startRecording;
- (void)startRecording2;
- (void)stopRecording;
- (void)stopRecording2;

@property (nonatomic,readonly)reverbValue *reverbValue;

@end
