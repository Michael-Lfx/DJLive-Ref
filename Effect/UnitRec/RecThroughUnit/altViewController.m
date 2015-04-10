//
//  altViewController.m
//  RecThroughUnit
//
//  Created by KatayamaRyusuke on 2015/02/18.
//  Copyright (c) 2015年 片山隆介. All rights reserved.
//  ARCをオフにして、releaseを明示的にすること　

#import "altViewController.h"
#import "CaptureSessionController.h"

@interface altViewController ()
- (void)updateUI;

@property (readwrite ,nonatomic ) IBOutlet UIButton *startButton;
@property (readwrite ,nonatomic ) IBOutlet UIButton *startButton2;
@property (readwrite ,nonatomic ) IBOutlet UILabel *playBackText;
@property (readwrite ,nonatomic ) IBOutlet UILabel *playBackText2;
@property (nonatomic, strong   ) IBOutlet CaptureSessionController *captureSessionController;
- (IBAction)buttonAction:(id)sender;
- (IBAction)buttonAction2:(id)sender;

- (IBAction)playPlayerB:(id)sender;
- (IBAction)exportA:(id)sender;
- (IBAction)exportB:(id)sender;

- (IBAction)segueA:(id)sender;

@end

@implementation altViewController
{//親画面のラベル
    __weak IBOutlet UILabel *testLabel1;
}
@synthesize portType;

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self != nil)
//    {
//        //audioSetup_ = [[audioSetup alloc] initWithSamplingRate:44100.0];
//        //[audioSetup_ open];
//        //[audioSetup_ start];
//    }
//    return self;
//}

//子画面から返された文字列を受け取るためのデリゲートメソッド
- (void)returnString:(NSString *)str{
    
    //ラベルの文字列としてセット
    testLabel1.text= str;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIImage *greenImage = [[UIImage imageNamed:@"green_button.png"] stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
    UIImage *redImage = [[UIImage imageNamed:@"red_button.png"] stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
    
    [self.startButton setBackgroundImage:greenImage forState:UIControlStateNormal];
    [self.startButton setBackgroundImage:redImage forState:UIControlStateSelected];
    [self.startButton2 setBackgroundImage:greenImage forState:UIControlStateNormal];
    [self.startButton2 setBackgroundImage:redImage forState:UIControlStateSelected];

}

- (void)viewDidUnload
{
    dryWetsSlider = nil;
    dryWetsLabel = nil;
    gainsSlider = nil;
    gainsLabel = nil;
    minDelayTimesLabel = nil;
    maxDelayTimesLabel = nil;
    minDelayTimesSlider = nil;
    maxDelayTimesSlider = nil;
    decayTimesAt0HzLabel = nil;
    decayTimesAt0HzSlider = nil;
    decayTimesAtNyquistLabel = nil;
    decayTimesAtNyquistSlider = nil;
    randomizeReflectionLabel = nil;
    randomizeReflectionSlider = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)viewWillAppear:(BOOL)animated
{
    [self registerForNotifications];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [self unregisterForNotifications];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - private methods
- (void)updateUI {
    reverbValue *defValue = [altAudioSetup reverbValue];
    Float32 value;
    value = [defValue dryWetMix];
    [dryWetsSlider setValue:value animated:YES];
    [dryWetsLabel setText:[NSString stringWithFormat:@"%.2f", value]];
    value = [defValue gain];
    [gainsSlider setValue:value animated:YES];
    [gainsLabel setText:[NSString stringWithFormat:@"%.2f", value]];
    value = [defValue minDelayTime];
    [minDelayTimesSlider setValue:value animated:YES];
    [minDelayTimesLabel setText:[NSString stringWithFormat:@"%.2f", value]];
    value = [defValue maxDelayTime];
    [maxDelayTimesSlider setValue:value animated:YES];
    [maxDelayTimesLabel setText:[NSString stringWithFormat:@"%.2f", value]];
    value = [defValue decayTimeAt0Hz];
    [decayTimesAt0HzSlider setValue:value animated:YES];
    [decayTimesAt0HzLabel setText:[NSString stringWithFormat:@"%.2f", value]];
    value = [defValue decayTimeAtNyquist];
    [decayTimesAtNyquistSlider setValue:value animated:YES];
    [decayTimesAtNyquistLabel setText:[NSString stringWithFormat:@"%.2f", value]];
    value = [defValue randomizeReflections];
    [randomizeReflectionSlider setValue:value animated:YES];
    [randomizeReflectionLabel setText:[NSString stringWithFormat:@"%.2f", value]];
}


#pragma mark - Actions
- (IBAction)didchangeDryWetMixSlider:(UISlider *)sender {
    Float32 value = [sender value];
    [[self.captureSessionController reverbValue] setDryWetMix:value]; //[インスタンス メソッド]
    [dryWetsLabel setText:[NSString stringWithFormat:@"%.2f", value]];
}

- (IBAction)didchangeGain:(UISlider *)sender {
    Float32 value = [sender value];
    [[self.captureSessionController reverbValue] setGain:value];
    [gainsLabel setText:[NSString stringWithFormat:@"%.2f", value]];
}

- (IBAction)didchangeMinDelayTime:(UISlider *)sender {
    Float32 value = [sender value];
    [[self.captureSessionController reverbValue] setMinDelayTime:value];
    [minDelayTimesLabel setText:[NSString stringWithFormat:@"%.2f", value]];
}

- (IBAction)didchangeMaxDelayTime:(UISlider *)sender {
    Float32 value = [sender value];
    [[self.captureSessionController reverbValue] setMaxDelayTime:value];
    [maxDelayTimesLabel setText:[NSString stringWithFormat:@"%.2f", value]];
}

- (IBAction)didchangeDecayTimeAt0Hz:(UISlider *)sender {
    Float32 value = [sender value];
    [[self.captureSessionController reverbValue] setDecayTimeAt0Hz:value];
    [decayTimesAt0HzLabel setText:[NSString stringWithFormat:@"%.2f", value]];
}

- (IBAction)didchangeDecayTimeAtNyquist:(UISlider *)sender {
    Float32 value = [sender value];
    [[self.captureSessionController reverbValue] setDecayTimeAtNyquist:value];
    [decayTimesAtNyquistLabel setText:[NSString stringWithFormat:@"%.2f", value]];
}

- (IBAction)didchangeRandomizeReflections:(UISlider *)sender {
    Float32 value = [sender value];
    [[self.captureSessionController reverbValue] setRandomizeReflections:value];
    [randomizeReflectionLabel setText:[NSString stringWithFormat:@"%.2f", value]];
}

- (IBAction)resets {
    [[self.captureSessionController reverbValue] resetParameters];
    [self updateUI];
}

-(IBAction)descPort:(id)sender{
    NSLog(@"ポートタイプは%s", [portType UTF8String]);
    NSArray *availableInputs = [[AVAudioSession sharedInstance] availableInputs];
    AVAudioSessionPortDescription *port = [availableInputs objectAtIndex:0];
    NSLog(@"available input is %@", port);
};


#pragma  - for capture
- (void)initCaptureSession
{
    if ([self.captureSessionController setupCaptureSession]) {
        [self updateUISelected:NO enabled:YES];
        [self updateUISelected2:NO enabled:YES];
    }
    else NSLog(@"Initializing CaptureSessionController failed just BAIL!");
}
- (IBAction)buttonAction:(id)sender
{
        if (self.captureSessionController.isRecording) {
            [self.captureSessionController stopRecording];
            [self updateUISelected:NO enabled:NO];
            [self playRecordedAudio];
        } else {
            [self.captureSessionController startRecording];
            [self updateUISelected:YES enabled:YES];
        }
}
- (IBAction)playPlayerA:(id)sender{
    if (self.captureSessionController.outputFile) {
        [playerA play];
    }
}
- (IBAction)playPlayerB:(id)sender{
    if (self.captureSessionController.outputFile1){
        [playerB play];
    }
}
- (IBAction)buttonAction2:(id)sender
{
    if (self.captureSessionController.isRecording1) {
        [self.captureSessionController stopRecording2];
        [self updateUISelected2:NO enabled:NO];
        [self playRecordedAudio2];
    } else {
        [self.captureSessionController startRecording2];
        [self updateUISelected2:YES enabled:YES];
    }
}


- (void)updateUISelected:(BOOL)selected enabled:(BOOL)enabled
{
    self.startButton.selected = selected;
    self.startButton.enabled = enabled;
}
- (void)updateUISelected2:(BOOL)selected enabled:(BOOL)enabled
{
    self.startButton2.selected = selected;
    self.startButton2.enabled = enabled;
}

#pragma mark ======== AVAudioPlayer =========

// when interrupted, just toss the player and we're done
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    NSLog(@"AVAudioPlayer audioPlayerBeginInterruption");
    
    if ([player isEqual:@"playerA"]) {
         [playerA setDelegate:nil];
         [playerA release];
         
         self.playBackText.hidden = YES;
    }else if([player isEqual:@"playerB"]){
        [playerB setDelegate:nil];
        [playerB release];
        
        self.playBackText2.hidden = YES;
    }
    
}

// when finished, toss the player and restart the capture session※再生が終わった後ボタンがフリーズするのはここが原因かも
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    
    (flag == NO) ?  NSLog(@"AVAudioPlayer unsuccessfull!") :
                    NSLog(@"AVAudioPlayer finished playing");
    NSLog(@"audioPlayerDelegate was called");
    if ([player isEqual: @"playerA"]) {
        
        [playerA setDelegate:nil];
        [playerA release];   //3/25追加
        self.playBackText.hidden = YES;
        NSLog(@"playerA was released");
    }else if([player isEqual:@"playerB"]){
    
        [playerB setDelegate:nil];
        [playerB release];
        self.playBackText2.hidden = YES;
        NSLog(@"playerB was released");
    }
    
    
    
    // start the capture session
    [self.captureSessionController startCaptureSession];
}

// basic AVAudioPlayer implementation to play back recorded file
- (void)playRecordedAudio
{
    NSError *error = nil;
    
    // stop the capture session
    [self.captureSessionController stopCaptureSession];
    
    NSLog(@"Playing Recorded Audio");
    
    // play the result
    playerA = [[AVAudioPlayer alloc] initWithContentsOfURL:(NSURL *)self.captureSessionController.outputFile error:nil];
    if (nil == playerA) {
        NSLog(@"AVAudioPlayer alloc failed! %@", [error localizedDescription]);
        [self.startButton setTitle:@"FAIL!" forState:UIControlStateDisabled];
        return;
    }
    
    self.playBackText.hidden = NO;
    
    [playerA setDelegate:self];
    [playerA play];
}
- (IBAction)exportA:(id)sender{
    NSURL *URL = (NSURL *)self.captureSessionController.outputFile;
    NSString *directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *filePath =
    [directory stringByAppendingPathComponent:@"fileone.caf"];
    BOOL successful = [NSKeyedArchiver archiveRootObject:URL toFile:filePath];
    if (successful) {
        NSLog(@"%@", @"データの保存に成功しました。");
    }
}
- (IBAction)exportB:(id)sender{
    NSURL *URL = (NSURL *)self.captureSessionController.outputFile1;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setURL:URL forKey:@"exportedAudiofile"];
    BOOL successful = [defaults synchronize];
    if (successful) {
        NSLog(@"%@", @"データの保存に成功しました。");
    }
}
-(IBAction)segueA:(id)sender{
    nextViewController *controller = [[nextViewController alloc] initWithNibName:@"nextViewController" bundle:nil];
    //自身のインスタンスをデリゲートとしてセット
    controller.delegate = self;
    
    //子画面のインスタンスに文字列を渡す
    controller.labelText = @"親から渡された文字列";
    
    //次画面に遷移する
    [self presentViewController:controller animated:YES completion:^ {
        //遷移完了時の処理はここに書く
    }];
//    [self.navigationController pushViewController:controller animated:YES];
}
- (void)playRecordedAudio2
{
    NSError *error = nil;
    
    // stop the capture session
    [self.captureSessionController stopCaptureSession];
    
    NSLog(@"Playing Recorded Audio");
    
    // play the result
    playerB = [[AVAudioPlayer alloc] initWithContentsOfURL:(NSURL *)self.captureSessionController.outputFile1 error:nil];
    if (nil == playerB) {
        NSLog(@"AVAudioPlayer alloc failed! %@", [error localizedDescription]);
        [self.startButton2 setTitle:@"FAIL!" forState:UIControlStateDisabled];
        return;
    }
    
    self.playBackText2.hidden = NO;
    
    [playerB setDelegate:self];
    [playerB play];
}



#pragma mark ======== Notifications =========

// notification handling to do the right thing when the app comes and goes
- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enableButton)
                                                 name:@"CaptureSessionRunningNotification"
                                               object:nil];
}

- (void)unregisterForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"CaptureSessionRunningNotification"
                                                  object:nil];
}

- (void)willResignActive
{
    NSLog(@"MyViewController willResignActive");
    
    [self updateUISelected:NO enabled:NO];
    [self updateUISelected2:NO enabled:NO];
}

- (void)enableButton
{
    NSLog(@"MyViewController enableButton");
    
    [self updateUISelected:NO enabled:YES];
    [self updateUISelected2:NO enabled:YES];
}


@end
