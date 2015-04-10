//
//  AppDelegate.m
//  RecThroughUnit
//
//  Created by 片山 隆介 on 2015/02/15.
//  Copyright (c) 2015年 片山隆介. All rights reserved.
//

#import "AppDelegate.h"
#import "altViewController.h"

@class altViewController;

@interface AppDelegate ()

@property (nonatomic, strong) IBOutlet UINavigationController *navController;

@end

@implementation AppDelegate

//@synthesize altviewController = _altviewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]autorelease];
    // Override point for customization after application launch.
    //self.altviewController = [[altViewController alloc] initWithNibName:@"altViewController" bundle:nil];
    self.window.rootViewController = self.navController; //元々はaltViewController
    [self.window makeKeyAndVisible];
    // Override point for customization after application launch.
//    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//    UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    UIViewController* tViewController = [storyBoard instantiateInitialViewController];
//    self.window.rootViewController = tViewController;
//    [self.window makeKeyAndVisible];
    altViewController *topViewController = (altViewController *)self.navController.topViewController;
    [topViewController initCaptureSession]; //実装内容の中で一番早い処理はこれ。インプットとアウトプットのキャプチャーを有効化
}


@end
