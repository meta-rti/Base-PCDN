//
//  PCDNClientVC.h
//  MetaPCDNDemo-Objective-c
//
//  Created by yoyo on 2023/1/13.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,PlayerType){
    PlayerTypeIJK,
    PlayerTypeALI,
};
NS_ASSUME_NONNULL_BEGIN

@interface PCDNClientVC : UIViewController
@property(nonatomic,strong)NSString * playerURL;
@property(nonatomic,assign)PlayerType type;
@end

NS_ASSUME_NONNULL_END
