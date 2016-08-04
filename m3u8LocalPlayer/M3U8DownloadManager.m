//
//  M3U8DownloadManager.m
//  m3u8LocalPlayer
//
//  Created by JokerAtBaoFeng on 8/3/16.
//  Copyright © 2016 joker. All rights reserved.
//

#import "M3U8DownloadManager.h"
#import <M3U8Kit/M3U8Kit.h>
#import <M3U8Kit/NSString+m3u8.h>
#import "M3U8PlayerControllerViewController.h"

@interface M3U8DownloadManager()
<
NSURLConnectionDataDelegate
>

@property (nonatomic, strong) NSMutableString *m3u8List;
@property (nonatomic, strong) NSMutableArray *urls;
@property (nonatomic, strong) NSMutableArray *names;

@property (nonatomic, strong) NSMutableData *revcData;
@property (nonatomic, strong) NSMutableData *contentData;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLConnection *contentConnection;

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) NSString *savePath;
@property (nonatomic, strong) NSString *fileFolder;

@end

@implementation M3U8DownloadManager

-(instancetype)init{
    if(self = [super init])
    {
        _urls = [NSMutableArray new];
        _names = [NSMutableArray new];
        _revcData = [NSMutableData data];
        _contentData = [NSMutableData data];
    }
    return self;
}

-(void)dealloc
{
    [_connection cancel];
    [_contentConnection cancel];
}

-(void)downloadM3U8WithFile:(NSString *)URL
{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:URL]];
    
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    [self.connection start];
}

-(void)parser:(NSString *)txt withURL:(NSURL *)URL
{
    M3U8SegmentInfoList *list = [txt m3u8SegementInfoListValueRelativeToURL:URL];
    
    NSLog(@"%@",@(list.count));
    
    for(int i = 0; i < list.count; i++)
    {
        M3U8SegmentInfo *info = [list segmentInfoAtIndex:i];
        NSLog(@"%@", info.URI);
        
        NSURL *infoURI = [NSURL URLWithString:info.URI];
        NSString *fileRelatePath = [infoURI relativePath];
        NSString *fileName = [[fileRelatePath componentsSeparatedByString:@"/"] lastObject];
        fileName = [NSString stringWithFormat:@"%@_%@",@(i),fileName];
        [self.names addObject:fileName];
        [self.urls addObject:info.URI];
    }
    
    NSArray *items = [URL.lastPathComponent componentsSeparatedByString:@"."];
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    self.fileFolder = [NSString stringWithFormat:@"%@/%@",path,[items firstObject]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    BOOL isDirectoryExist;
    [fm fileExistsAtPath:self.fileFolder isDirectory:&isDirectoryExist];
    
   
    if(isDirectoryExist){
        NSError *error;
        [fm removeItemAtPath:self.fileFolder error:&error];
        if(error)
        {
            NSLog(@"remove files faile:%@",error.description);
        }
        
    }
    NSError *error;
    [fm createDirectoryAtPath:self.fileFolder withIntermediateDirectories:YES attributes:nil error:&error];
    
    if(error)
    {
        NSLog(@"create directory failed! %@", error.description);
    }
    
    [self createM3u8ListFile:[self.fileFolder copy]];
    
    NSLog(@"%@", self.fileFolder);
    
    [self.connection cancel];
    
    [self downloadTS:[self.fileFolder copy]];
    
}

//创建m3u8列表
- (void)createM3u8ListFile:(NSString *)savePath
{
    NSString *tempM3U8List = self.m3u8List;
    for (int i = 0; i < self.urls.count; i++) {
        NSURL * url = [NSURL URLWithString:self.urls[i]];
        
        NSString *siteStr;
        if([url port]){
            siteStr = [NSString stringWithFormat:@"%@://%@:%@%@",[url scheme],[url host],[url port],[url relativePath]];
        }else
        {
            siteStr = [NSString stringWithFormat:@"%@://%@%@",[url scheme],[url host],[url relativePath]];
        }
        
        NSString *replaceStr = [NSString stringWithFormat:@"%@/%@",kLocalLoopURL,self.names[i]];
        NSString *localSiteStr = [self.urls[i] stringByReplacingOccurrencesOfString:siteStr withString:replaceStr];
        
        tempM3U8List = [tempM3U8List stringByReplacingOccurrencesOfString:self.urls[i] withString:localSiteStr];
    }
    
    self.m3u8List = [NSMutableString stringWithString:tempM3U8List];
    
    //将m3u8写到文件夹
    [self writeM3u8List];
}
- (void)writeM3u8List
{
    NSData *data = [self.m3u8List dataUsingEncoding: NSUTF8StringEncoding];
    
    NSString *fileName = @"m3u8List.m3u";
    
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",self.fileFolder,fileName];
    
    BOOL is = [data writeToFile:filePath atomically:YES];
    
    NSLog(@"%d",is);
}
- (void)downloadTS:(NSString *)savePath
{
    if (self.urls.count>0) {
        
        [self requestWithIndex:0 savePath:savePath];
    }
}

- (void)requestWithIndex:(NSInteger)index savePath:(NSString *)savePath
{
    self.index = index;
    self.savePath = savePath;
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.urls[self.index]]];
    
    self.contentConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    [self.contentConnection start];
}
#pragma mark - NSURLConnectionDataDelegate
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if(connection == self.connection){
        
        [self.revcData appendData:data];
        
    }else if(connection == self.contentConnection)
    {
        [self.contentData appendData:data];
    }
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if(connection == self.connection){
        self.m3u8List = [[NSMutableString alloc] initWithData:self.revcData encoding:NSUTF8StringEncoding];
        
        if(self.m3u8List)
        {
            [self parser: self.m3u8List withURL:[[connection originalRequest] URL]];
        }
    }
    else if(connection == self.contentConnection)
    {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@",self.savePath,self.names[self.index]];
        
        NSMutableData *currentData = [NSMutableData dataWithContentsOfFile:filePath];
        
        if (currentData ==nil) {
            currentData = [[NSMutableData alloc] init];
        }
        
        [currentData appendData:self.contentData];
        
        BOOL success = [currentData writeToFile:filePath atomically:YES];
        
        if (success) {
            self.index += 1;
            
            if (self.index < self.urls.count) {
                
                [self requestWithIndex:self.index savePath:self.savePath];
                NSLog(@"下载第%@个视频段",@(self.index));
            }
            
            //下载完成
            if(self.index == self.urls.count)
            {
                NSLog(@"**** 下载完成所有视频段 ****");
            }
        }else
        {
            NSLog(@"写入下载文件失败");
        }

    }
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"download failed! %@", error.description);
}
@end
