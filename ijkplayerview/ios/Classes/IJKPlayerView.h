//
//  IJKPlayerView.h
//  BasePlayerView
//
//  Created by 划落永恒 on 2018/12/22.
//  Copyright © 2018 xiaocan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <IJKMediaFramework/IJKMediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface IJKPlayerView : UIView

@property(nonatomic, strong, readonly) NSURL *url;
@property(nonatomic, strong) id<IJKMediaPlayback> player;
@property(nonatomic, assign, readonly) BOOL isPlaying;
@property(nonatomic, assign, readonly) BOOL lastPlayStatus; /**< YES：play，NO：pause */
/** 暂停 */
- (void)pause;
/** 继续 */
- (void)resume;
/** 播放 */
- (void)play;
/** 关闭 */
- (void)shutDown;
/** 播放状态互切 */
- (void)changePlayStatus;
//set player seeking time
- (void)setCurrentPlayBackTime:(double)playTime;
/** 设置播放链接并播放 */
- (void)playWithUrl:(NSURL *)playUrl withHeaderInfos:(NSDictionary *)headerInfo;


@end

NS_ASSUME_NONNULL_END
