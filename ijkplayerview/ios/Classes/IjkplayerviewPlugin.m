#import "IjkplayerviewPlugin.h"
#import "FlutterIJKPlayerView.h"

@implementation IjkplayerviewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterIJKPlayerViewFactory *ijkPlayerFactory = [[FlutterIJKPlayerViewFactory alloc] init];
    [registrar registerViewFactory:ijkPlayerFactory withId:@"ijkplayerview"];
//  [SwiftIjkplayerviewPlugin registerWithRegistrar:registrar];
}
@end
