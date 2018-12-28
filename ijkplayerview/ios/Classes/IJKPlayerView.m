//
//  IJKPlayerView.m
//  BasePlayerView
//
//  Created by 划落永恒 on 2018/12/22.
//  Copyright © 2018 xiaocan. All rights reserved.
//

#import "IJKPlayerView.h"
#import <MediaPlayer/MediaPlayer.h>

typedef NS_ENUM(NSInteger,TouhGestureType){
    TouhGestureType_Brightness = 0, /**< 亮度调节 */
    TouhGestureType_Volume,         /**< 音量调节 */
    ToucGestureType_Invalid,        /**< 无效 */
    TouhGestureType_None,           /**< 未知 */
};

@interface IJKPlayerView()

@property(nonatomic, strong, readwrite) NSURL *url;
@property(nonatomic, assign, readwrite) BOOL isPlaying;
@property(nonatomic, assign, readwrite) BOOL lastPlayStatus; /**< YES：play，NO：pause */

@property(nonatomic, strong) UIActivityIndicatorView *loadView; /**< 视频load状态提示 */

//音量设置
@property(nonatomic, strong) MPVolumeView           *volumeView;/**< 音量调节 */
@property(nonatomic, strong) UISlider               *volumeSlider;
//手势相关
@property (nonatomic, assign) CGPoint           lastTouchPoint;
@property (nonatomic, assign) TouhGestureType   touchType;  /**< 手势功能 */

//前后台
@property (nonatomic, assign) BOOL              isActivity;

@property (nonatomic, assign) CGRect superBounds;
@property (nonatomic, strong) IJKPlayerView *fullScreenView;

@end

@implementation IJKPlayerView

- (UISlider *)volumeSlider{
    if (!_volumeSlider) {
        for (UIView *subView in _volumeView.subviews) {
            if ([subView.class.description isEqualToString:@"MPVolumeSlider"]) {
                self.volumeSlider = (UISlider *)subView;
                break;
            }
        }
    }
    return _volumeSlider;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.superBounds = self.bounds;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor blackColor];
        _isActivity = YES;
        
        _lastTouchPoint = CGPointZero;
        _touchType = TouhGestureType_None;

        _loadView = [[UIActivityIndicatorView alloc]init];
        _loadView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        _loadView.hidesWhenStopped = YES;
        [self addSubview:_loadView];
        
        _volumeView = [[MPVolumeView alloc]initWithFrame:CGRectMake(10, 10, 100, 40)];
        [self addSubview:_volumeView];
        _volumeView.hidden = YES;
        
        [self installMovieNotificationObservers];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenStatusBarChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGestured:)];
        [self addGestureRecognizer:panGesture];
        
    }
    return self;
}

- (void)playWithUrl:(NSURL *)playUrl withHeaderInfos:(NSDictionary *)headerInfo{
    [self.loadView startAnimating];
    self.lastPlayStatus = NO;
    self.url = playUrl;
    if (self.player) {
        [self shutDown];
    }
#ifdef DEBUG
    [IJKFFMoviePlayerController setLogReport:YES];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];
#else
    [IJKFFMoviePlayerController setLogReport:NO];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
#endif
    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:NO];
    
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    if (headerInfo && [headerInfo isKindOfClass:[NSDictionary class]]) {
        NSArray *keyArr = [headerInfo allKeys];
        for (NSString *keyStr in keyArr) {
            if ([[headerInfo objectForKey:keyStr] isKindOfClass:[NSString class]]) {
                [options setFormatOptionValue:[headerInfo objectForKey:keyStr] forKey:keyStr];
            }
        }
    }
    [options setPlayerOptionIntValue:60  forKey:@"max-fps"];
    [options setPlayerOptionIntValue:30 forKey:@"r"];
    //跳帧开关
    [options setPlayerOptionIntValue:1  forKey:@"framedrop"];
    [options setPlayerOptionIntValue:0  forKey:@"start-on-prepared"];
    [options setPlayerOptionIntValue:0  forKey:@"http-detect-range-support"];
    [options setPlayerOptionIntValue:48  forKey:@"skip_loop_filter"];
    [options setPlayerOptionIntValue:0  forKey:@"packet-buffering"];
    [options setPlayerOptionIntValue:2000000 forKey:@"analyzeduration"];
    [options setPlayerOptionIntValue:25  forKey:@"min-frames"];
    [options setPlayerOptionIntValue:1  forKey:@"start-on-prepared"];
    [options setCodecOptionIntValue:8 forKey:@"skip_frame"];
    [options setFormatOptionValue:@"nobuffer" forKey:@"fflags"];
    [options setFormatOptionValue:@"8192" forKey:@"probsize"];
    //自动转屏开关
    [options setFormatOptionIntValue:1 forKey:@"auto_convert"];
    //重连次数
    [options setFormatOptionIntValue:5 forKey:@"reconnect"];
    //开启硬解码
    [options setPlayerOptionIntValue:1  forKey:@"videotoolbox"];
    
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:self.url withOptions:options];
    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    self.player.shouldAutoplay = YES;
    
    self.autoresizesSubviews = YES;
    [self insertSubview:self.player.view atIndex:0];
    
    [self.player prepareToPlay];
}
- (void)layoutSubviews{
    [super layoutSubviews];
    self.loadView.center = self.center;
    self.player.view.frame = self.bounds;
}
#pragma mark- 播放器方法
- (void)pause{
    [self.player pause];
}
- (void)resume{
    self.player.currentPlaybackTime = 0.f;
    [self.player pause];
}

- (void)play{
    [self.player play];
}

- (void)shutDown{
    [self.player.view removeFromSuperview];
    [self.player shutdown];
}

- (void)changePlayStatus{
    if (self.isPlaying) {
        [self pause];
    }else{
        [self play];
    }
}

- (void)setCurrentPlayBackTime:(double)playTime{
    self.player.currentPlaybackTime = playTime;
}

#pragma mark-
#pragma mark- 播放器手势
- (void)panGestured:(UIPanGestureRecognizer *)gesture{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:{
            _lastTouchPoint = [gesture locationInView:self];
        }
            break;
        case UIGestureRecognizerStateChanged:{
            CGPoint currentPoint = [gesture locationInView:self];
            CGFloat changeX = currentPoint.x - _lastTouchPoint.x;
            CGFloat changeY = currentPoint.y - _lastTouchPoint.y;
            if (_touchType == TouhGestureType_None) {
                if (ABS(changeX) > ABS(changeY)) {//左右滑动
                    
                }else{//上下滑动
                    if (_lastTouchPoint.x <= self.bounds.size.width * 0.3) {
                        _touchType = TouhGestureType_Brightness;
                    }else if (_lastTouchPoint.x >= self.bounds.size.width * 0.7){
                        _touchType = TouhGestureType_Volume;
                    }else{
                        _touchType = ToucGestureType_Invalid;
                    }
                }
            }else{
                CGPoint velocityPoint = [gesture velocityInView:self];
             //   CGFloat velocityX = velocityPoint.x / self.bounds.size.width;
                CGFloat velocityY = velocityPoint.y / self.bounds.size.height;
                
                if (_touchType == TouhGestureType_Brightness) {//亮度
                    CGFloat bright = [UIScreen mainScreen].brightness - velocityY / 20.0;
                    [[UIScreen mainScreen] setBrightness:bright];
                }else if (_touchType == TouhGestureType_Volume){//音量
                    self.volumeSlider.value = self.volumeSlider.value - velocityY / 20.0;
                }
            }
            _lastTouchPoint = currentPoint;
        }
            break;
        default:
            _lastTouchPoint = CGPointZero;
            _touchType = TouhGestureType_None;
            break;
    }
}


#pragma mark-
#pragma mark- 播放器通知方法
//加载状态变化
- (void)loadStateDidChange:(NSNotification*)notification{
    
    IJKMPMovieLoadState loadState = _player.loadState;
    
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {//加载完成
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStatePlaythroughOK: %d\n", (int)loadState);
        [_loadView stopAnimating];
    } else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {//加载停滞
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
        [_loadView startAnimating];
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)moviePlayBackDidFinish:(NSNotification*)notification{
    int reason = [[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    
    switch (reason){
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            break;
            
        case IJKMPMovieFinishReasonPlaybackError://视频播放出错
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            break;
            
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

//初始化完成、即将播放
- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification{
    NSLog(@"mediaIsPreparedToPlayDidChange\n");

}

//播放状态更改
- (void)moviePlayBackStateDidChange:(NSNotification*)notification{
    switch (_player.playbackState){
        case IJKMPMoviePlaybackStateStopped: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStatePlaying: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStatePaused: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateInterrupted: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}

#pragma mark- 应用进入前后台
- (void)appWillEnterForeground:(NSNotification *)notifi{
    _isActivity = YES;
    if (_lastPlayStatus && !self.isPlaying) {
        [_player play];
    }
}
- (void)appDidEnterBackground:(NSNotification *)notifi{
    _lastPlayStatus = self.isPlaying;
    if (_lastPlayStatus) {
        [_player pause];
    }
    _isActivity = NO;
}
- (void)screenStatusBarChanged:(NSNotification *)notifi{
    if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait){
        if (_fullScreenView) {
            self.player = _fullScreenView.player;
            [self insertSubview:self.player.view atIndex:0];
            [_fullScreenView removeFromSuperview];
            _fullScreenView = nil;
        }
    }else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
        self.superBounds = self.bounds;
        if (!_fullScreenView) {
            _fullScreenView = [[IJKPlayerView alloc] initWithFrame:[UIScreen mainScreen].bounds];
            _fullScreenView.player = self.player;
            [_fullScreenView addSubview:_fullScreenView.player.view];
            [[UIApplication sharedApplication].keyWindow addSubview:_fullScreenView];
        }else{
            _fullScreenView.player.view.frame = [UIScreen mainScreen].bounds;
        }
    }
}
#pragma mark- 播放状态
- (BOOL)isPlaying{
    return [_player isPlaying];
}
- (void)setBackgroundColor:(UIColor *)backgroundColor{
    [super setBackgroundColor:[UIColor blackColor]];
}
#pragma mark- 播放器通知
- (void)installMovieNotificationObservers{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadStateDidChange:) name:IJKMPMoviePlayerLoadStateDidChangeNotification object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:) name:IJKMPMoviePlayerPlaybackDidFinishNotification object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaIsPreparedToPlayDidChange:) name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackStateDidChange:) name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:_player];
}

- (void)removeMovieNotificationObservers{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerLoadStateDidChangeNotification object:_player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackDidFinishNotification object:_player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification object:_player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:_player];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}

- (void)dealloc{
    [self removeMovieNotificationObservers];
}

@end
