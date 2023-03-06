//
//  TXPlayer.m
//  Meta-pcdn-Tutrial-Objective-C
//
//  Created by yoyo on 2023/3/5.
//

#import <TXLiteAVSDK_Professional/V2TXLivePlayer.h>
#import <TXLiteAVSDK_Professional/TXLivePlayer.h>
#import "Masonry.h"
#import "TXPlayer.h"
#define US_V2Player 1

@interface TXPlayer ()<V2TXLivePlayerObserver,TXLivePlayListener,TXVideoCustomProcessDelegate>
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) UIView *playerView;

@property (nonatomic, strong) UILabel *sourceLabel;

@property (nonatomic, strong) UILabel *statisticsLabel;

@property (nonatomic, assign) NSTimeInterval playbtnClickedTime;
@property (nonatomic, assign) NSTimeInterval reciverFirstFrameTime;
#if US_V2Player
@property (strong, nonatomic) V2TXLivePlayer *livePlayer;
#else
@property (nonatomic, strong) TXLivePlayer *livePlayer;
#endif

@property (nonatomic, strong) V2TXLivePlayerStatistics *curStatistics;


@end
@implementation TXPlayer


@synthesize playerType;

@synthesize playURL;

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



- (void)releaseHudView {
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

- (void)updateDataSourceTitle:(NSString *)title {
    self.sourceLabel.text = title;
}

- (void)getVideoInfo {
    NSString *str = @"";

    if (self.reciverFirstFrameTime > 0.0f) {
        str = [NSString stringWithFormat:@"%@\n 首帧时间:%.0f ms \n", str, (self.reciverFirstFrameTime - self.playbtnClickedTime) * 1000.0f];
    }

    if (self.curStatistics) {
        str = [NSString stringWithFormat:@" %@ 帧率: %lu\n 视频码率: %lu\n 音频码率: %lu ", str, self.curStatistics.fps, self.curStatistics.videoBitrate, self.curStatistics.audioBitrate];
    }

    if (self.rtcBoxIp.length > 0) {
        str = [NSString stringWithFormat:@"%@\n box ip: %@", str, self.rtcBoxIp];
    }

    self.statisticsLabel.text = str;
}

- (void)stopTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)pause {
#if US_V2Player
    [self.livePlayer pauseVideo];
    [self.livePlayer pauseAudio];
#else
    [self.livePlayer pause];
#endif
}

- (void)resume {
#if US_V2Player
    [self.livePlayer resumeVideo];
    [self.livePlayer resumeAudio];
#else
    [self.livePlayer resume];
#endif

    
    
}

- (void)play:(nonnull NSString *)url {
    for (UIView * sbv in self.playerView.subviews) {
        [sbv removeFromSuperview];
    }
#if US_V2Player
    if (self.livePlayer) {
        [self.livePlayer pauseVideo];
        [self.livePlayer pauseVideo];
        [self.livePlayer stopPlay];
        self.livePlayer = nil;
    }

    self.playbtnClickedTime = [[NSDate date] timeIntervalSince1970];
    self.reciverFirstFrameTime = -1;
    self.livePlayer = [[V2TXLivePlayer alloc] init];
    [self.livePlayer setCacheParams:0.1 maxTime:5];
    [self.livePlayer setRenderView:self.playerView];
    [self.livePlayer setObserver:self];
    [self.livePlayer startPlay:url];
    
    
    [self.livePlayer showDebugView:YES];
#else
    if (self.livePlayer) {
        [self.livePlayer pause];
        [self.livePlayer stopPlay];
        self.livePlayer = nil;
    }
    self.playbtnClickedTime = [[NSDate date] timeIntervalSince1970];
    self.reciverFirstFrameTime = -1;
    self.livePlayer = [[TXLivePlayer alloc] init];
    self.livePlayer.config =  [[TXLivePlayConfig alloc] init];
    [self.livePlayer startPlay:url type:PLAY_TYPE_LIVE_RTMP];
    self.livePlayer.delegate = self;
    self.livePlayer.videoProcessDelegate = self;
    self.livePlayer.enableHWAcceleration = YES;
    self.livePlayer.isAutoPlay = YES;
    self.livePlayer.isAutoPlay = YES;
    [self.livePlayer setupVideoWidget:self.playerView.bounds containView:self.playerView insertIndex:0];
#endif
    [self startTime];
    self.playURL = url;
}



- (void)stop {
    [self.livePlayer stopPlay];
    self.livePlayer = nil;
}

- (void)onError:(id<V2TXLivePlayer>)player code:(V2TXLiveCode)code message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    NSLog(@" error code %ld msg = %@ extraInfo = %@", (long)code, msg, extraInfo);
}

- (void)onWarning:(id<V2TXLivePlayer>)player code:(V2TXLiveCode)code message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    NSLog(@" Warning code %ld msg = %@ extraInfo = %@", (long)code, msg, extraInfo);
}

- (void)onConnected:(id<V2TXLivePlayer>)player extraInfo:(NSDictionary *)extraInfo {
    NSLog(@" onConnected change %@", extraInfo);
}

- (void)onVideoPlaying:(id<V2TXLivePlayer>)player firstPlay:(BOOL)firstPlay extraInfo:(NSDictionary *)extraInfo {
    if (self.reciverFirstFrameTime <= 0.0f && firstPlay) {
        self.reciverFirstFrameTime = [[NSDate date] timeIntervalSince1970];
    }
}

- (void)onStatisticsUpdate:(id<V2TXLivePlayer>)player statistics:(V2TXLivePlayerStatistics *)statistics {
    //内部统计
    self.curStatistics = statistics;
}

- (void)dealloc {
    [self.livePlayer stopPlay];
    self.livePlayer = nil;
}

- (void)onPlayEvent:(int)evtID withParam:(NSDictionary *)param {
    NSLog(@"onPlayEvent = %@",param);
}

- (void)onNetStatus:(NSDictionary *)param {
    
}
@end
