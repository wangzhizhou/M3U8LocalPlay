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

@interface M3U8PlayerControllerViewController () <M3U8DownloadManagerDelegate>

@property (nonatomic ,strong)   NSString *m3u8VideoLocalUrl;
@property (nonatomic, strong)   UIActivityIndicatorView *downloadIndicator;
@property (nonatomic, strong)   M3U8DownloadManager *downloader;
@property (nonatomic, strong)   UILabel *countLabel;
@end

@implementation M3U8PlayerControllerViewController


-(void)setupView
{
    UIButton *downloadBtn = [[UIButton alloc]initWithFrame:CGRectMake((self.view.bounds.size.width - 200)/2.0, 100, 200, 100)];
    downloadBtn.backgroundColor = [UIColor greenColor];
    
    [downloadBtn addTarget:self action:@selector(download) forControlEvents:UIControlEventTouchUpInside];
    
    [downloadBtn setTitle:@"下载视频到本地" forState:UIControlStateNormal];
    
    [self.view addSubview:downloadBtn];
    
    
    UIButton *playBtn = [[UIButton alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 200)/2.0, 250, 200, 100)];
    playBtn.backgroundColor = [UIColor redColor];
    
    [playBtn addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    
    [playBtn setTitle:@"播放本地视频" forState:UIControlStateNormal];
    
    [self.view addSubview:playBtn];
    
    
    UIButton *clearCacheBtn = [[UIButton alloc]initWithFrame:CGRectMake((self.view.bounds.size.width - 200)/2.0, CGRectGetMaxY(playBtn.frame) + 50, 200, 100)];
    clearCacheBtn.backgroundColor = [UIColor blueColor];
    
    [clearCacheBtn addTarget:self action:@selector(clearCahceBtnPress) forControlEvents:UIControlEventTouchUpInside];
    
    [clearCacheBtn setTitle:@"清除所有缓存" forState:UIControlStateNormal];
    
    [self.view addSubview:clearCacheBtn];
    
    
    self.downloadIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.downloadIndicator.hidesWhenStopped = YES;
    self.downloadIndicator.color = [UIColor brownColor];
    
    self.downloadIndicator.center = CGPointMake(CGRectGetMinX(downloadBtn.frame) + 30, CGRectGetMinY(downloadBtn.frame) - 30);
    
    [self.view addSubview:self.downloadIndicator];
    
    self.countLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.downloadIndicator.frame) + 20, CGRectGetMinY(self.downloadIndicator.frame),downloadBtn.frame.size.width, self.downloadIndicator.frame.size.height)];
    self.countLabel.textColor = [UIColor blackColor];
    self.countLabel.font = [UIFont boldSystemFontOfSize:24];
    
    [self.view addSubview:self.countLabel];
    
}


- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupView];
    
    self.downloader = [M3U8DownloadManager new];
    self.downloader.delegate = self;
}

-(void)showM3U8UrlEditor
{
    
}

-(void)download
{
    
    [self showM3U8UrlEditor];
    
    [self deleteAllCacheFiles];
    [self showDownloadIndicator];
    
    [self.downloader downloadM3U8WithFile:kSrcURL completeBlock:^(NSString *downloadFileLocalUrl) {
        self.m3u8VideoLocalUrl = downloadFileLocalUrl;
        
        [self hideDownloadIndicator];
        [self showAlert:@"" message:@"视频已缓存到本地"];
        
    } errorBlock:^(NSError *error) {
        [self hideDownloadIndicator];
        [self.downloader cancelDownloadTask];
        [self showAlert:@"" message:@"下载未完成"];
    }];
}
-(void)play
{
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
    [self.downloader cancelDownloadTask];
    [self hideDownloadIndicator];
    
    if([self deleteAllCacheFiles])
    {
        [self showAlert:@"" message:@"已清除所有缓存文件"];
        self.countLabel.text = @"";
            
    }else
    {
        [self showAlert:@"" message:@"没有缓存文件"];
    }
}
-(BOOL)deleteAllCacheFiles
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *cacheDirectory = [self.downloader getDownloadDirectory];
    BOOL isDirectory;
    if([fm fileExistsAtPath:cacheDirectory isDirectory:&isDirectory])
    {
        if(isDirectory)
        {
            NSError *error;
            if([fm removeItemAtPath:cacheDirectory error:&error]){
                return YES;
            }
        }
    }
    return NO;
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
-(void)showAlert:(NSString*)title message:(NSString *)msg
{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alertVC addAction:action];
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma - mark M3U8DownloadManagerDelegate
-(void)currentDownloadRatio:(CGFloat)ratio
{
    self.countLabel.text = [NSString stringWithFormat:@"%5.2f%%", ratio * 100];
}
@end
