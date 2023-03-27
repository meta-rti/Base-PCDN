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

#import <sys/param.h>
#import <sys/sysctl.h>
#import <sys/types.h>

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

@property(nonatomic,strong)NSDateFormatter * formatter;

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
        
        self.formatter = [[NSDateFormatter alloc] init];
        self.formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
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
    NSString * deviceInfo = GetDeviceInfo();
    NSString * trackID = @"";
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
            NSString * timeStr = [self.formatter stringFromDate:[NSDate date]];
            trackID = [NSString stringWithFormat:@"RTC_%@_%@",deviceInfo,timeStr];
            
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
          
            NSString * timeStr = [self.formatter stringFromDate:[NSDate date]];
            trackID = [NSString stringWithFormat:@"CDN_%@_%@",deviceInfo,timeStr];
        }
    }

    self.playURL = url;
    self.player.delegate = self;
    self.player.renderingDelegate = self;
    self.player.eventReportParamsDelegate = self;
    self.reciverFirstFrameTime = -1.0f;
    AVPUrlSource *urlSource = [[AVPUrlSource  alloc] urlWithString:url];
    [self.player setUrlSource:urlSource];
    [self.player setTraceID:trackID];
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
    if(self.delegate &&[self.delegate respondsToSelector:@selector(requestRestPlayerURL:)]) {
        [self.delegate requestRestPlayerURL:self];
    }
}

- (void)onEventReportParams:(NSDictionary<NSString *, NSString *> *)params {
//    NSLog(@"player url = %@  report params = %@",self.playURL,[params description]);
}

- (void)onSEIData:(AliPlayer *)player type:(int)type data:(NSData *)data {
    NSString *sei = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    NSLog(@"recive sei type %d  data = %@", type, sei);
}

@synthesize delegate;

@end

 NSString * GetDeviceInfo(void) {
  // HUAWEI PAL-100
  int mib[2];
  size_t len;
  char *machine;

  mib[0] = CTL_HW;
  mib[1] = HW_MACHINE;
  sysctl(mib, 2, NULL, &len, NULL, 0);
  machine = (char *)malloc(len);
  sysctl(mib, 2, machine, &len, NULL, 0);

  NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];

  free(machine);
  NSString *device_name = convertIphoeModeName(platform);
  return convertIphoeModeName(device_name);
}

NSString *convertIphoeModeName(NSString *deviceModel) {
  // https://www.theiphonewiki.com/wiki/Models
  // iphone
  if ([deviceModel isEqualToString:@"iPhone3,1"] || [deviceModel isEqualToString:@"iPhone3,2"] || [deviceModel isEqualToString:@"iPhone3,3"])
    return @"iPhone 4 (A1332|A1349)";

  if ([deviceModel isEqualToString:@"iPhone4,1"]) return @"iPhone 4S (A1387|A1431)";

  if ([deviceModel isEqualToString:@"iPhone5,1"] || [deviceModel isEqualToString:@"iPhone5,2"]) return @"iPhone 5 (A1428|A1429|A1442)";

  if ([deviceModel isEqualToString:@"iPhone5,3"] || [deviceModel isEqualToString:@"iPhone5,4"])
    return @"iPhone 5c (A1456|A1532|A1507|A1516|A1526|A1529)";

  if ([deviceModel isEqualToString:@"iPhone6,1"] || [deviceModel isEqualToString:@"iPhone6,2"])
    return @"iPhone 5s (A1453|A1533|A1457|A1518|A1528|A1530)";

  if ([deviceModel isEqualToString:@"iPhone7,1"]) return @"iPhone 6 Plus (A1522|A1524|A1593)";
  if ([deviceModel isEqualToString:@"iPhone7,2"]) return @"iPhone 6 (A1549|A1586|A1589[1)";
  if ([deviceModel isEqualToString:@"iPhone8,1"]) return @"iPhone 6s (A1633|A1688|A1691|A1700)";
  if ([deviceModel isEqualToString:@"iPhone8,2"]) return @"iPhone 6s Plus (A1634|A1687|A1690|A1699)";
  if ([deviceModel isEqualToString:@"iPhone8,4"]) return @"iPhone SE (A1662|A1723|A1724)";
  // 日行两款手机型号均为日本独占，可能使用索尼FeliCa支付方案而不是苹果支付
  if ([deviceModel isEqualToString:@"iPhone9,1"]) return @"iPhone 7 (A1660|A1779|A1780|A1778)";
  if ([deviceModel isEqualToString:@"iPhone9,2"] || [deviceModel isEqualToString:@"iPhone9,4"]) return @"iPhone 7 Plus (A1661|A1785|A1786|A1784)";

  if ([deviceModel isEqualToString:@"iPhone10,1"] || [deviceModel isEqualToString:@"iPhone10,4"]) return @"iPhone 8 (A1863|A1906|A1907|A1905)";

  if ([deviceModel isEqualToString:@"iPhone10,2"] || [deviceModel isEqualToString:@"iPhone10,5"]) return @"iPhone 8 Plus (A1864| A1898|A1899)";

  if ([deviceModel isEqualToString:@"iPhone10,3"] || [deviceModel isEqualToString:@"iPhone10,6"]) return @"iPhone X (A1865|A1902|A1901)";

  if ([deviceModel isEqualToString:@"iPhone11,8"]) return @"iPhone XR (A1984|A2105|A2106|A2108)";
  if ([deviceModel isEqualToString:@"iPhone11,2"]) return @"iPhone XS (A1920|A2097|A2098|A2100)";
  if ([deviceModel isEqualToString:@"iPhone11,6"] || [deviceModel isEqualToString:@"iPhone11,4"])
    return @"iPhone XS Max (A1921|A2101|A2102|A2104|A2103)";

  if ([deviceModel isEqualToString:@"iPhone12,1"]) return @"iPhone 11 (A2111|A2221|A2223)";

  if ([deviceModel isEqualToString:@"iPhone12,3"]) return @"iPhone 11 Pro (A2160|A2215|A2217)";
  if ([deviceModel isEqualToString:@"iPhone12,5"]) return @"iPhone 11 Pro Max (A2161|A2220|A2218)";
  if ([deviceModel isEqualToString:@"iPhone12,8"]) return @"iPhone SE 2G (A2275|A2296|A2298)";
  if ([deviceModel isEqualToString:@"iPhone13,1"]) return @"iPhone 12 mini (A2176|A2398|A2400|A2399)";
  if ([deviceModel isEqualToString:@"iPhone13,2"]) return @"iPhone 12 (A2172|A2402|A2404|A2403)";
  if ([deviceModel isEqualToString:@"iPhone13,3"]) return @"iPhone 12 Pro (A2341|A2406|A2407|A2408)";
  if ([deviceModel isEqualToString:@"iPhone13,4"]) return @"iPhone 12 Pro Max (A2342|A2410|A2411|A2412)";

  if ([deviceModel isEqualToString:@"iPhone14,4"]) return @"iPhone 13 mini (iA2481|A2626|A2629|A2630|A2628)";
  if ([deviceModel isEqualToString:@"iPhone14,5"]) return @"iPhone 13 (A2482|A2631|A2634|A2635A2633)";
  if ([deviceModel isEqualToString:@"iPhone14,2"]) return @"iPhone 13 Pro (A2483|A2636|A2639|A2640|A2638)";
  if ([deviceModel isEqualToString:@"iPhone14,3"]) return @"iPhone 13 Pro Max (A2484|A2641|A2644|A2645|A2643)";
  if ([deviceModel isEqualToString:@"iPhone14,6"]) return @"iPhone SE 3G (A2595|A2782|A2783|A2784|A2785)";
  if ([deviceModel isEqualToString:@"iPhone14,7"]) return @"iPhone 14 (A2649|A2881|A2882|A2883A2884)";
  if ([deviceModel isEqualToString:@"iPhone14,8"]) return @"iPhone 14 Plus (A2632|A2885|A2886|A2887|A2888)";
  if ([deviceModel isEqualToString:@"iPhone15,2"]) return @"iPhone 14 Pro (A2650|A2889|A2890|A2891|A2892)";
  if ([deviceModel isEqualToString:@"iPhone15,3"]) return @"iPhone 14 Pro Max (A2651|A2893|A2894|A2895|A2896)";

  // ipod
  if ([deviceModel isEqualToString:@"iPod1,1"]) return @"iPod Touch 1G (A1213)";
  if ([deviceModel isEqualToString:@"iPod2,1"]) return @"iPod Touch 2G (A1288|A1319)";
  if ([deviceModel isEqualToString:@"iPod3,1"]) return @"iPod Touch 3G (A1318)";
  if ([deviceModel isEqualToString:@"iPod4,1"]) return @"iPod Touch 4G (A1367)";
  if ([deviceModel isEqualToString:@"iPod5,1"]) return @"iPod Touch 5G (A1421|A1509)";
  if ([deviceModel isEqualToString:@"iPod7,1"]) return @"iPod Touch 6G (A1574)";
  if ([deviceModel isEqualToString:@"iPod9,1"]) return @"iPod Touch 7G (A2178)";
  // ipad
  if ([deviceModel isEqualToString:@"iPad1,1"]) return @"iPad (A1219|A1337)";
  if ([deviceModel isEqualToString:@"iPad2,3"] || [deviceModel isEqualToString:@"iPad2,4"] || [deviceModel isEqualToString:@"iPad2,2"])
    return @"iPad 2G (A1395|A1396|A1397|A1395)";

  if ([deviceModel isEqualToString:@"iPad3,2"] || [deviceModel isEqualToString:@"iPad3,3"] || [deviceModel isEqualToString:@"iPad3,1"])
    return @"iPad 3G (A1416|A1403|A1430)";

  if ([deviceModel isEqualToString:@"iPad3,4"] || [deviceModel isEqualToString:@"iPad3,5"] || [deviceModel isEqualToString:@"iPad3,6"])
    return @"iPad 4G (A1458|iA1459|A1460)";

  if ([deviceModel isEqualToString:@"iPad6,11"] || [deviceModel isEqualToString:@"iPad6,12"]) return @"iPad 5G (A1822|A1823)";

  if ([deviceModel isEqualToString:@"iPad7,5"] || [deviceModel isEqualToString:@"iPad7,6"]) return @"iPad 6G (A1893|A1954)";
  if ([deviceModel isEqualToString:@"iPad7,11"] || [deviceModel isEqualToString:@"iPad7,12"]) return @"iPad 7G (A2197|A2198|A2200)";

  if ([deviceModel isEqualToString:@"iPad11,6"] || [deviceModel isEqualToString:@"iPad11,7"]) return @"iPad 8G (A2270|A2428|A2429|A2430)";

  if ([deviceModel isEqualToString:@"iPad12,1"] || [deviceModel isEqualToString:@"iPad12,2"]) return @"iPad 9G (A2602|A2603|A2604|A2605)";

  // ipad pro
  if ([deviceModel isEqualToString:@"iPad6,7"] || [deviceModel isEqualToString:@"iPad6,8"]) return @"iPad Pro 12.9 inch (iPad6,7|A1652)";

  if ([deviceModel isEqualToString:@"iPad6,3"] || [deviceModel isEqualToString:@"iPad6,4"]) return @"iPad Pro 9.7 inch (A1673|A1674|A1675)";

  if ([deviceModel isEqualToString:@"iPad7,1"] || [deviceModel isEqualToString:@"iPad7,2"]) return @"iPad Pro 12.9 inch 2G (A1670|A1671|A1821)";

  if ([deviceModel isEqualToString:@"iPad7,3"] || [deviceModel isEqualToString:@"iPad7,4"]) return @"iPad Pro 10.5 inch (A1701|A1709)";

  if ([deviceModel isEqualToString:@"iPad8,1"] || [deviceModel isEqualToString:@"iPad8,2"] || [deviceModel isEqualToString:@"iPad8,3"] ||
      [deviceModel isEqualToString:@"iPad8,4"])
    return @"iPad Pro 11 inch (A1980|A1934|A1979|A2013)";

  if ([deviceModel isEqualToString:@"iPad8,5"] || [deviceModel isEqualToString:@"iPad8,6"] || [deviceModel isEqualToString:@"iPad8,7"] ||
      [deviceModel isEqualToString:@"iPad8,8"])
    return @"iPad Pro 12.9 inch 3G (A1876|A1895|A1983|A2014)";

  if ([deviceModel isEqualToString:@"iPad8,9"] || [deviceModel isEqualToString:@"iPad8,10"]) return @"iPad Pro 11 inch 2G (A2228|A2068|A2230|A2231)";

  if ([deviceModel isEqualToString:@"iPad8,11"] || [deviceModel isEqualToString:@"iPad8,12"])
    return @"iPad Pro 12.9 inch 4G (A2229|A2069|A2232|A2233)";

  if ([deviceModel isEqualToString:@"iPad13,4"] || [deviceModel isEqualToString:@"iPad13,5"] || [deviceModel isEqualToString:@"iPad13,6"] ||
      [deviceModel isEqualToString:@"iPad13,7"])
    return @"iPad Pro 11 inch 3G (A2377|A2459|A2301|A2460)";

  if ([deviceModel isEqualToString:@"iPad13,8"] || [deviceModel isEqualToString:@"iPad13,9"] || [deviceModel isEqualToString:@"iPad13,10"] ||
      [deviceModel isEqualToString:@"iPad3,11"])
    return @"iPad Pro 12.9 inch 5G (A2378|A2461|A2379|A2462)";

  // ipad Air
  if ([deviceModel isEqualToString:@"iPad4,1"] || [deviceModel isEqualToString:@"iPad4,2"] || [deviceModel isEqualToString:@"iPad4,3"])
    return @"iPad Air (A1474|A1475|A1476)";

  if ([deviceModel isEqualToString:@"iPad5,3"] || [deviceModel isEqualToString:@"iPad5,4"]) return @"iPad Air 2 (A1566|A1567)";

  if ([deviceModel isEqualToString:@"iPad11,3"] || [deviceModel isEqualToString:@"iPad11,4"]) return @"iPad Air 3G(A2152|A2123|A2153|A2154)";

  if ([deviceModel isEqualToString:@"iPad13,1"] || [deviceModel isEqualToString:@"iPad13,2"]) return @"iPad Air 4G (A2316|A2324|A2325|A2072)";

  if ([deviceModel isEqualToString:@"iPad13,16"] || [deviceModel isEqualToString:@"iPad13,17"]) return @"iPad Air 5G (A2588|A2589|A2591)";

  // ipad mini
  if ([deviceModel isEqualToString:@"iPad2,6"] || [deviceModel isEqualToString:@"iPad3,1"] || [deviceModel isEqualToString:@"iPad2,5"])
    return @"iPad Mini (A1432|A1454|A1455)";

  if ([deviceModel isEqualToString:@"iPad4,4"] || [deviceModel isEqualToString:@"iPad4,5"] || [deviceModel isEqualToString:@"iPad4,6"])
    return @"iPad Mini 2 (A1489|A1490|A1491)";

  if ([deviceModel isEqualToString:@"iPad4,7"] || [deviceModel isEqualToString:@"iPad4,8"] || [deviceModel isEqualToString:@"iPad4,9"])
    return @"iPad Mini 3 (A1599|A1600|A1601)";

  if ([deviceModel isEqualToString:@"iPad5,1"] || [deviceModel isEqualToString:@"iPad5,2"]) return @"iPad Mini 4 (A1538|A1550)";

  if ([deviceModel isEqualToString:@"iPad11,1"] || [deviceModel isEqualToString:@"iPad11,2"]) return @"iPad mini 5G (A2133|A2124|A2125|A2126)";

  if ([deviceModel isEqualToString:@"iPad14,1"] || [deviceModel isEqualToString:@"iPad14,2"]) return @"iPad mini 6G (A2567|A2568|A2569)";

  if ([deviceModel isEqualToString:@"i386"] || [deviceModel isEqualToString:@"x86_64"]) return @"Simulator";
  return deviceModel;
}
