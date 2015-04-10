//
//  altViewController.h
//  RecThroughUnit
//
//  Created by KatayamaRyusuke on 2015/02/18.
//  Copyright (c) 2015年 片山隆介. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "reverbValue.h" //3/25
#import "nextViewController.h"

@class audioSetup;
@class CaptureSessionController;
//プロトコルとして<SubViewControllerDelegate>を宣言
@interface altViewController : UIViewController
<AVAudioRecorderDelegate,AVAudioPlayerDelegate,nextViewControllerDelegate>
{
    AVAudioRecorder *avRecorder;
    AVAudioPlayer *avPlayer;
    
    NSString *portType;
    NSString *portName;
    NSArray *channels;
    //------------------------
    audioSetup *audioSetup_;
    altViewController *altAudioSetup;
    reverbValue *reverbValue_;
    
    __weak IBOutlet UILabel *dryWetsLabel;
    __weak IBOutlet UISlider *dryWetsSlider;
    __weak IBOutlet UILabel *gainsLabel;
    __weak IBOutlet UISlider *gainsSlider;
    __weak IBOutlet UILabel *minDelayTimesLabel;
    __weak IBOutlet UISlider *minDelayTimesSlider;
    __weak IBOutlet UILabel *maxDelayTimesLabel;
    __weak IBOutlet UISlider *maxDelayTimesSlider;
    __weak IBOutlet UILabel *decayTimesAt0HzLabel;
    __weak IBOutlet UISlider *decayTimesAt0HzSlider;
    __weak IBOutlet UILabel *decayTimesAtNyquistLabel;
    __weak IBOutlet UISlider *decayTimesAtNyquistSlider;
    __weak IBOutlet UILabel *randomizeReflectionLabel;
    __weak IBOutlet UISlider *randomizeReflectionSlider;
    
    AVAudioPlayer *playerA;
    AVAudioPlayer *playerB; 
}

//------------------------
- (IBAction)didchangeDryWetMixSlider:(UISlider *)sender;
- (IBAction)didchangeGain:(UISlider *)sender;
- (IBAction)didchangeMinDelayTime:(UISlider *)sender;
- (IBAction)didchangeMaxDelayTime:(UISlider *)sender;
- (IBAction)didchangeDecayTimeAt0Hz:(UISlider *)sender;
- (IBAction)didchangeDecayTimeAtNyquist:(UISlider *)sender;
- (IBAction)didchangeRandomizeReflections:(UISlider *)sender;
- (IBAction)resets;

- (IBAction)playPlayerA:(id)sender;

- (IBAction)descPort:(id)sender;
@property (readonly) NSString *portType;
@property (nonatomic,readonly)reverbValue *reverbValue;
//capture
- (void)initCaptureSession;
@end

