//
//  ViewController.h
//  offlinerender
//
//  Created by liumiao on 11/17/14.
//  Copyright (c) 2014 Chang Ba. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
@interface ViewController : UIViewController
{
    AUGraph mGraph;
    //Audio Unit References
    AudioUnit mFilePlayer;
    AudioUnit mFilePlayer2;
    AudioUnit mReverb;
    AudioUnit mTone;
    AudioUnit mMixer;
    AudioUnit mGIO;
    //Audio File Location
    AudioFileID inputFile;
    AudioFileID inputFile2;
    //Audio file refereces for saving
    ExtAudioFileRef extAudioFile;
    //Standard sample rate
    Float64 graphSampleRate;
    AudioStreamBasicDescription stereoStreamFormat864;
    
    Float64 MaxSampleTime;
}
@end

