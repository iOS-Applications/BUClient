//
//  BUCAppDelegate.m
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCAppDelegate.h"
#import "BUCUser.h"
#import "BUCLoginViewController.h"
#import "BUCNetworkEngine.h"


@implementation BUCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"", @"currentUser", @"", @"loadImage", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    self.appIsJustLaunched = YES;
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (self.appIsJustLaunched) {
        
        self.appIsJustLaunched = NO;
        NSString *errorMessage = [self login];
        self.mainViewController = (BUCMainViewController *)self.window.rootViewController;
        
        if (errorMessage) {
            [(BUCMainViewController *)self.window.rootViewController displayLoginWithMessage:errorMessage];
        }
    }
}

#pragma mark - custom getter method of property window
- (BUCEventInterceptWindow *)window
{
    static BUCEventInterceptWindow *customWindow = nil;
    if (!customWindow) customWindow = [[BUCEventInterceptWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    return customWindow;
}

#pragma mark - private methods
- (NSString *)login
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults objectForKey:@"currentUser"];
    
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    if (![engine checkNetworkStatus])
        return @"无法连接到联盟服务器，服务器有可能出现故障，请检查网络连接或稍后再试";
    else if (![username length]) return @"";
    else {
        BUCUser *user = [BUCUser sharedInstance];
        user.username = username;
        NSString *password = [user getPassword];
        
        NSMutableDictionary *loginDataDic = user.loginJsonDic;
        [loginDataDic setObject:username forKey:@"username"];
        [loginDataDic setObject:password forKey:@"password"];
        
        NSString *errorMessage = [engine processSyncRequest:user.loginDic];
        if (errorMessage) return errorMessage;

        if (!engine.responseDic && [[engine.responseDic objectForKey:@"result"] isEqualToString:@"fail"]) {
            return @"当前密码已失效，请手动登录";
        }

        user.session = [engine.responseDic objectForKey:@"session"];
        user.isLoggedIn = YES;
        user.loadImage = [defaults objectForKey:@"loadImage"];
    }
    
    return nil;
}

@end





















