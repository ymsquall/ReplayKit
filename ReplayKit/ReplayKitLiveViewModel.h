#import <UIKit/UIKit.h>
#import "ReplayKit/ReplayKit.h"
#import "ReplayKitLiveView.h"

@class ReplayKitLiveViewModel;

@protocol ReplayKitLiveViewModelDelegate<NSObject>

@optional

- (void)rpliveStarted;                              // 直播开启了的事件
- (void)rpliveStoppedWithError:(NSError *)error;    // 直播结束了的事件
- (void)rplivePaused;                               // 直播已暂停

@end

@interface ReplayKitLiveViewModel : NSObject<RPBroadcastActivityViewControllerDelegate, RPBroadcastControllerDelegate>

// start前可以设置的属性
@property (weak, nonatomic) id<ReplayKitLiveViewModelDelegate> delegate;            // 代理方法
@property (assign, nonatomic, getter=isCameraEnabled) BOOL cameraEnabled;           // 开启摄像头(内部自动提示获取权限)，同时反映权限状态，支持KVO
@property (assign, nonatomic, getter=isMicrophoneEnabled) BOOL microphoneEnabled;   // 开启麦克风(内部自动提示获取权限)，同时反映权限状态，支持KVO

// start之后可以访问的属性、可以监听的状态变化
//@property (readonly, weak, nonatomic) UIView *cameraPreview;            // 摄像头的预览画面
@property (readonly, copy, nonatomic) NSURL *broadcastURL;              // 用来分享的直播地址
@property (readonly, copy, nonatomic) NSURL *chatURL;                   // 用来展示聊天的URL地址，支持KVO
@property (readonly, assign, nonatomic, getter=isLiving) BOOL living;   // 查询是否正在直播，支持KVO
@property (readonly, assign, nonatomic, getter=isPaused) BOOL paused;   // 直播是否暂停了(注意：只有正在直播才有是否暂停的状态)，支持KVO

@property (strong, nonatomic, retain) UIViewController *ownerViewController;
@property (strong, nonatomic, retain) ReplayKitLiveView *liveView;

+ (instancetype)Instance;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithViewController:(UIViewController *)vc NS_DESIGNATED_INITIALIZER;
- (void)showFloatWindow;
- (void)start;                                                      // 开启直播
- (void)pause;                                                      // 暂停直播
- (void)resume;                                                     // 恢复直播
- (void)stop;                                                       // 停止直播

@end
