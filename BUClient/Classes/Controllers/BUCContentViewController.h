//
//  BUCContentViewController.h
//  BUClient
//
//  Created by Joe Jeong on 1/22/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BUCContentViewController : UIViewController
@property (nonatomic) id info;
@property NSDictionary *infoDic;

- (void)removeChildController;
- (void)displayLoading;
- (void)hideLoading;
@end
