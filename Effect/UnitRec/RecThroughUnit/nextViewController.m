//
//  nextViewController.m
//  RecThroughUnit
//
//  Created by KatayamaRyusuke on 2015/03/29.
//  Copyright (c) 2015年 片山隆介. All rights reserved.
//

#import "nextViewController.h"

@interface nextViewController ()
//@property (nonatomic, strong   ) IBOutlet CaptureSessionController *captureSessionControllerNext;
@end

@implementation nextViewController{
    
    //画面に表示するラベル
    __weak IBOutlet UILabel *testLabel2;
    
}
@synthesize userParam;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //渡された文字列をラベルの文字列にする
    testLabel2.text = self.labelText;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//-(IBAction)changeReverbGain:(UISlider*)sender{
//    Float32 value = [sender value];
//    userParam = value;
//    //[reverbValueNext setGain:value];
//    [gainsLabelnext setText:[NSString stringWithFormat:@"%.2f", value]];
//}
- (IBAction)back:(UIButton *)sender {
    
    //デリゲート先が"returnString"というメソッドを持っているか確認
    if([self.delegate respondsToSelector:@selector(returnString:)]){
        //デリゲートメソッドを呼び出す
        [self.delegate returnString:@"子から渡された文字列"];
    }
    
    //元の画面に戻る
    [self dismissViewControllerAnimated:YES completion:^ {
        //元の画面に戻った後の処理をここに書く
    }];
    
}/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
