//
//  BUCAppDelegate.m
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCAppDelegate.h"
#import "BUCConstants.h"

@implementation BUCAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:BUCAppLaunchStateDefaultKey];
}

@end





















