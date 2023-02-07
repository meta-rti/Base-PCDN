//
//  ViewController.m
//  Meta-pcdn-Tutrial-Objective-C
//
//  Created by yoyo on 2023/2/6.
//

#import <IJKMediaFramework/IJKMediaFramework.h>
#import <Masonry.h>
#import <MetaPCDNKit/MetaPCDNKit.h>
#import "Key.h"
#import "ViewController.h"


@interface ViewController ()<MetaPCDNClientDelegate>
@property (nonatomic, strong) IJKFFMoviePlayerController *player;
@property (nonatomic, strong) MetaPCDNClient *client;
@property (nonatomic, strong) UITextField *urlInputField;
@property (nonatomic, strong) NSString *playerURL;
@property (nonatomic, strong) NSString *localProxyURL;
@property (nonatomic, strong) UIView *playerView;

@property (nonatomic, strong) UILabel *sourceLabel;

@end

@implementation ViewController
- (CGFloat)statusBarHeight {
    CGFloat statusBarHeight = 0;

    if (@available(iOS 13.0, *)) {
        statusBarHeight = [UIApplication sharedApplication].windows.firstObject.windowScene.statusBarManager.statusBarFrame.size.height;
    } else {
        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    }

    return statusBarHeight;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.playerURL = @"rtmp://221.13.203.66:31937/live/IMG_30fps_bf1_1M_baseline_360p";

    self.playerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.playerView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.playerView];

    [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.mas_equalTo(0);
        make.bottom.mas_equalTo(-80);
    }];


    self.urlInputField = [[UITextField alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.urlInputField];

    self.urlInputField.layer.borderColor = [UIColor colorWithRed:64.0 / 255 green:151.0 / 255 blue:255.0 / 255 alpha:1].CGColor;
    self.urlInputField.layer.borderWidth = 1;
    self.urlInputField.layer.cornerRadius = 3;
    self.urlInputField.text = self.playerURL;
    self.urlInputField.placeholder = @"请输入视频URL";
    self.urlInputField.textColor = [UIColor colorWithRed:64.0 / 255 green:151.0 / 255 blue:255.0 / 255 alpha:1];
    self.urlInputField.font = [UIFont boldSystemFontOfSize:15];

    [self.urlInputField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(5);
        make.right.mas_equalTo(-100);
        make.top.equalTo(self.playerView.mas_bottom).offset(10);
        make.height.mas_equalTo(40);
    }];

    UIButton *playerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [playerBtn setTitle:@"开始播放" forState:UIControlStateNormal];
    [playerBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [playerBtn addTarget:self action:@selector(playerBtnClickedHandler:) forControlEvents:UIControlEventTouchUpInside];
    playerBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    playerBtn.layer.cornerRadius = 5;
    playerBtn.layer.masksToBounds = true;

    playerBtn.backgroundColor = [UIColor colorWithRed:64.0 / 255 green:151.0 / 255 blue:255.0 / 255 alpha:1];
    [self.view addSubview:playerBtn];

    [playerBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.urlInputField);
        make.right.equalTo(self.view).offset(-5);
        make.left.equalTo(self.urlInputField.mas_right).offset(5);
        make.height.mas_equalTo(40);
    }];

    self.sourceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.sourceLabel.font = [UIFont systemFontOfSize:17];
    self.sourceLabel.textColor = [UIColor systemRedColor];
    self.sourceLabel.textAlignment = NSTextAlignmentCenter;
    self.sourceLabel.layer.cornerRadius = 5;
    self.sourceLabel.layer.masksToBounds = YES;
    self.sourceLabel.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.5];

    [self.view addSubview:self.sourceLabel];
    [self.sourceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo([self statusBarHeight] + 10);
        make.centerX.mas_equalTo(self.view);
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(80);
    }];
    //1.setp init client
    MetaPCDNClientConfig *config = [[MetaPCDNClientConfig alloc] init];
    config.cid = CID;
    config.vid = VID;
    config.token = Token;
    self.client = [MetaPCDNClient shareClientConfig:config];
    self.client.delegate = self;

    //2. create local url
    self.localProxyURL = [self.client createLocalStream:self.playerURL];

    //3. play local url
    [self playWithLocalURL:self.localProxyURL];
}

- (void)playerBtnClickedHandler:(UIButton *)sender {
    if (self.urlInputField.text.length <= 0) {
        NSLog(@" input url is empty");
        return;
    }

    // destory old url
    if (self.localProxyURL) {
        [self.client destoryLocalStream:self.localProxyURL];
    }

    //crate new local url
    self.localProxyURL = [self.client createLocalStream:self.urlInputField.text];

    //play local url
    [self playWithLocalURL:self.localProxyURL];
}

- (void)playWithLocalURL:(NSString *)url {
    [self destoryPlayer];
    IJKFFOptions *option = [IJKFFOptions optionsByDefault];
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURLString:url withOptions:option];
    self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    self.player.shouldAutoplay = YES;
    self.player.shouldShowHudView = YES;
    [self.player prepareToPlay];
    [self.player play];
    [self.playerView addSubview:self.player.view];
    [self.player.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.insets(UIEdgeInsetsZero);
    }];
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

- (void)dealloc {
    [self destoryPlayer];
    [self.client destoryLocalStream:self.localProxyURL];
    self.client = nil;
}

#pragma mark -MetaPCDNClientDelegate
- (void)client:(MetaPCDNClient *)client onWarning:(int)warn remoteUrl:(NSString *)remoteURL localUrl:(NSString *)localURL msg:(NSString *)message {
    NSLog(@" remoteUrl:%@ warn:%d msg:%@", remoteURL, warn, message);
}

- (void)client:(MetaPCDNClient *)client onError:(MetaPCDNErrorCode)error remoteUrl:(NSString *)remoteURL localUrl:(NSString *)localURL msg:(NSString *)message {
    NSLog(@" remoteUrl:%@ error:%ld msg:%@", remoteURL, error, message);
}

- (void)client:(MetaPCDNClient *)client requestTokeError:(MetaPCDNErrorCode)error {
    NSLog(@" requestTokeError %ld", error);
}

- (void)client:(MetaPCDNClient *)client remoteUrl:(NSString *)remoteURL localUrl:(NSString *)localURL sourceFromType:(MetaDataSourceType)sourceType {
    NSString *sourceFrom = @"unknow";

    if ([localURL isEqualToString:self.localProxyURL]) {
        if (sourceType == MetaDataSourceRTC) {
            sourceFrom = @"RTC";
        } else if (sourceType == MetaDataSourceCDN) {
            sourceFrom = @"CDN";
        }
    }
    NSLog(@"remoteUrl : %@ localUrl:%@ sourceFromType : %@", remoteURL, localURL, sourceFrom);
    self.sourceLabel.text = sourceFrom;
}

@end
