//
//  AppDelegate.m
//  Meta-pcdn-Tutrial-Objective-C
//
//  Created by yoyo on 2023/2/6.
//

#import "AppDelegate.h"
#import <IQKeyboardManager/IQKeyboardManager.h>
#import <TXLiteAVSDK_Professional/V2TXLivePremier.h>
#import "Key.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [IQKeyboardManager sharedManager].enable = YES;
    [IQKeyboardManager sharedManager].shouldResignOnTouchOutside = YES;
    [V2TXLivePremier setLicence:LICENSEURL key:LICENSEURLKEY];
    return YES;
}

@end
