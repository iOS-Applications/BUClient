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
#import "NSObject+BUCTools.h"
#import "BUCTask.h"

@interface BUCBaseTableViewController : UITableViewController

@property (weak, nonatomic) BUCMainViewController *mainController;
@property (weak, nonatomic) BUCContentViewController *contentController;
@property (weak, nonatomic) BUCIndexViewController *indexController;

@property (nonatomic) BUCUser *user;
@property (nonatomic) BUCNetworkEngine *engine;

@property (nonatomic) BUCTask *task;
@property (nonatomic) NSMutableArray *taskList;
@property (nonatomic) NSString *jsonListKey;

@property (nonatomic) NSMutableArray *dataList;
@property (nonatomic) NSMutableArray *cellList;

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL refreshing;
@property (nonatomic) NSInteger pageCount;

@property (nonatomic) NSString *unwindSegueIdentifier;

- (void)alertWithMessage:(NSString *)message;
- (IBAction)refresh:(id)sender;
- (void)loadDataOfTask:(BUCTask *)task;
- (void)loadJSONOfTask:(BUCTask *)task;
- (void)makeCacheList;
- (void)startAllTasks;
- (void)endLoading;
- (void)cancelLoading;
- (void)suspendLoading;
- (void)resumeLoading;

@end
