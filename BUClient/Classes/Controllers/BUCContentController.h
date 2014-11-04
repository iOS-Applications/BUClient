//
//  BUCContentViewController.h
//  BUClient
//
//  Created by Joe Jeong on 1/22/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BUCContentController : UINavigationController


- (void)displayLoading;
- (void)hideLoading;

- (void)alertMessage:(NSString *)message;


@end
