//
//  PCDNPlayer.h
//  MetaPCDNDemo-Objective-c
//
//  Created by yoyo on 2022/12/3.
//

#import <UIKit/UIKit.h>
#import "IPlayerEable.h"
NS_ASSUME_NONNULL_BEGIN
@interface IJKPlayer : UIView<IPlayerEable>
@property(nonatomic,assign)PCDNPlayerType playerType;
@property(nonatomic,strong)NSString * playURL;
@property(nonatomic,strong)NSString * rtcBoxIp;
- (void)play:(NSString *)url;

- (void)updateDataSourceTitle:(NSString *)title;
- (void)stop;
- (void)stopTimer;

- (void)releaseHudView;
@end

NS_ASSUME_NONNULL_END
