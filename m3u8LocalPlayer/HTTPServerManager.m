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

-(NSString *)webRoot{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    
    NSString *web = [NSString stringWithFormat:@"%@/%@",path,@"m3u8"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if(![fm fileExistsAtPath:web])
    {
        [fm createDirectoryAtPath:web withIntermediateDirectories:YES attributes:nil error:nil];
        NSLog(@"The server root directory is: %@", web);
    }
    return web;
}

-(void)startHTTPServer{
    httpServer = [[HTTPServer alloc] init];
    
    [httpServer setType:@"_http._tcp."];
    
    [httpServer setPort:30000];
    
    [httpServer setDocumentRoot:[self webRoot]];
    
    NSError *error;
    
    if([httpServer start:&error])
    {
        NSLog(@"HttpServer is started, port is: %@",@([httpServer listeningPort]));
        NSLog(@"server request site is: http://127.0.0.1:30000");
    }else
    {
        NSLog(@"%@", error.description);
    }
}

-(HTTPServer *)returnHTTPServer{
    if(httpServer ==  nil)
    {
        [self startHTTPServer];
    }
    return httpServer;
}

-(void)stopHTTPServer{
    [httpServer stop];
}

@end
