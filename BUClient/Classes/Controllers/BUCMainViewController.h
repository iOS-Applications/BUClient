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
@property (weak, readonly, nonatomic) BUCIndexViewController *indexController;
@property (weak, readonly, nonatomic) BUCContentViewController *contentController;

- (void)displayLoginWithMessage:(NSString *)message;
- (void)revealIndex;
- (void)hideIndex;
- (void)switchContentWith:(NSString *)segueIdendifier completion:(void (^)(void))completeHandler;

- (void)disableIndex;
- (void)enableIndex;

@end
