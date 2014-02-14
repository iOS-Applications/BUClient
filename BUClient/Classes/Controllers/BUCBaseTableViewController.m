//
//  BUCBaseTableViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCBaseTableViewController.h"

@implementation BUCBaseTableViewController
@synthesize user, engine;

#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        user = [BUCUser sharedInstance];
        engine = [BUCNetworkEngine sharedInstance];
        
        _requestDic = [[NSMutableDictionary alloc] init];
        [_requestDic setObject:@"POST" forKey:@"method"];
        _jsonDic = [[NSMutableDictionary alloc] init];
        [_jsonDic setObject:user.username forKey:@"username"];
        [_jsonDic setObject:user.session forKey:@"session"];
        [_requestDic setObject:_jsonDic forKey:@"dataDic"];
        
        _dataList = [[NSMutableArray alloc] init];
        _cellList = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    if (self.loading || self.refreshing) [self cancelLoading];
    [self removeObserver:self forKeyPath:@"rawDataDic" context:NULL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mainController = (BUCMainViewController *)((BUCAppDelegate *)[UIApplication sharedApplication].delegate).mainViewController;
    self.contentController = self.mainController.contentController;
    self.indexController = self.mainController.indexController;
    
    self.avatarList = engine.responseDataArray;
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Loading..."];
    
    self.refreshControl = refresh;
    [refresh addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    
    [self.contentController displayLoading];
    self.loading = YES;
    self.tableView.bounces = NO;
    
    [self addObserver:self forKeyPath:@"rawDataDic" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (![segue.identifier isEqualToString:@"segueToEditor"]) return;
    
    UINavigationController *navVC = (UINavigationController *)segue.destinationViewController;
    BUCEditorViewController *editor = (BUCEditorViewController *)[navVC.childViewControllers lastObject];
    editor.unwindSegueIdendifier = self.unwindSegueIdentifier;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.rawDataDic) {
        self.rawDataList = [self.rawDataDic objectForKey:self.rawListKey];
        [self makeCacheList];
        [self endLoading];
        [self.tableView reloadData];
    }
}

#pragma mark - public methods
- (void)cancelLoading
{
    [self endLoading];
    
    [engine cancelCurrentTask];
}

- (void)suspendLoading
{
    [self.contentController hideLoading];
    [self.refreshControl endRefreshing];
    [engine suspendCurrentTask];
}

- (void)resumeLoading
{
    [self.contentController displayLoading];
    
    [engine resumeCurrentTask];
}

- (void)endLoading
{
    [self.contentController hideLoading];
    [self.refreshControl endRefreshing];
    self.loading = NO;
    self.refreshing = NO;
    self.tableView.bounces = YES;
}

- (void)loadData:(NSDictionary *)postDic
{
    if (!engine.hostIsOn) {
        [self endLoading];
        [self alertWithMessage:@"无网络连接"];
        return;
    }
    
    BUCBaseTableViewController * __weak weakSelf = self;
    [engine processAsyncRequest:postDic completionHandler:^(NSString *message) {
        if (engine.responseDic) {
            NSString *result = [engine.responseDic objectForKey:@"result"];
            if ([result isEqualToString:@"success"]) {
                weakSelf.rawDataDic = engine.responseDic;
                return;
            } else if ([result isEqualToString:@"fail"]) {
                // current session is expired, must get a new session string
                [engine processAsyncRequest:user.loginDic completionHandler:^(NSString *message) {
                    if (engine.responseDic) {
                        NSString *result = [engine.responseDic objectForKey:@"result"];
                        if ([result isEqualToString:@"success"]) {
                            [weakSelf loadData:postDic];
                        } else if ([result isEqualToString:@"fail"]) {
                            weakSelf.user.isLoggedIn = NO;
                            [weakSelf.mainController displayLoginWithMessage:@"当前密码已失效，请重新登录"];
                            [weakSelf.contentController removeChildController];
                        }
                    } else if (message) {
                        if (![message length]) return;
                        
                        [weakSelf alertWithMessage:message];
                    }
                }];
            }
        } else if (message) {
            [weakSelf endLoading];
            if (![message length]) return;
            
            [weakSelf alertWithMessage:message];
        }
    }];
}

- (void)loadImage:(NSString *)imageUrl atIndex:(NSInteger)index
{
    if (!engine.hostIsOn) {
        [self endLoading];
        [self alertWithMessage:@"无网络连接"];
        return;
    }
    
    NSURL *url = [NSURL URLWithString:imageUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [engine processAsyncQueueRequest:request index:index];
}

- (void)makeCacheList
{
    
}

- (void)alertWithMessage:(NSString *)message
{
    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:nil
                                                       message:message
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
    [theAlert show];
}

#pragma mark - action methods
- (IBAction)refresh:(id)sender
{
    if (self.loading || self.refreshing) return;

    self.dataList = [[NSMutableArray alloc] init];
    self.cellList = [[NSMutableArray alloc] init];
    
    if (![sender isKindOfClass:[UIRefreshControl class]]) {
        [self.contentController displayLoading];
        self.loading = YES;
        self.tableView.bounces = NO;
    } else {
        self.refreshing = YES;
    }
    
    [self loadData:self.requestDic];
}

- (IBAction)displayMenu:(id)sender
{
    [self.mainController revealIndex];
}

@end
