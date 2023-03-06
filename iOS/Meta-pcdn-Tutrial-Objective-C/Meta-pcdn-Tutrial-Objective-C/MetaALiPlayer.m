//
//  PCDNPlayer.m
//  MetaPCDNDemo-Objective-c
//
//  Created by yoyo on 2022/12/3.
//

#import <AliyunPlayer/AliyunPlayer.h>
#import <MetaPCDNKit/MetaPCDNKit.h>
#import "Masonry.h"
#import "MetaALiPlayer.h"
#import "SVProgressHUD.h"

@interface SVProgressHUD ()
- (void)showProgress:(float)progress status:(NSString *)status;
- (void)dismissWithDelay:(NSTimeInterval)delay completion:(SVProgressHUDDismissCompletion)completion;

@end
@interface MetaALiPlayer  ()<AVPDelegate, CicadaRenderingDelegate, AVPEventReportParamsDelegate>

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) AliPlayer *player;
@property (nonatomic, strong) UIView *playerView;

@property (nonatomic, strong) UILabel *sourceLabel;

@property (nonatomic, strong) UILabel *statisticsLabel;

@property (nonatomic, assign) NSTimeInterval playbtnClickedTime;
@property (nonatomic, assign) NSTimeInterval reciverFirstFrameTime;

@property (nonatomic, weak) SVProgressHUD *hudView;

@end
@implementation MetaALiPlayer

@synthesize playURL;

@synthesize playerType;

@synthesize rtcBoxIp;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.playerType = PCDNPlayerTypeCDN;
        self.playerView = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:self.playerView];

        [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.insets(UIEdgeInsetsZero);
        }];

        self.sourceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.sourceLabel.font = [UIFont systemFontOfSize:17];
        self.sourceLabel.textColor = [UIColor systemRedColor];
        self.sourceLabel.textAlignment = NSTextAlignmentCenter;

        [self addSubview:self.sourceLabel];
        [self.sourceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.mas_equalTo(0);
            make.height.mas_equalTo(30);
        }];

        self.statisticsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.statisticsLabel.font = [UIFont systemFontOfSize:14];
        self.statisticsLabel.numberOfLines = 0;
        self.statisticsLabel.textColor = [UIColor whiteColor];
        self.statisticsLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:self.statisticsLabel];

        [self.statisticsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.mas_equalTo(0);
            make.width.equalTo(self).dividedBy(1);
            make.height.mas_equalTo(200);
        }];

        self.statisticsLabel.backgroundColor = [UIColor clearColor];
    }

    return self;
}

- (void)play:(NSString *)url {
    self.playbtnClickedTime = [[NSDate date] timeIntervalSince1970];

    if (self.player) {
        self.player.renderingDelegate = nil;
        self.player.delegate = nil;
        [self.player pause];
        [self.player stop];
    }

    if (!self.player) {
        self.player = [[AliPlayer alloc] init];
        self.player.enableHardwareDecoder = NO;
        self.player.playerView = self.playerView;
        self.player.loop = YES;

        if (self.playerType == PCDNPlayerTypePCDN) {
            //先获取配置
            AVPConfig *config = [self.player getConfig];
            //最大延迟。注意：直播有效。当延时比较大时，播放器SDK内部会追帧等，保证播放器的延时在这个范围内。
            config.maxDelayTime = 5000;
            // 最大缓冲区时长。单位ms。播放器每次最多加载这么长时间的缓冲数据。
            config.maxBufferDuration = 50000;
            //高缓冲时长。单位ms。当网络不好导致加载数据时，如果加载的缓冲时长到达这个值，结束加载状态。
            config.highBufferDuration = 500;
            // 起播缓冲区时长。单位ms。这个时间设置越短，起播越快。也可能会导致播放之后很快就会进入加载状态。
            config.startBufferDuration = 10;

            config.mMAXBackwardDuration = 0;
            [self.player setConfig:config];
        } else {
            //先获取配置
            AVPConfig *config = [self.player getConfig];
            //最大延迟。注意：直播有效。当延时比较大时，播放器SDK内部会追帧等，保证播放器的延时在这个范围内。
            config.maxDelayTime = 5000;
            // 最大缓冲区时长。单位ms。播放器每次最多加载这么长时间的缓冲数据。
            config.maxBufferDuration = 50000;
            //高缓冲时长。单位ms。当网络不好导致加载数据时，如果加载的缓冲时长到达这个值，结束加载状态。
            config.highBufferDuration = 3000;
            // 起播缓冲区时长。单位ms。这个时间设置越短，起播越快。也可能会导致播放之后很快就会进入加载状态。
            config.startBufferDuration = 500;
            //
            config.mMAXBackwardDuration = 0;

            [self.player setConfig:config];
        }
    }

    self.playURL = url;
    self.player.delegate = self;
    self.player.renderingDelegate = self;
    self.player.eventReportParamsDelegate = self;
    self.reciverFirstFrameTime = -1.0f;
    AVPUrlSource *urlSource = [[AVPUrlSource  alloc] urlWithString:url];
    [self.player setUrlSource:urlSource];
    self.player.autoPlay = YES;
    [self.player prepare];
    [self.player start];
    [self startTime];
}

- (void)stop {
    [self.player pause];
    [self.player stop];
}

- (void)releaseHudView {
}

- (void)dealloc {
    [[MetaPCDNClient shareClientConfig:[[MetaPCDNClientConfig alloc] init]] destoryLocalStream:self.playURL];
    [self.player pause];
    [self.player stop];
    [self.player destroy];
    self.player = nil;
}

- (void)updateDataSourceTitle:(NSString *)title {
    self.sourceLabel.text = title;
}

- (void)startTime {
    [self stopTimer];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(timeRefresh:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)timeRefresh:(NSTimer *)timer {
    [self getVideoInfo];
}

- (void)stopTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)getVideoInfo {
    //获取当前渲染的帧率，数据类型为Float。
    NSString *fps =   [NSString stringWithFormat:@"%ld", [[self.player getOption:AVP_OPTION_RENDER_FPS] integerValue]];
    //获取当前播放的视频码率，数据类型为Float，单位为bps。
    NSString *video_bitrate =  [NSString stringWithFormat:@"%.2f kbs", [[self.player getOption:AVP_OPTION_VIDEO_BITRATE] floatValue] / 1000];
    //获取当前播放的音频码率，数据类型为Float，单位为bps。
    NSString *audio_bitrate =  [NSString stringWithFormat:@"%.2f kbs", [[self.player getOption:AVP_OPTION_AUDIO_BITRATE] floatValue] / 1000];
    //获取当前的网络下行码率，数据类型为Float，单位为bps。
    NSString *download_bitrate = [NSString stringWithFormat:@"%.2f kbs", [[self.player getOption:AVP_OPTION_DOWNLOAD_BITRATE] floatValue] / 1000];
    NSString *str = @"";
    if (self.reciverFirstFrameTime > 0.0f) {
        str = [NSString
                         stringWithFormat:@" 帧率: %@\n 视频码率: %@\n 音频码率: %@ \n 网络下行码率: %@ \n 首帧时间:%.0f ms", fps, video_bitrate, audio_bitrate, download_bitrate, (self.reciverFirstFrameTime - self.playbtnClickedTime) * 1000.0f];
    } else {
       str = [NSString stringWithFormat:@" 帧率: %@\n 视频码率: %@\n 音频码率: %@ \n 网络下行码率: %@ ", fps, video_bitrate, audio_bitrate, download_bitrate];
    }
    if(self.rtcBoxIp.length > 0) {
        str = [NSString stringWithFormat:@"%@\n box ip: %@",str,self.rtcBoxIp];
    }
    self.statisticsLabel.text = str;
}

- (void)onPlayerEvent:(AliPlayer *)player eventType:(AVPEventType)eventType {
    NSLog(@" onPlayerEvent type = %d",eventType);
    switch (eventType) {
        case AVPEventPrepareDone: {
            // 准备完成
        }
        break;

        case AVPEventAutoPlayStart:
            // 自动播放开始事件
            break;

        case AVPEventFirstRenderedStart:
            // 首帧显示
            [self.hudView dismissWithDelay:0.0 completion:nil];

            if (self.reciverFirstFrameTime <= 0.0f) {
                self.reciverFirstFrameTime = [[NSDate date] timeIntervalSince1970];
            }

            [self getVideoInfo];
            NSLog(@"onPlayerEvent  url %@  fisrt frame time : %2.f", self.playURL, (self.reciverFirstFrameTime - self.playbtnClickedTime) * 1000.0f);
            break;

        case AVPEventCompletion:
            // 播放完成
            break;

        case AVPEventLoadingStart:
            // 缓冲开始
            break;

        case AVPEventLoadingEnd:
            // 缓冲完成
            break;

        case AVPEventSeekEnd:
            // 跳转完成
            break;

        case AVPEventLoopingStart:
            // 循环播放开始
            break;

        default:
            break;
    }
}

- (void)pause {
    [self.player pause];
}
- (void)resume {
    [self.player prepare];
    [self.player start];
}

- (void)onPlayerEvent:(AliPlayer *)player eventWithString:(AVPEventWithString)eventWithString description:(NSString *)description {
    NSLog(@"player url = %@  event = %lu descr = %@", self.playURL, (unsigned long)eventWithString, description);
}

- (void)onError:(AliPlayer *)player errorModel:(AVPErrorModel *)errorModel {
    NSLog(@"player url = %@ error code  = %ld  error msg = %@", self.playURL, errorModel.code, errorModel.message);
    [self play:self.playURL];
}

- (void)onEventReportParams:(NSDictionary<NSString *, NSString *> *)params {
//    NSLog(@"player url = %@  report params = %@",self.playURL,[params description]);
}

- (void)onSEIData:(AliPlayer *)player type:(int)type data:(NSData *)data {
    NSString *sei = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    NSLog(@"recive sei type %d  data = %@", type, sei);
}

@end
