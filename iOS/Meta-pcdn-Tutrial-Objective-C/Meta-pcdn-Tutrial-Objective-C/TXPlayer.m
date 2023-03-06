//
//  TXPlayer.m
//  Meta-pcdn-Tutrial-Objective-C
//
//  Created by yoyo on 2023/3/5.
//

#import <TXLiteAVSDK_Professional/V2TXLivePlayer.h>
#import "Masonry.h"
#import "TXPlayer.h"
@interface TXPlayer ()<V2TXLivePlayerObserver>
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) UIView *playerView;

@property (nonatomic, strong) UILabel *sourceLabel;

@property (nonatomic, strong) UILabel *statisticsLabel;

@property (nonatomic, assign) NSTimeInterval playbtnClickedTime;
@property (nonatomic, assign) NSTimeInterval reciverFirstFrameTime;

@property (strong, nonatomic) V2TXLivePlayer *livePlayer;

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

- (void)play:(nonnull NSString *)url {
    for (UIView * sbv in self.playerView.subviews) {
        [sbv removeFromSuperview];
    }
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
    [self.livePlayer setRenderFillMode:V2TXLiveFillModeScaleFill];
    [self.livePlayer setObserver:self];
    [self.livePlayer startLivePlay:url];
    [self.livePlayer showDebugView:YES];
    [self startTime];
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
    [self.livePlayer pauseVideo];
    [self.livePlayer pauseAudio];
}

- (void)resume {
    [self.livePlayer resumeVideo];
    [self.livePlayer resumeAudio];
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

@end
