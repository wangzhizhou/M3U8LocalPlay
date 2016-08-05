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

@protocol M3U8DownloadManagerDelegate <NSObject>

-(void)currentDownloadRatio:(CGFloat)ratio;

@end

@interface M3U8DownloadManager : NSObject

@property (nonatomic,weak) id<M3U8DownloadManagerDelegate> delegate;

-(void)downloadM3U8WithFile:(NSString *)URL completeBlock:(CompleteBlock)completeBlock errorBlock:(ErrorBlock)errorBlock;

-(NSString *)getDownloadDirectory;
-(void)cancelDownloadTask;
@end
