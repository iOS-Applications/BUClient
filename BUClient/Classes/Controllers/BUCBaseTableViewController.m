//
//  BUCBaseTableViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCBaseTableViewController.h"

@interface BUCBaseTableViewController ()
@property (nonatomic) NSString *baseUrl;
@end

@implementation BUCBaseTableViewController
@synthesize user, engine;

#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        user = [BUCUser sharedInstance];
        engine = [BUCNetworkEngine sharedInstance];
        
        _taskList = [[NSMutableArray alloc] init];
        _task = [[BUCTask alloc] init];
        _task.index = 0;
        _task.json = user.json;
        _task.silence = NO;
        [_taskList addObject:_task];
    }
    
    return self;
}

- (void)dealloc
{
    if (self.loading || self.refreshing) [self cancelLoading];
    for (BUCTask *task in self.taskList) {
        [task removeObserver:self forKeyPath:@"jsonData" context:NULL];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mainController = (BUCMainViewController *)((BUCAppDelegate *)[UIApplication sharedApplication].delegate).mainViewController;
    self.contentController = self.mainController.contentController;
    self.indexController = self.mainController.indexController;
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Loading..."];
    
    self.refreshControl = refresh;
    [refresh addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    
    [self.contentController displayLoading];
    self.loading = YES;
    self.tableView.bounces = NO;
    

    [self.task addObserver:self forKeyPath:@"jsonData" options:NSKeyValueObservingOptionNew context:NULL];
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
    [self makeCacheList];
    [self endLoading];
    [self.tableView reloadData];
}

#pragma mark - public methods
- (void)cancelLoading
{
    [self endLoading];
    for (BUCTask *task in self.taskList) {
        [task.task cancel];
        for (BUCTask *task in task.taskList) {
            [task.task cancel];
        }
    }
}

- (void)suspendLoading
{
    [self.contentController hideLoading];
    [self.refreshControl endRefreshing];
    for (BUCTask *task in self.taskList) {
        [task.task suspend];
        for (BUCTask *task in task.taskList) {
            [task.task suspend];
        }
    }
}

- (void)resumeLoading
{
    [self.contentController displayLoading];
    for (BUCTask *task in self.taskList) {
        [task.task resume];
        for (BUCTask *task in task.taskList) {
            [task.task resume];
        }
    }
}

- (void)endLoading
{
    [self.contentController hideLoading];
    [self.refreshControl endRefreshing];
    self.loading = NO;
    self.refreshing = NO;
    self.tableView.bounces = YES;
}

- (void)loadJSONOfTask:(BUCTask *)task
{
    if (!task.json || !task.url) return; // ad hoc message, do nothing, just return
    
    BOOL silence = task.silence;
    
    if (!engine.hostIsOn) {
        if (!silence) return [self alertWithMessage:@"无网络连接"];
        return;
    }
    
    NSURLRequest *req = [self requestWithUrl:[NSString stringWithFormat:engine.baseUrl, task.url] json:task.json];
    if (!req) {
        if (!silence) return [self alertWithMessage:@"未知错误"];
        return;
    }
    
    task.done = NO;
    BUCBaseTableViewController * __weak weakSelf = self;
    task.task = [engine processRequest:req completionHandler:^(NSData *data, NSError *error) {
        if (error) {
            if (!silence) return [weakSelf alertWithMessage:error.localizedDescription];
            return;
        }
        
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (!jsonData) {
            if (!silence) return [weakSelf alertWithMessage:@"未知错误"];
            return;
        }
        
        NSString *result = [jsonData objectForKey:@"result"];
        if ([result isEqualToString:@"fail"]) {
            // current session is expired, must get a new session string
            task.task = [engine processRequest:user.req completionHandler:^(NSData *data, NSError *error) {
                if (error) {
                    if (!silence) return [weakSelf alertWithMessage:error.localizedDescription];
                    return;
                }
                
                NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                if (!jsonData) {
                    return [weakSelf alertWithMessage:@"未知错误"];
                    return;
                }
                
                NSString *result = [jsonData objectForKey:@"result"];
                if ([result isEqualToString:@"fail"]) {
                    user.isLoggedIn = NO;
                    [weakSelf.mainController displayLoginWithMessage:@"当前密码已失效，请重新登录"];
                    return [weakSelf.contentController removeChildController];
                }
                
                user.session = [jsonData objectForKey:@"session"];
                [task.json setObject:user.session forKey:@"session"];
                [weakSelf loadJSONOfTask:task];
            }];
            return;
        }
        task.jsonData = jsonData;
    }];
}

- (void)loadDataOfTask:(BUCTask *)task
{
    if (!engine.hostIsOn) return;
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:task.url]
                                                       cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                   timeoutInterval:30];
    
    task.done = NO;
    task.task = [engine processRequest:req completionHandler:^(NSData *data, NSError *error) {
        task.done = YES;
        if (error || ![data length]) return;
        
        task.data = data;
    }];
}

- (void)makeCacheList
{

}

- (void)startAllTasks
{
    for (BUCTask *task in self.taskList) {
        [self loadJSONOfTask:task];
    }
}

- (void)alertWithMessage:(NSString *)message
{
    [self endLoading];
    if (![message length]) return;
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
    
    if (![sender isKindOfClass:[UIRefreshControl class]]) {
        [self.contentController displayLoading];
        self.loading = YES;
        self.tableView.bounces = NO;
    } else {
        self.refreshing = YES;
    }
    
    [self startAllTasks];
}

- (IBAction)displayMenu:(id)sender
{
    [self.mainController revealIndex];
}

@end
