//
//  HTTPServerManager.m
//  m3u8LocalPlayer
//
//  Created by JokerAtBaoFeng on 8/2/16.
//  Copyright © 2016 joker. All rights reserved.
//

#import "HTTPServerManager.h"

@implementation HTTPServerManager

+(instancetype)shareInstance{
    static HTTPServerManager *manager;
    static dispatch_once_t once;
    
    if(!manager)
    {
        dispatch_once(&once, ^{
            manager = [[HTTPServerManager alloc] init];
        });
    }
    return manager;
}

-(NSString *)makeValid:(NSString *)rootPath{

    NSFileManager *fm = [NSFileManager defaultManager];
    
    if(![fm fileExistsAtPath:rootPath])
    {
        [fm createDirectoryAtPath:rootPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSLog(@"site directory is %@",rootPath);
    return rootPath;
}

-(void)startHTTPServerWithWebRoot:(NSString *)rootPath portNum:(NSInteger)port{
    httpServer = [[HTTPServer alloc] init];
    
    [httpServer setType:@"_http._tcp."];
    
    [httpServer setPort:port];
    
    [httpServer setDocumentRoot:[self makeValid:rootPath]];
    
    NSError *error;
    
    if(![httpServer isRunning]){
        
        if([httpServer start:&error])
        {
            NSLog(@"HttpServer is started, port is: %@",@([httpServer listeningPort]));
            NSLog(@"server request site is: http://127.0.0.1:30000");
        }else
        {
            NSLog(@"%@", error.description);
        }
    }
}

-(void)stopHTTPServer{
    
    [httpServer stop];
}

@end
