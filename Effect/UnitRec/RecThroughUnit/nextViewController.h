//
//  nextViewController.h
//  RecThroughUnit
//
//  Created by KatayamaRyusuke on 2015/03/29.
//  Copyright (c) 2015年 片山隆介. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "CaptureSessionController.h"
#import "reverbValue.h"
@class altViewController;

@protocol nextViewControllerDelegate <NSObject>

//デリゲートメソッドを宣言
//デリゲート先となるクラスはこのデリゲートメソッドを実装する
- (void)returnString:(NSString*)str;

@end

@interface nextViewController : UIViewController{
    __weak IBOutlet UILabel *gainsLabelnext;
    reverbValue *reverbValueNext;
    int userParam;
}

@property int userParam;


//デリゲート先になっているインスタンスを参照するためのプロパティを定義
@property (nonatomic, assign) id<nextViewControllerDelegate> delegate;

//「戻る」ボタンが押された時に呼び出されるメソッド
- (IBAction)back:(UIButton *)sender;

//渡された文字列を格納するプロパティ
@property (nonatomic, retain)NSString *labelText;

@end

