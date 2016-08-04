//
//  HTTPServerManager.h
//  m3u8LocalPlayer
//
//  Created by JokerAtBaoFeng on 8/2/16.
//  Copyright © 2016 joker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HTTPServer.h>

@interface HTTPServerManager : NSObject
{
    HTTPServer *httpServer;
}

+(instancetype)shareInstance;

-(void)startHTTPServerWithWebRoot:(NSString *)rootPath portNum: (NSInteger)port;
-(void)stopHTTPServer;

@end
