//
//  ViewController.h
//  offlinerender
//
//  Created by liumiao on 11/17/14.
//  Copyright (c) 2014 Chang Ba. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MTPlayer.h"
#import "MTSourcePlayer.h"

@interface ViewController : UIViewController
{
    AUGraph mGraph;
    //Audio Unit References
    AudioUnit mFilePlayer;
    AudioUnit mConvert;
    AudioUnit mMixer;
    AudioUnit mGIO;
    //Standard sample rate
    Float64 graphSampleRate;
    AudioStreamBasicDescription stereoStreamFormat864;
    
    MTPlayer* player;
    MTSourcePlayer* cwPlayer;
    
    Float64 MaxSampleTime;
}
@end

