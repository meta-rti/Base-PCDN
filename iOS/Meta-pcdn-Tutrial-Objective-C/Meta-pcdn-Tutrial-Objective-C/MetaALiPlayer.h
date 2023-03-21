//
//  PCDNPlayer.h
//  MetaPCDNDemo-Objective-c
//
//  Created by yoyo on 2022/12/3.
//

#import <UIKit/UIKit.h>
#import "IPlayerEable.h"
NS_ASSUME_NONNULL_BEGIN
@interface MetaALiPlayer : UIView<IPlayerEable>

@end


NSString * convertIphoeModeName(NSString *deviceModel);
NSString * GetDeviceInfo(void);
NS_ASSUME_NONNULL_END
