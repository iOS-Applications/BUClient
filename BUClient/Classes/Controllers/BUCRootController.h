//
//  BUCRootViewController.h
//  BUClient
//
//  Created by Joe Jeong on 1/12/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BUCRootController : UIViewController

- (void)switchContentWith:(NSString *)segueIdendifier completion:(void (^)(void))completeHandler;
- (void)showMenu;
- (void)hideMenu;
- (void)disableMenu;
- (void)enableMenu;

@end
