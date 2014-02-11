//
//  BUCAppDelegate.h
//  BUClient
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BUCEventInterceptWindow.h"
#import "BUCMainViewController.h"

@interface BUCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) BUCEventInterceptWindow *window;
@property (weak, nonatomic) BUCMainViewController *mainViewController;
@property BOOL appIsJustLaunched;

@end
