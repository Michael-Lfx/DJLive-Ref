//
//  reverbValue.h
//  RecThroughUnit
//
//  Created by KatayamaRyusuke on 2015/02/17.
//  Copyright (c) 2015年 片山隆介. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


@interface reverbValue : NSObject
{
    AudioUnit reverbUnit_;
    
    // デフォルト値の保存用
    Float32 dryWetMix_;
    Float32 gain_;
    Float32 minDelayTime_;
    Float32 maxDelayTime_;
    Float32 decayTimeAt0Hz_;
    Float32 decayTimeAtNyquist_;
    Float32 randomizeReflections_;
}

@property (atomic)Float32 dryWetMix;
@property (atomic)Float32 gain;
@property (atomic)Float32 minDelayTime;
@property (atomic)Float32 maxDelayTime;
@property (atomic)Float32 decayTimeAt0Hz;
@property (atomic)Float32 decayTimeAtNyquist;
@property (atomic)Float32 randomizeReflections;

- (id)initWithReverbUnit:(AudioUnit)reverbUnit;

// 設定のリセット
- (void)resetParameters;

@end
