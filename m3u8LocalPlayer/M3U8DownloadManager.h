//
//  M3U8DownloadManager.h
//  m3u8LocalPlayer
//
//  Created by JokerAtBaoFeng on 8/3/16.
//  Copyright © 2016 joker. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^CompleteBlock)(NSString *downloadFileLocalUrl);
typedef void (^ErrorBlock)(NSError *error);

@interface M3U8DownloadManager : NSObject

-(void)downloadM3U8WithFile:(NSString *)URL completeBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock;

-(NSString *)getDownloadDirectory;
-(void)cancelDownloadTask;
@end
