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

@implementation BUCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObject:@"" forKey:@"username"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    self.appIsJustLaunched = YES;
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (self.appIsJustLaunched) {
        NSString *errorMessage = nil;
        self.appIsJustLaunched = NO;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *username = [defaults objectForKey:@"username"];
        if (![username isEqualToString:@""]) {
            BUCUser *user = [BUCUser sharedInstance];
            user.username = username;
            if ([user loginForLaunch]) return;
            else errorMessage = @"原有密码已失效，请手动登录";
        }
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        BUCLoginViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"loginViewController"];
        [self.window.rootViewController presentViewController:loginVC animated:NO completion:nil];
        
        if (errorMessage) [loginVC alertWithMessage:errorMessage];
    }
}

- (BUCEventInterceptWindow *)window
{
    static BUCEventInterceptWindow *customWindow = nil;
    if (!customWindow) customWindow = [[BUCEventInterceptWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    return customWindow;
}
@end





















