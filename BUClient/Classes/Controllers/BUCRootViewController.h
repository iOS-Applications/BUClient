//
//  BUCRootViewController.h
//  BUClient
//
//  Created by Joe Jeong on 1/12/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BUCIndexViewController.h"
#import "BUCContentViewController.h"

@interface BUCRootViewController : UIViewController
@property (weak, readonly, nonatomic) BUCIndexViewController *indexController;
@property (weak, readonly, nonatomic) BUCContentViewController *contentController;

- (void)switchContentWith:(NSString *)segueIdendifier completion:(void (^)(void))completeHandler;
- (void)showMenu;
- (void)hideMenu;
- (void)disableMenu;
- (void)enableMenu;
- (void)displayLogin;

@end
