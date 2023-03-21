//
//  IPlayerEable.h
//  MetaPCDNDemo-Objective-c
//
//  Created by yoyo on 2023/3/4.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@protocol IPlayerEable;
@protocol IPlayerDelegate <NSObject>
- (void)requestRestPlayerURL:(id<IPlayerEable>)player;
@end

typedef NS_ENUM(NSInteger,PCDNPlayerType)  {
    PCDNPlayerTypePCDN,
    PCDNPlayerTypeCDN,
};

@protocol IPlayerEable <NSObject>
@property(nonatomic,assign)PCDNPlayerType playerType;
@property(nonatomic,weak)id<IPlayerDelegate> delegate;
@property(nonatomic,strong)NSString * playURL;
@property(nonatomic,strong)NSString * rtcBoxIp;
- (void)play:(NSString *)url;

- (void)pause;
- (void)resume;


- (void)updateDataSourceTitle:(NSString *)title;
- (void)stop;
- (void)stopTimer;

- (void)releaseHudView;

@end
NS_ASSUME_NONNULL_END
