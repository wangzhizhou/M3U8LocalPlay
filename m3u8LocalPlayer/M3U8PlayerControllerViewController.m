//
//  M3U8PlayerControllerViewController.m
//  m3u8LocalPlayer
//
//  Created by JokerAtBaoFeng on 8/2/16.
//  Copyright © 2016 joker. All rights reserved.
//

#import "M3U8PlayerControllerViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "M3U8DownloadManager.h"
#import "HTTPServerManager.h"

@interface M3U8PlayerControllerViewController ()

@end

@implementation M3U8PlayerControllerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    UIButton *downloadBtn = [[UIButton alloc]initWithFrame:CGRectMake((self.view.bounds.size.width - 100)/2.0, 100, 100, 100)];
    downloadBtn.backgroundColor = [UIColor greenColor];
    
    [downloadBtn addTarget:self action:@selector(download) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:downloadBtn];
    
    
    UIButton *playBtn = [[UIButton alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 100)/2.0, 250, 100, 100)];
    playBtn.backgroundColor = [UIColor redColor];
    
    [playBtn addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:playBtn];
    

}
-(void)download
{
    [[M3U8DownloadManager new] downloadM3U8WithFile:kSrcURL];
}
-(void)play
{
    [[HTTPServerManager shareInstance] startHTTPServer];

        NSString *videoUrl = [NSString stringWithFormat:@"%@/m3u8List.m3u",kLocalLoopURL];
//    NSString *videoUrl = [NSString stringWithFormat:@"%@/m3u8List",kLocalLoopURL];
//    videoUrl = [videoUrl stringByAppendingString:@"?vid=XNTQwMTgxMTE2&type=mp4&ts=1470189078&keyframe=0&ep=eyaTGkiFX84H4yfaiT8bZyrgdSQKXJZ0kn7C%2FLY1SMZAPerQnT%2FRzg%3D%3D&sid=9470189076451120621c5&token=4109&ctype=12&ev=1&oip=1875778498"];
    
    NSURL *localM3U8Url = [NSURL URLWithString:videoUrl];
    MPMoviePlayerViewController *mpc = [[MPMoviePlayerViewController alloc] initWithContentURL:localM3U8Url];
    
    [self presentViewController:mpc animated:YES completion:nil];
}
-(void)dealloc
{
    [[HTTPServerManager shareInstance] stopHTTPServer];
}
@end
