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
#import "NSObject+BUCTools.h"

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
            [self.mainViewController displayLoginWithMessage:errorMessage];
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
    if (![engine checkNetworkStatus]) {
        return @"无法连接到联盟服务器，服务器有可能出现故障，请检查网络连接或稍后再试";
    }
    else if (![username length]) return @"";
    else {
        BUCUser *user = [BUCUser sharedInstance];
        user.username = username;
        NSString *password = [user getPassword];
        
        NSMutableDictionary *json = user.json;
        [json setObject:username forKey:@"username"];
        [json setObject:password forKey:@"password"];
        
        NSString *url = [NSString stringWithFormat:engine.baseUrl, @"logging"];
        NSURLRequest *req = [self requestWithUrl:url json:json];
        if (!req) return @"未知错误";
        
        NSURLResponse *response;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&error];
        if (error) {
            error = [self checkErr:error response:response];
            return error.localizedDescription;
        } else if (![data length]) {
            return @"未知错误";
        }

        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!json) {
            return @"未知错误";
        }

        user.session = [json objectForKey:@"session"];
        user.isLoggedIn = YES;
        user.loadImage = [defaults objectForKey:@"loadImage"];
        user.req = req;
        [user.json setObject:username forKey:@"username"];
        [user.json setObject:user.session forKey:@"session"];
    }
    
    return nil;
}

@end





















