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


typedef NS_ENUM(NSInteger, M3U8DownloadState)
{
    DOWNLOAD_NOT_START,
    DOWNLOAD_URL_LIST_FILE,
    DOWNLOAD_TS_FILE,
    DOWNLOAD_COMPLETE
};

@interface M3U8DownloadManager()
<
NSURLConnectionDataDelegate
>

@property (nonatomic, assign) M3U8DownloadState state;

@property (nonatomic, strong) NSMutableString   *m3u8List;
@property (nonatomic, strong) NSMutableArray    *urls;
@property (nonatomic, strong) NSMutableArray    *names;

@property (nonatomic, strong) NSMutableData     *m3u8ListFileData;
@property (nonatomic, strong) NSMutableData     *videoSliceData;
@property (nonatomic, strong) NSURLConnection   *connection;

@property (nonatomic, assign) NSInteger         index;
@property (nonatomic, strong) NSString          *savePath;
@property (nonatomic, strong) NSString          *fileFolder;
@property (nonatomic, strong) NSString          *m3u8VideoName;
@property (nonatomic, strong) NSString          *m3u8VideoLocalUrl;

@property (nonatomic, strong) CompleteBlock     complete;
@property (nonatomic, strong) ErrorBlock        error;

@end

@implementation M3U8DownloadManager

#pragma - Initialization ad deinitialization function
-(instancetype)init{
    if(self = [super init])
    {
        _state = DOWNLOAD_NOT_START;
        
        _urls = [NSMutableArray new];
        _names = [NSMutableArray new];
        _m3u8ListFileData = [NSMutableData data];
        _videoSliceData = [NSMutableData data];
        
        _index = 0;
    }
    return self;
}
-(void)dealloc{
    [self cancelDownloadTask];
}

#pragma mark - Public Interfaces
-(void)downloadM3U8WithFile:(NSString *)URL completeBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock{
    
    self.complete = completeBlock;
    self.error = errorBlock;
    
    self.state = DOWNLOAD_URL_LIST_FILE;
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:URL]];
    
    if(self.connection)
    {
        [self.connection cancel];
    }
    
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    [self.connection start];
}
-(NSString *)getDownloadDirectory{
    NSString *saveDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    
    return [saveDirectoryPath stringByAppendingString:@"/videoCache"];
}
-(void)cancelDownloadTask{
    [self.connection cancel];
}

#pragma mark - Utility Member Functions
-(BOOL)parserAndWriteToDisk:(NSString *)txt withURL:(NSURL *)URL{
   
    //分析URLs
    M3U8SegmentInfoList *list = [txt m3u8SegementInfoListValueRelativeToURL:URL];
    
    for(int i = 0; i < list.count; i++)
    {
        M3U8SegmentInfo *info = [list segmentInfoAtIndex:i];
        
        NSURL *infoURI = [NSURL URLWithString:info.URI];
        NSString *fileRelatePath = [infoURI relativePath];
        NSString *fileName = [[fileRelatePath componentsSeparatedByString:@"/"] lastObject];
        fileName = [NSString stringWithFormat:@"%@_%@",@(i),fileName];
        
        [self.names addObject:fileName];
        [self.urls addObject:info.URI];
    }
    
    

    //构建保存文件和数据的目录
    self.m3u8VideoName = [[[URL relativePath] componentsSeparatedByString:@"/"] lastObject];
    
    self.fileFolder = [NSString stringWithFormat:@"%@/%@",[self getDownloadDirectory],self.m3u8VideoName];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    BOOL isDirectoryExist;
    [fm fileExistsAtPath:self.fileFolder isDirectory:&isDirectoryExist];
    
    //目录如果已经存在了，就删除原有内容
    if(isDirectoryExist){
        
        NSError *error;
        [fm removeItemAtPath:self.fileFolder error:&error];
        if(error)
        {
            NSLog(@"remove files faile:%@",error.description);
        }
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:kLastDownloadVideoLocalUrl];
        
        
    }
    
    
    NSError *error;
    [fm createDirectoryAtPath:self.fileFolder withIntermediateDirectories:YES attributes:nil error:&error];
    
    if(error)
    {
        NSLog(@"create directory failed! %@", error.description);
    }
    
    //保存M3U8 Url列表文件到磁盘目录
    return [self writeM3u8ListFileToDirectory:[self.fileFolder copy]];
}
-(BOOL)writeM3u8ListFileToDirectory:(NSString *)savePath{
    
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
        
        NSString *localLoopSiteStr = [NSString stringWithFormat:@"%@/%@",kLocalLoopURL,self.names[i]];
        
        NSString *localUrlStr = [self.urls[i] stringByReplacingOccurrencesOfString:siteStr withString:localLoopSiteStr];
        
        tempM3U8List = [tempM3U8List stringByReplacingOccurrencesOfString:self.urls[i] withString:localUrlStr];
    }
    
    self.m3u8List = [NSMutableString stringWithString:tempM3U8List];
    
    
    //将m3u8写到文件夹下
    NSData *data = [self.m3u8List dataUsingEncoding: NSUTF8StringEncoding];
    
    NSString *m3u8ListFileName = [NSString stringWithFormat:@"%@.m3u", self.m3u8VideoName];
    
    self.m3u8VideoLocalUrl = [NSString stringWithFormat:@"%@/%@",self.fileFolder,m3u8ListFileName];
    
    
    BOOL isSaved = [data writeToFile:self.m3u8VideoLocalUrl atomically:YES];
    
    if(isSaved){
        [[NSUserDefaults standardUserDefaults] setObject:self.m3u8VideoLocalUrl forKey:kLastDownloadVideoLocalUrl];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    return isSaved;
    
}
-(void)downloadTS:(NSString *)savePath{
    [self.connection cancel];
    self.state = DOWNLOAD_TS_FILE;
    
    if (self.urls.count>0) {
        
        [self requestTSData];
    }
}
-(void)requestTSData{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.urls[self.index]]];
    
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    [self.connection start];
}


#pragma mark - NSURLConnectionDataDelegate
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    if(DOWNLOAD_URL_LIST_FILE == self.state){
        
        [self.m3u8ListFileData appendData:data];
        
    }else if(DOWNLOAD_TS_FILE == self.state)
    {
        [self.videoSliceData appendData:data];
    }
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    if(DOWNLOAD_URL_LIST_FILE == self.state){
        
        self.m3u8List = [[NSMutableString alloc] initWithData:self.m3u8ListFileData encoding:NSUTF8StringEncoding];
        
        if(self.m3u8List)
        {
            if([self parserAndWriteToDisk: self.m3u8List withURL:[[connection originalRequest] URL]])
            {
                    [self downloadTS:[self.fileFolder copy]];
            }
        }
    }
    else if(DOWNLOAD_TS_FILE == self.state)
    {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@",self.fileFolder,self.names[self.index]];
        
        NSMutableData *currentData = [NSMutableData dataWithContentsOfFile:filePath];
        
        if (currentData ==nil) {
            currentData = [[NSMutableData alloc] init];
        }
        
        [currentData appendData:self.videoSliceData];
        
        BOOL success = [currentData writeToFile:filePath atomically:YES];
        
        if (success) {
            
            self.index += 1;
            
            if (self.index < self.urls.count) {
                
                [self requestTSData];
                
                NSLog(@"下载第%@个视频段",@(self.index));
            }
            
            //下载完成
            if(self.index == self.urls.count)
            {
                self.state = DOWNLOAD_COMPLETE;
                
                if(self.complete)
                {
                    self.complete([self.m3u8VideoLocalUrl copy]);
                }
            }
        }else
        {
            NSLog(@"写入下载文件失败");
        }

    }
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    
    if(self.error)
    {
        self.error(error);
    }
}
@end
