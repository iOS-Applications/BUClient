//
//  BUCAppDelegate.m
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCAppDelegate.h"
#import "BUCRootViewController.h"
#import "BUCAuthManager.h"

@implementation BUCAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isJustLaunched"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isJustLaunched"])
    {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"])
        {
            BUCRootViewController *rootVC = (BUCRootViewController *)self.window.rootViewController;
            [rootVC displayLogin];
        }
        else
        {
            BUCAuthManager *authManager = [BUCAuthManager sharedInstance];
            [authManager start];
        }
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isJustLaunched"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end





















