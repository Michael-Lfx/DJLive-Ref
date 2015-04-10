//
//  ViewController.m
//  TestFM
//
//  Created by mac on 15/4/9.
//  Copyright (c) 2015年 com.live. All rights reserved.
//

#import "ViewController.h"
#import <PlayerKit/PlayerKit.h>
#import <AudioToolbox/AudioToolbox.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    AudioComponentDescription desc;
//    desc.componentType = kAudioUnitType_Output;
//    desc.componentSubType = kAudioSubDeviceDriftCompensationLowQuality;
//    desc.componentFlags = 0;
//    desc.componentFlagsMask = 0;
//    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
//    
//    PKAudioEffectRef ref=PKAudioEffectCreate(desc, NULL);
//    PKAudioEffectSetEnabled(ref, YES, NULL);
    
    CFErrorRef error;
    PKAudioPlayerInit(&error);
    CFURLRef sound1URL = (__bridge CFURLRef)[NSURL fileURLWithPath:@"/Users/mac/Desktop/test.mp3"];
    BOOL isplay= PKAudioPlayerCanPlayFileAtLocation(sound1URL);
    if (isplay) {
        PKAudioPlayerSetURL(sound1URL, &error);
    }
    // Do any additional setup after loading the view.
}

- (IBAction)play:(id)sender
{
    if (PKAudioPlayerIsPlaying()) {
        PKAudioPlayerPause(NULL);
    }
    else
    {
        PKAudioPlayerPlay(NULL);;
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

@end
