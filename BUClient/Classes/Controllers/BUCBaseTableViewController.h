//
//  BUCBaseTableViewController.h
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BUCMainViewController.h"

@interface BUCBaseTableViewController : UITableViewController

@property BUCMainViewController *mainController;
@property NSString *listKey;
@property NSArray *list;
@property NSDictionary *listDic;

@property NSMutableDictionary *postDic;
@property NSMutableDictionary *postDataDic;

- (void)alertWithMessage:(NSString *)message;
- (void)getData;

@end
