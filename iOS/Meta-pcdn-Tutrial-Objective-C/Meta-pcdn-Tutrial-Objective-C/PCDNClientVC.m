//
//  PCDNClientVC.m
//  MetaPCDNDemo-Objective-c
//
//  Created by yoyo on 2023/1/13.
//

#import <MetaPCDNKit/MetaPCDNKit.h>
#import "Key.h"
#import "LMJDropdownMenu.h"
#import "Masonry.h"
#import "PCDNClientVC.h"
#import "IJKPlayer.h"
#import "TXPlayer.h"
#import "SVProgressHUD.h"
#import "MetaALiPlayer.h"


@interface PCDNClientVC ()<MetaPCDNClientDelegate>
@property (nonatomic, strong) UIView<IPlayerEable> *playerView1;
@property (nonatomic, strong) UIView<IPlayerEable> *playerView2;

@property (nonatomic, strong) UITextField *urlInputField;

@property (nonatomic, strong) NSString *remoteUrl;
@property (nonatomic, strong) NSString *locoalUrl;
@property (nonatomic, assign) BOOL sync_play_source;  //同步播放cdn 视频流

@property (nonatomic, strong) MetaPCDNClient *client;

@end

@implementation PCDNClientVC

- (MetaPCDNClient *)client {
    if (_client == nil) {
        MetaPCDNClientConfig *config = [[MetaPCDNClientConfig alloc] init];
        config.cid = CID;
        _client = [MetaPCDNClient shareClientConfig:config];
        _client.delegate = self;
    }

    return _client;
}

- (CGFloat)statusBarHeight {
    CGFloat statusBarHeight = 0;

    if (@available(iOS 13.0, *)) {
        statusBarHeight = [UIApplication sharedApplication].windows.firstObject.windowScene.statusBarManager.statusBarFrame.size.height;
    } else {
        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    }

    return statusBarHeight;
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterActiveground:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)applicationDidEnterBackground:(NSNotification *)notif {
    [self.playerView1 pause];
    [self.playerView2 pause];
}

- (void)applicationDidEnterActiveground:(NSNotification *)notif {
    [self.playerView1 resume];
    [self.playerView2 resume];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.playerView1 stopTimer];
    [self.playerView1 releaseHudView];

    [self.playerView2 stopTimer];
    [self.playerView2 releaseHudView];

    [self.client destoryLocalStream:self.locoalUrl];

    self.view.backgroundColor = [UIColor whiteColor];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"back"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStyleDone target:self action:@selector(back)];

    self.title = self.playerURL;

    self.view.backgroundColor = [UIColor whiteColor];


    if(self.type == PlayerTypeIJK) {
        self.playerView1 = [[IJKPlayer alloc] initWithFrame:CGRectZero];
        self.playerView1.playerType = PCDNPlayerTypePCDN;
        self.playerView2 = [[IJKPlayer alloc] initWithFrame:CGRectZero];
    } else if (self.type == PlayerTypeALI) {
        self.playerView1 = [[MetaALiPlayer alloc] initWithFrame:CGRectZero];
        self.playerView1.playerType = PCDNPlayerTypePCDN;
        self.playerView2 = [[MetaALiPlayer alloc] initWithFrame:CGRectZero];
    } else {
        self.playerView1 = [[TXPlayer alloc] initWithFrame:CGRectZero];
        self.playerView1.playerType = PCDNPlayerTypePCDN;
        self.playerView2 = [[TXPlayer alloc] initWithFrame:CGRectZero];
    }
    
    [self.view addSubview:self.playerView1];

    CGFloat statusHeight = [self statusBarHeight];
    CGFloat navBarHeight = 44.0f;
    CGFloat playerHeight = ([UIScreen mainScreen].bounds.size.height - statusHeight - navBarHeight - 70) / 2.0;
    [self.playerView1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(statusHeight + navBarHeight);
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(playerHeight);
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
        make.top.equalTo(self.playerView1.mas_bottom).offset(10);
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

    
    [self.view addSubview:self.playerView2];

    [self.playerView2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.urlInputField.mas_bottom).offset(10);
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(playerHeight);
    }];

    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    versionLabel.textColor = [UIColor systemGrayColor];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.text = [NSString stringWithFormat:@"version:%@", [self.client getSdkVersion]];
    versionLabel.font = [UIFont systemFontOfSize:13];
    [self.view addSubview:versionLabel];
    [versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-20);
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(15);
    }];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.view addSubview:label];

    label.font = [UIFont systemFontOfSize:14];
    label.text = @"同步播放原始视频";
    label.textColor = [UIColor colorWithRed:64.0 / 255 green:151.0 / 255 blue:255.0 / 255 alpha:1];
    label.backgroundColor = [UIColor clearColor];

    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-80);
        make.top.mas_equalTo(navBarHeight + statusHeight + 20);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(30);
    }];

    UISwitch *switchView =  [[UISwitch alloc] initWithFrame:CGRectZero];
    [self.view addSubview:switchView];
    [switchView setOn:false];
    [switchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(label.mas_centerY);
        make.left.equalTo(label.mas_right).offset(5);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(30);
    }];
    self.sync_play_source = YES;
    [switchView setOn:self.sync_play_source];
    [switchView addTarget:self action:@selector(switchLogValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)switchLogValueChanged:(UISwitch *)sender {
    self.sync_play_source = sender.isOn;

    if (self.sync_play_source && self.remoteUrl.length > 0) {
        [self.playerView2 play:self.remoteUrl];
        [self.playerView2 updateDataSourceTitle:@"CDN"];
    } else {
        [self.playerView2 stop];
    }
}

- (void)playerBtnClickedHandler:(UIButton *)sender {
    if (self.urlInputField.text.length <= 0) {
        [SVProgressHUD showInfoWithStatus:@"输入地址为空!"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
        return;
    }

    [self playRemoteUrl:self.urlInputField.text];
}

- (void)playRemoteUrl:(NSString *)urlStr {
    if (urlStr.length <= 0) {
        [SVProgressHUD showInfoWithStatus:@"没有视频地址,请填写后再播放"];
        [SVProgressHUD dismissWithDelay:2];
        return;
    }

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSLog(@" url = %@ ", [url lastPathComponent]);

    NSString *logPath = [NSString stringWithFormat:@"%@/%@.log", path, [url lastPathComponent]];
    unlink([logPath UTF8String]);

    [self.client setLogFilter:MetaPCDNLogFilterInfo];
    [self.client setLogFile:logPath fileSize:10 * 1024 * 1024];
   

    // destory old local proxy url
    [self.client destoryLocalStream:self.locoalUrl];
    //create new  local proxy url
    NSString *proxyUrl = [self.client createLocalStream:urlStr vid:VID token:@""];

    //player local url
    [self.playerView1 play:proxyUrl];

    if (self.sync_play_source) {
        [self.playerView2 play:urlStr];
        [self.playerView2 updateDataSourceTitle:@"CDN"];
    }

    self.locoalUrl = proxyUrl;
    self.remoteUrl = urlStr;
}

#pragma mark MetaPCDNClientDelegate
- (void)client:(MetaPCDNClient *)client onError:(MetaPCDNErrorCode)error remoteUrl:(NSString *)remoteURL localUrl:(nonnull NSString *)localURL vid:(nonnull NSString *)vid msg:(NSString *)message {
    NSString *log = [NSString stringWithFormat:@"remoteURL : %@  localUrl = %@ error : %ld msg:%@ ", remoteURL, localURL, error, message];

    NSLog(@"%@", log);

    if ([remoteURL isEqualToString:self.remoteUrl] && [localURL isEqualToString:self.locoalUrl]) {
    }
}

- (void)client:(MetaPCDNClient *)client stats:(MetaPCDNStats *)stats {
    NSString *sourceFrom = @"unknow";

    if ([stats.remoteUrl isEqualToString:self.remoteUrl] && [stats.localUrl isEqualToString:self.locoalUrl]) {
        if (stats.sourceType == MetaDataSourceRTC) {
            sourceFrom = @"RTC";
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", stats.boxIp]];
            NSString *host = @"";

            if (url) {
                host = [url host];
            }

            self.playerView1.rtcBoxIp = host;
        } else if (stats.sourceType == MetaDataSourceCDN) {
            sourceFrom = @"CDN";
            self.playerView1.rtcBoxIp = @"";
        }

        [self.playerView1 updateDataSourceTitle:[NSString stringWithFormat:@"SOURCE : %@", sourceFrom]];
    }
}

- (void)client:(MetaPCDNClient *)client onWarning:(int)warn remoteUrl:(NSString *)remoteURL localUrl:(nonnull NSString *)localURL vid:(nonnull NSString *)vid msg:(NSString *)message {
    NSString *log = [NSString stringWithFormat:@"remoteURL : %@ localUlr = %@ warring : %d msg:%@ ", remoteURL, localURL, warn, message];

    NSLog(@"%@ ", log);
}

- (void)client:(nonnull MetaPCDNClient *)client remoteUrl:(nonnull NSString *)remoteURL vid:(nonnull NSString *)vid sourceFromType:(MetaDataSourceType)sourceType {
}

/*
 #pragma mark - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
   }
 */

@end
