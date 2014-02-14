//
//  BUCBaseTableViewController.h
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BUCAppDelegate.h"
#import "BUCMainViewController.h"
#import "BUCIndexViewController.h"
#import "BUCContentViewController.h"
#import "BUCEditorViewController.h"
#import "BUCUser.h"
#import "BUCNetworkEngine.h"
#import "BUCSection.h"
#import "BUCForum.h"
#import "BUCPost.h"
#import "BUCPoster.h"
#import "BUCTableCell.h"
#import "NSString+NSString_Extended.h"

@interface BUCBaseTableViewController : UITableViewController

@property (weak, nonatomic) BUCMainViewController *mainController;
@property (weak, nonatomic) BUCContentViewController *contentController;
@property (weak, nonatomic) BUCIndexViewController *indexController;

@property (weak, nonatomic) BUCUser *user;
@property (weak, nonatomic) BUCNetworkEngine *engine;

@property (nonatomic) NSDictionary *rawDataDic;
@property (nonatomic) NSString *rawListKey;
@property (nonatomic) NSArray *rawDataList;
@property (nonatomic) NSMutableArray *dataList;
@property (nonatomic) NSMutableArray *cellList;
@property (nonatomic) NSMutableArray *avatarList;

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL refreshing;

@property (nonatomic) NSMutableDictionary *requestDic;
@property (nonatomic) NSMutableDictionary *jsonDic;

@property (nonatomic) NSString *unwindSegueIdentifier;

- (void)alertWithMessage:(NSString *)message;
- (IBAction)refresh:(id)sender;
- (void)loadData:(NSDictionary *)postDic;
- (void)loadImage:(NSString *)imageUrl atIndex:(NSInteger)index;
- (void)urldecodeData;
- (void)makeCacheList;
- (void)endLoading;
- (void)cancelLoading;
- (void)suspendLoading;
- (void)resumeLoading;

@end
