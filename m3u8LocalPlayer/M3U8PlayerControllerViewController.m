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
@property (nonatomic ,strong)   NSString *m3u8VideoLocalUrl;

@property (nonatomic, strong)   UIActivityIndicatorView *downloadIndicator;
@end

@implementation M3U8PlayerControllerViewController


-(void)setupView
{
    UIButton *downloadBtn = [[UIButton alloc]initWithFrame:CGRectMake((self.view.bounds.size.width - 200)/2.0, 100, 200, 100)];
    downloadBtn.backgroundColor = [UIColor greenColor];
    
    [downloadBtn addTarget:self action:@selector(download) forControlEvents:UIControlEventTouchUpInside];
    
    [downloadBtn setTitle:@"下载完成后播放" forState:UIControlStateNormal];
    
    [self.view addSubview:downloadBtn];
    
    
    UIButton *playBtn = [[UIButton alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 200)/2.0, 250, 200, 100)];
    playBtn.backgroundColor = [UIColor redColor];
    
    [playBtn addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    
    [playBtn setTitle:@"直接播放本地视频" forState:UIControlStateNormal];
    
    [self.view addSubview:playBtn];
    
    
    UIButton *clearCacheBtn = [[UIButton alloc]initWithFrame:CGRectMake((self.view.bounds.size.width - 200)/2.0, CGRectGetMaxY(playBtn.frame) + 50, 200, 100)];
    clearCacheBtn.backgroundColor = [UIColor blueColor];
    
    [clearCacheBtn addTarget:self action:@selector(clearCahceBtnPress) forControlEvents:UIControlEventTouchUpInside];
    
    [clearCacheBtn setTitle:@"清除所有缓存" forState:UIControlStateNormal];
    
    [self.view addSubview:clearCacheBtn];
    
    
    self.downloadIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.downloadIndicator.hidesWhenStopped = YES;
    
    self.downloadIndicator.center = self.view.center;
    
    [self.view addSubview:self.downloadIndicator];
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupView];
}

-(void)download
{
    [self showDownloadIndicator];
    
    [[M3U8DownloadManager new] downloadM3U8WithFile:kSrcURL completeBlock:^(NSString *downloadFileLocalUrl) {
        self.m3u8VideoLocalUrl = downloadFileLocalUrl;
        
        [self hideDownloadIndicator];
        [self play];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"download failed! %@", error.description);
    }];
}
-(void)play
{
    [[HTTPServerManager shareInstance] stopHTTPServer];

    if(nil == self.m3u8VideoLocalUrl || [self.m3u8VideoLocalUrl isEqualToString:@""])
    {
        self.m3u8VideoLocalUrl = [[NSUserDefaults standardUserDefaults] objectForKey:kLastDownloadVideoLocalUrl];
    }
    
    if(self.m3u8VideoLocalUrl && ![self.m3u8VideoLocalUrl isEqualToString:@""]){
        
        NSString *m3u8FileName = [self.m3u8VideoLocalUrl lastPathComponent];
        
        [[HTTPServerManager shareInstance] startHTTPServerWithWebRoot:[self.m3u8VideoLocalUrl stringByReplacingOccurrencesOfString:m3u8FileName withString:@""] portNum:30000];
        
        NSString *videoUrl = [NSString stringWithFormat:@"%@/%@",kLocalLoopURL, m3u8FileName];
        
        NSURL *localM3U8Url = [NSURL URLWithString:videoUrl];
        MPMoviePlayerViewController *mpc = [[MPMoviePlayerViewController alloc] initWithContentURL:localM3U8Url];
        
        [self presentViewController:mpc animated:YES completion:nil];
    }
}
-(void)clearCahceBtnPress
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *cacheDirectory = [[M3U8DownloadManager new] getDownloadDirectory];
    BOOL isDirectory;
    if([fm fileExistsAtPath:cacheDirectory isDirectory:&isDirectory])
    {
        if(isDirectory)
        {
            NSError *error;
            [fm removeItemAtPath:cacheDirectory error:&error];
        }
    }
    
}
-(void)dealloc
{
    [[HTTPServerManager shareInstance] stopHTTPServer];
}
-(void)showDownloadIndicator
{
    [self.downloadIndicator startAnimating];
}
-(void)hideDownloadIndicator
{
    [self.downloadIndicator stopAnimating];
}
@end
