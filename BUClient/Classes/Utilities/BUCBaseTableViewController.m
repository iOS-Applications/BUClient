//
//  BUCBaseTableViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCBaseTableViewController.h"
#import "BUCMainViewController.h"

@interface BUCBaseTableViewController ()

@end

@implementation BUCBaseTableViewController
- (IBAction)displayMenu:(id)sender
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    BUCMainViewController *mainController = (BUCMainViewController *)window.rootViewController;
    if (!mainController.loadingView.hidden) {
        mainController.loadingView.hidden = YES;
        [mainController.activityView stopAnimating];
    }
    [mainController showIndex];
}

@end
