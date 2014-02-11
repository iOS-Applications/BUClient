//
//  BUCMainViewController.h
//  BUClient
//
//  Created by Joe Jeong on 1/12/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BUCIndexViewController.h"
#import "BUCContentViewController.h"

@interface BUCMainViewController : UIViewController
@property (weak, nonatomic) BUCIndexViewController *indexController;
@property (weak, nonatomic) BUCContentViewController *contentController;

- (void)displayLoginWithMessage:(NSString *)message;
- (void)revealIndex;
- (void)hideIndex;
- (void)switchContentWith:(NSString *)segueIdendifier;

- (void)disableIndex;
- (void)enableIndex;

@end
