#import "ReplayKitLiveView.h"

#define WIDTH self.frame.size.width
#define HEIGHT self.frame.size.height
#define kScreenWidth [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height

#define animateDuration 0.3         //位置改变动画时间
#define showDuration 0.5            //展开动画时间
#define margin  5                   //间隔
#define liveButtonFixWidth 15
#define liveButtonFixHeight 10

@interface ReplayKitLiveView()

@property (strong, nonatomic) ReplayKitLiveViewModel *liveVM;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIImageView *background;
@property (strong, nonatomic) UIButton *liveButton;
@property (strong, nonatomic) UIButton *pauseButton;
@property (strong, nonatomic) UIButton *micButton;
@property (strong, nonatomic) UIButton *cameraButton;
@property (strong, nonatomic) UIButton *stopButton;

@property(nonatomic)BOOL  isShowTab;
@property(nonatomic)BOOL  isLiveButtonInLeft;
@property(nonatomic,strong)UIPanGestureRecognizer *pan;
@property(nonatomic)CGPoint startPanOffset;
@property(nonatomic)CGFloat contentWidth;

+ (ReplayKitLiveView*)Instance;

@end

static ReplayKitLiveView* _instance = nil;

@implementation ReplayKitLiveView

+ (ReplayKitLiveView*)Instance
{
    return _instance;
}

+ (UIImage *)getImageFromBundle:(NSString *)imgName{
    return [ReplayKitLiveView getImageFromBundle:imgName ext:@"png"];
}

+ (UIImage *)getImageFromBundle:(NSString *)imgName ext:(NSString*)extName
{
    NSString *path = [[ NSBundle mainBundle] pathForResource: @ "image" ofType:@ "bundle"];
    //NSLog(@"%@", path);
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    NSString *img_path = [bundle pathForResource:imgName ofType:extName];
    return [UIImage imageWithContentsOfFile:img_path];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if(_instance)
        return _instance;
    self = [super initWithFrame:frame];
    _instance = self;
    if (self) {
        // Initialization code
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame bgcolor:(UIColor *)bgcolor{
    return  [self initWithFrame:frame bgcolor:bgcolor animationColor:nil];
}

- (instancetype)initWithFrame:(CGRect)frame bgcolor:(UIColor *)bgcolor animationColor:animationColor
{
    if(_instance)
        return _instance;
    if(self = [super initWithFrame:frame])
    {
        _isShowTab = FALSE;

        self.backgroundColor = [UIColor clearColor];
        self.windowLevel = UIWindowLevelAlert + 1;  //如果想在 alert 之上，则改成 + 2
        
        _liveButton =  [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [ReplayKitLiveView getImageFromBundle:@"live_off"];
        [_liveButton setFrame:(CGRect){0, 0, frame.size.width, frame.size.height - (liveButtonFixWidth - liveButtonFixHeight)}];
        [_liveButton setImage:image forState:UIControlStateNormal];
        _liveButton.tag = FloatingButton_Live;
        [_liveButton addTarget:self action:@selector(itemsClick:) forControlEvents:UIControlEventTouchUpInside];
        CGFloat buttonSize = _liveButton.frame.size.width;
        _contentWidth = buttonSize + 4 * (frame.size.width - liveButtonFixWidth + margin) - margin;
        _contentView = [[UIView alloc] initWithFrame:(CGRect){margin, liveButtonFixHeight / 2, 0, buttonSize - liveButtonFixWidth}];
        _contentView.alpha = 0;
        [self addSubview:_contentView];
        //添加按钮
        [self setButtons];
        [self addSubview:_liveButton];
        
        _pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(locationChange:)];
        _pan.delaysTouchesBegan = NO;
        [self addGestureRecognizer:_pan];
        //设备旋转
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
    _instance = self;
    return self;
}

- (BOOL)isWindowShow
{
    return !self.hidden;
}
- (void)dissmissWindow{
    self.hidden = YES;
}
- (void)showWindow{
    self.hidden = NO;
}

- (void)setButtons{
    CGFloat width = WIDTH - liveButtonFixWidth;
    UIImage* image = [ReplayKitLiveView getImageFromBundle:@"live_adorn"];
    image = [image stretchableImageWithLeftCapWidth:image.size.width * 0.35 topCapHeight:image.size.height * 0.5];
    self.background = [[UIImageView alloc] initWithImage:image];
    [self.background setFrame: CGRectMake(0, 0, _liveButton.frame.size.width, _contentView.frame.size.height)];
    [self.contentView addSubview:_background];
    
    CGFloat startPosX = _liveButton.frame.size.width;
    self.pauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.micButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [self.pauseButton setFrame: CGRectMake(startPosX, 0, width, width)];
    [self.micButton setFrame: CGRectMake(startPosX + width + margin, 0, width, width)];
    [self.cameraButton setFrame: CGRectMake(startPosX + (width + margin) * 2, 0, width, width)];
    [self.stopButton setFrame: CGRectMake(startPosX + (width + margin) * 3, 0, width, width)];
    
    [self.cameraButton setImage:[ReplayKitLiveView getImageFromBundle:@"live_camera_on"] forState:UIControlStateNormal];
    [self.micButton setImage:[ReplayKitLiveView getImageFromBundle:@"live_microphone_on"] forState:UIControlStateNormal];
    [self.pauseButton setImage:[ReplayKitLiveView getImageFromBundle:@"live_pause"] forState:UIControlStateNormal];
    [self.stopButton setImage:[ReplayKitLiveView getImageFromBundle:@"live_stop"] forState:UIControlStateNormal];
    
    self.pauseButton.tag = FloatingButton_Pause;
    self.micButton.tag = FloatingButton_Micphone;
    self.cameraButton.tag = FloatingButton_Webcam;
    self.stopButton.tag = FloatingButton_Stop;
    
    [self.pauseButton addTarget:self action:@selector(itemsClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.micButton addTarget:self action:@selector(itemsClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.cameraButton addTarget:self action:@selector(itemsClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.stopButton addTarget:self action:@selector(itemsClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:_pauseButton];
    [self.contentView addSubview:_micButton];
    [self.contentView addSubview:_cameraButton];
    [self.contentView addSubview:_stopButton];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"cameraEnabled"])
    {
        if (self.liveVM.isCameraEnabled) {
            [self.cameraButton setImage:[ReplayKitLiveView getImageFromBundle:@"live_camera_off"] forState:UIControlStateNormal];
        }
        else {
            [self.cameraButton setImage:[ReplayKitLiveView getImageFromBundle:@"live_camera_on"] forState:UIControlStateNormal];
        }
    }
    else if([keyPath isEqualToString:@"microphoneEnabled"])
    {
        if (self.liveVM.isMicrophoneEnabled) {
            [self.micButton setImage:[ReplayKitLiveView getImageFromBundle:@"live_microphone_off"] forState:UIControlStateNormal];
        }
        else {
            [self.micButton setImage:[ReplayKitLiveView getImageFromBundle:@"live_microphone_on"] forState:UIControlStateNormal];
        }
    }
    else if([keyPath isEqualToString:@"living"])
    {
        if (self.liveVM.isLiving) {
            UIImage *liveImage = [ReplayKitLiveView getImageFromBundle:@"live_on"];
            [self.liveButton setImage:liveImage forState:UIControlStateNormal];
            [self onOpenTab];
        }
        else {
            [self.liveButton setImage:[ReplayKitLiveView getImageFromBundle:@"live_off"] forState:UIControlStateNormal];
            [self onCloseTab];
        }
    }
    else if([keyPath isEqualToString:@"paused"])
    {
        if (self.liveVM.isPaused) {
            [self.pauseButton setImage:[ReplayKitLiveView getImageFromBundle:@"live_play"] forState:UIControlStateNormal];
        }
        else {
            [self.pauseButton setImage:[ReplayKitLiveView getImageFromBundle:@"live_pause"] forState:UIControlStateNormal];
        }
    }
}
- (void)setupVMObserver:(ReplayKitLiveViewModel *)liveVM {
    
    self.liveVM = liveVM;
    [self.liveVM addObserver:self forKeyPath:@"cameraEnabled" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self.liveVM addObserver:self forKeyPath:@"microphoneEnabled" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self.liveVM addObserver:self forKeyPath:@"living" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self.liveVM addObserver:self forKeyPath:@"paused" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
}

//改变位置
- (void)locationChange:(UIPanGestureRecognizer*)p
{
    CGPoint panPoint = [p locationInView:[[UIApplication sharedApplication] keyWindow]];
    if(p.state == UIGestureRecognizerStateBegan)
    {
        //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(changeStatus) object:nil];
        self.startPanOffset = CGPointMake(panPoint.x - self.center.x, panPoint.y - self.center.y);
    }
    if(p.state == UIGestureRecognizerStateChanged)
    {
        self.center = CGPointMake(panPoint.x - self.startPanOffset.x
                                  , panPoint.y - self.startPanOffset.y);
    }
    else if(p.state == UIGestureRecognizerStateEnded)
    {
        //[self performSelector:@selector(changeStatus) withObject:nil afterDelay:statusChangeDuration];
        [self fixedBound];
    }
}
/*
- (void)changeStatus
{
    [UIView animateWithDuration:0.5 animations:^{
        CGFloat x = self.center.x < 20+WIDTH/2 ? 0 :  self.center.x > kScreenWidth - 20 -WIDTH/2 ? kScreenWidth : self.center.x;
        CGFloat y = self.center.y < 40 + HEIGHT/2 ? 0 : self.center.y > kScreenHeight - 40 - HEIGHT/2 ? kScreenHeight : self.center.y;
        
        if((x == 0 && y ==0) || (x == kScreenWidth && y == 0) || (x == 0 && y == kScreenHeight) || (x == kScreenWidth && y == kScreenHeight)){
            y = self.center.y;
        }
        self.center = CGPointMake(x, y);
    }];
}
 */

#pragma mark ------- contentview 操作 --------------------
- (void)fixedBound
{
    CGFloat left = WIDTH / 2 + margin;
    CGFloat right = kScreenWidth - (WIDTH / 2 + margin);
    CGFloat top = HEIGHT / 2 + margin;
    CGFloat bottom = kScreenHeight - (HEIGHT / 2 + margin);
    if (self.center.x < left) {
        [UIView animateWithDuration:animateDuration animations:^{
            self.center = CGPointMake(left, self.center.y);
        }];
    }else if (self.center.x > right) {
        [UIView animateWithDuration:animateDuration animations:^{
            self.center = CGPointMake(right, self.center.y);
        }];
    }
    if (self.center.y < top) {
        [UIView animateWithDuration:animateDuration animations:^{
            self.center = CGPointMake(self.center.x, top);
        }];
    }else if (self.center.y > bottom) {
        [UIView animateWithDuration:animateDuration animations:^{
            self.center = CGPointMake(self.center.x, bottom);
        }];
    }
    NSLog(@"self.center=%f,%f", self.center.x,self.center.y);
}
- (void)fadeoutButton:(UIButton*) btn
{
    
}
- (void)fadeinButton:(UIButton*) btn
{
    
}
- (void)onCloseTab
{
    if(!self.isShowTab)
        return;
    self.isShowTab = NO;
    [UIView animateWithDuration:showDuration animations:^{
        _contentView.alpha = 0;
        CGSize buttonSize = self.liveButton.frame.size;
        self.liveButton.frame = CGRectMake(0, 0, buttonSize.width, buttonSize.height);
        _contentView.frame = CGRectMake(margin, liveButtonFixHeight / 2, 0, buttonSize.width - liveButtonFixWidth);
        _background.frame = CGRectMake(0, 0, buttonSize.width, _contentView.frame.size.height);
        
        if (_isLiveButtonInLeft) {
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, HEIGHT, HEIGHT);
        }else{
            self.frame = CGRectMake(self.frame.origin.x + _contentWidth - 2 * margin - buttonSize.width, self.frame.origin.y, HEIGHT, HEIGHT);
        }
    }];
    [self fixedBound];
}
- (void)onOpenTab
{
    if(self.isShowTab)
        return;
    self.isShowTab = YES;
    [UIView animateWithDuration:showDuration animations:^{
        _contentView.alpha = 1;
        CGSize buttonSize = self.liveButton.frame.size;
        if (self.frame.origin.x <= kScreenWidth/2) {
            //按钮在屏幕左边时，contentview恢复默认
            _contentView.frame = CGRectMake(margin, liveButtonFixHeight / 2, _contentWidth, buttonSize.width - liveButtonFixWidth);
            _background.frame = CGRectMake(0, 0, _contentWidth, _contentView.frame.size.height);
            _liveButton.frame = CGRectMake(0, 0, buttonSize.width, buttonSize.height);
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, _contentWidth, HEIGHT);
            _isLiveButtonInLeft = YES;
        }else{
            //按钮在屏幕右边时，左移contentview
            _contentView.frame = CGRectMake(-(buttonSize.width + 2 * margin), liveButtonFixHeight / 2, _contentWidth, buttonSize.width - liveButtonFixWidth);
            _background.frame = CGRectMake(buttonSize.width, 0, _contentWidth, _contentView.frame.size.height);
            _liveButton.frame = CGRectMake(_contentWidth - buttonSize.width - 2 * margin, 0, buttonSize.width, buttonSize.height);
            self.frame = CGRectMake(self.frame.origin.x - _contentWidth / 2 - 2 * margin - buttonSize.width, self.frame.origin.y, _contentWidth, HEIGHT);
            _isLiveButtonInLeft = NO;
        }
    }];
    [self fixedBound];
}
#pragma mark  ------- button事件 ---------
- (void)itemsClick:(id)sender{
    UIButton *button = (UIButton *)sender;
    switch(button.tag)
    {
        case FloatingButton_Live:
            if (!self.liveVM.isLiving) {
                [self.liveVM start];
            }
            else {
                if (self.isShowTab) {
                    [self onCloseTab];
                }
                else {
                    [self onOpenTab];
                }
            }
            break;
        case FloatingButton_Pause:
            if (self.liveVM.isPaused) {
                [self.liveVM resume];
            }
            else {
                [self.liveVM pause];
            }
            break;
        case FloatingButton_Micphone:
            self.liveVM.microphoneEnabled = !self.liveVM.isMicrophoneEnabled;
            break;
        case FloatingButton_Webcam:
            self.liveVM.cameraEnabled = !self.liveVM.isCameraEnabled;
            break;
        case FloatingButton_Stop:
            if (self.liveVM.isLiving) {
                [self.liveVM stop];
            }
            if (self.isShowTab) {
                [self onCloseTab];
            }
            break;
    }
    if (self.clickBolcks) {
        self.clickBolcks((FloatingButtonIndex)button.tag);
    }
}
#pragma mark  ------- 设备旋转 -----------
- (void)orientChange:(NSNotification *)notification{
    //旋转前要先改变frame，否则坐标有问题（临时办法）
    self.frame = CGRectMake(0, kScreenHeight - self.frame.origin.y - HEIGHT, WIDTH, HEIGHT);
}


@end
