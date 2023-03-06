//
//  PCDNPlayer.m
//  MetaPCDNDemo-Objective-c
//
//  Created by yoyo on 2022/12/3.
//

#import <IJKMediaFramework/IJKMediaFramework.h>
#import <MetaPCDNKit/MetaPCDNKit.h>
#import "IJKPlayer.h"
#import "LMJDropdownMenu.h"
#import "Masonry.h"
#import "SVProgressHUD.h"

@interface SVProgressHUD ()
- (void)showProgress:(float)progress status:(NSString *)status;
- (void)dismissWithDelay:(NSTimeInterval)delay completion:(SVProgressHUDDismissCompletion)completion;

@end
@interface IJKPlayer  ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) IJKFFMoviePlayerController *player;
@property (nonatomic, strong) UIView *playerView;

@property (nonatomic, strong) UILabel *sourceLabel;

@property (nonatomic, strong) UILabel *statisticsLabel;

@property (nonatomic, assign) NSTimeInterval playbtnClickedTime;
@property (nonatomic, assign) NSTimeInterval reciverFirstFrameTime;

@property (nonatomic, weak) SVProgressHUD *hudView;

@end
@implementation IJKPlayer
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
        [self addNotiObserver];
    }

    return self;
}

- (void)addNotiObserver {
    //IJKMPMoviePlayerFirstVideoFrameDecodedNotification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(firstVideoFrameDecodeNotif:) name:@"IJKMPMoviePlayerFirstVideoFrameDecodedNotification" object:nil];
}

- (void)removeNotiObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"IJKMPMoviePlayerFirstVideoFrameDecodedNotification" object:nil];
}

- (void)firstVideoFrameDecodeNotif:(NSNotification *)nofi {
    IJKFFMoviePlayerController *obj =  nofi.object;

    if ([obj isEqual:self.player]) {
        if (self.reciverFirstFrameTime <= 0.0f) {
            self.reciverFirstFrameTime = [[NSDate date] timeIntervalSince1970];
        }

        [self getVideoInfo];
    }
}

- (void)destoryPlayer {
    if (self.player) {
        [self.player.view removeFromSuperview];
        [self.player pause];
        [self.player stop];
        [self.player shutdown];
        self.player = nil;
    }
}

- (void)play:(NSString *)url {
    for (UIView * sbv in self.playerView.subviews) {
        [sbv removeFromSuperview];
    }
    self.playbtnClickedTime = [[NSDate date] timeIntervalSince1970];
    self.reciverFirstFrameTime = -1;
    [self destoryPlayer];
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    //不限制输入缓存区大小
    [options setOptionIntValue:1 forKey:@"infbuf" ofCategory:kIJKFFOptionCategoryPlayer];
    //最大缓存区大小
    [options setOptionIntValue:1024 forKey:@"maxx-buffer-size" ofCategory:kIJKFFOptionCategoryPlayer];
    //设置rtmp的来源
    [options setOptionValue:url forKey:@"rtmp_pageurl" ofCategory:kIJKFFOptionCategoryFormat];
    //底下这几句补上，可以大大提高ijkplayer打开直播流的速度
    [options setOptionIntValue:100L forKey:@"analyzemaxduration" ofCategory:1];
    [options setOptionIntValue:10240L forKey:@"probesize" ofCategory:1];
    [options setOptionIntValue:1L forKey:@"flush_packets" ofCategory:1];
    [options setOptionIntValue:0L forKey:@"packet-buffering" ofCategory:4];
    [options setOptionIntValue:1L forKey:@"framedrop" ofCategory:4];
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURLString:url withOptions:options];
    self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    self.player.shouldAutoplay = YES;
    self.player.shouldShowHudView = YES;
    [self.player setPauseInBackground:YES];
    [self.player prepareToPlay];
    [self.player play];
    [self.playerView addSubview:self.player.view];
    [self.player.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.insets(UIEdgeInsetsZero);
    }];
    [self startTime];
}

- (void)stop {
    [self.player pause];
    [self.player stop];
    self.player = nil;
}

- (void)pause {
    [self.player pause];
}

- (void)resume {
    [self.player prepareToPlay];
    [self.player play];
}

- (void)releaseHudView {
}

- (void)dealloc {
    [self destoryPlayer];
    [self removeNotiObserver];
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
    NSString *str = @"";

    if (self.reciverFirstFrameTime > 0.0f) {
        str = [NSString stringWithFormat:@"%@\n 首帧时间:%.0f ms", str, (self.reciverFirstFrameTime - self.playbtnClickedTime) * 1000.0f];
    }

    if (self.rtcBoxIp.length > 0) {
        str = [NSString stringWithFormat:@"%@\n 盒子地址: %@", str, self.rtcBoxIp];
    }

    self.statisticsLabel.text = str;
}

@end
