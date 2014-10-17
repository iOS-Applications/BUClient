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

@interface BUCAppDelegate ()

@property (nonatomic) BOOL appIsJustLaunched;

@end

@implementation BUCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"", @"currentUser", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    self.appIsJustLaunched = YES;
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (self.appIsJustLaunched) {
        self.appIsJustLaunched = NO;
        self.mainViewController = (BUCMainViewController *)self.window.rootViewController;
        
        NSString *errorMsg = nil;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *username = [defaults objectForKey:@"currentUser"];
        
        if (![username length]) {
            [self.mainViewController displayLoginWithMessage:errorMsg];
            return;
        }
        
        errorMsg = [self loginWithUsername:username];
        if (errorMsg) {
            [self.mainViewController displayLoginWithMessage:errorMsg];
        }
    }
}

#pragma mark - private methods
- (NSString *)loginWithUsername:(NSString *)username
{
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    BUCUser *user = [BUCUser sharedInstance];
    user.username = username;
    NSString *password = [user getPassword];
    
    NSMutableDictionary *json = user.json;
    [json setObject:username forKey:@"username"];
    [json setObject:password forKey:@"password"];
    
    NSString *url = [NSString stringWithFormat:engine.baseUrl, @"logging"];
    NSMutableURLRequest *req = [[self requestWithUrl:url json:json] mutableCopy];
    if (!req) {
        return @"未知错误";
    }
    req.timeoutInterval = 3;
    
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
    user.req = req;
    [user.json setObject:username forKey:@"username"];
    [user.json setObject:user.session forKey:@"session"];
    
    return nil;
}

@end





















