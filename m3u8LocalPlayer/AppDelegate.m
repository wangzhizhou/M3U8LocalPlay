//
//  AppDelegate.m
//  m3u8LocalPlayer
//
//  Created by JokerAtBaoFeng on 8/2/16.
//  Copyright © 2016 joker. All rights reserved.
//

#import "AppDelegate.h"
#import "M3U8PlayerControllerViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    M3U8PlayerControllerViewController *playerVC = [[M3U8PlayerControllerViewController alloc] init];
    
    self.window.rootViewController = playerVC;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}
@end
