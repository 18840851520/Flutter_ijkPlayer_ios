//
//  IJKPlayerView.m
//  ijkplayerview
//
//  Created by 划落永恒 on 2018/12/22.
//

#import "FlutterIJKPlayerView.h"
#import "IJKPlayerView.h"

#pragma mark IJKPlayerViewFactory
@implementation FlutterIJKPlayerViewFactory{
    NSObject<FlutterBinaryMessenger>* _messenger;
}
- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    self = [super init];
    if (self) {
        _messenger = messenger;
    }
    return self;
}
- (NSObject<FlutterMessageCodec>*)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}
- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
    FlutterIJKPlayerView *flutterIjk = [[FlutterIJKPlayerView alloc] initWithWithFrame:frame viewIdentifier:viewId arguments:args binaryMessenger:_messenger];
    return flutterIjk;
}

@end

#pragma mark IJKPlayerView
@interface FlutterIJKPlayerView(){
    int64_t _viewId;
    FlutterMethodChannel* _channel;
    id args;
}
@property (nonatomic, strong) IJKPlayerView *ijkPlayerView;
@property(nonatomic, strong, readwrite) NSURL *url;

@end

@implementation FlutterIJKPlayerView

-(UIView *)view{
    return _ijkPlayerView;
}
- (instancetype)initWithWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger{
    if ([super init]) {
        _viewId = viewId;
        _ijkPlayerView = [[IJKPlayerView alloc] initWithFrame:frame];
        NSString *channelName = [NSString stringWithFormat:@"com.gmi.video.player.channel"];
        _channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
        __weak typeof(self)weakSelf = self;
        [_channel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
            [weakSelf onMethodCall:call result:result];
        }];
    }
    return self;
}
#pragma mark -
- (void)onMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result{
    NSString *method = [call method];
    if ([method isEqualToString:@"initPlayer"]) {
        
    }else if ([method isEqualToString:@"setVideoUrl"]) {
        [_ijkPlayerView playWithUrl:[NSURL URLWithString:method] withHeaderInfos:@{}];
    }else if ([method isEqualToString:@"isPlaying"]) {
        result([NSNumber numberWithBool:_ijkPlayerView.isPlaying]);
    }else if ([method isEqualToString:@"start"]) {
        [_ijkPlayerView play];
    }else if ([method isEqualToString:@"stop"]) {
        [_ijkPlayerView pause];
    }else if ([method isEqualToString:@"reStart"]) {
        [_ijkPlayerView resume];
    }else if ([method isEqualToString:@"dispose"]) {
        [_ijkPlayerView shutDown];
    }
}

@end
