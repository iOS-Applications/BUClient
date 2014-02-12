//
//  BUCBaseTableViewController.h
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BUCMainViewController.h"
#import "BUCContentViewController.h"
#import "BUCUser.h"
#import "BUCNetworkEngine.h"
#import "BUCIndexViewController.h"
#import "NSString+NSString_Extended.h"

@interface BUCBaseTableViewController : UITableViewController

@property (weak, nonatomic) BUCMainViewController *mainController;
@property (weak, nonatomic) BUCContentViewController *contentController;
@property (weak, nonatomic) BUCIndexViewController *indexController;

@property (weak, nonatomic) BUCUser *user;
@property (weak, nonatomic) BUCNetworkEngine *engine;

@property NSString *listKey;
@property NSArray *list;
@property NSDictionary *responseDic;
@property NSMutableArray *responseDataArray;

@property BOOL loading;
@property BOOL refreshing;

@property NSMutableDictionary *postDic;
@property NSMutableDictionary *postDataDic;

@property NSString *unwindSegueIdentifier;

- (void)alertWithMessage:(NSString *)message;
- (IBAction)refresh:(id)sender;
- (void)loadData:(NSDictionary *)postDic;
- (void)loadImage:(NSString *)imageUrl atIndex:(NSInteger)index;
- (void)endLoading;
- (void)cancelLoading;
- (void)suspendLoading;
- (void)resumeLoading;

@end
