//
//  BUCBaseTableViewController.m
//  BUClient
//
//  Created by Joe Jeong on 1/24/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCBaseTableViewController.h"
#import "BUCAppDelegate.h"
#import "BUCEventInterceptWindow.h"
#import "BUCUser.h"
#import "BUCNetworkEngine.h"
#import "NSString+NSString_Extended.h"

@implementation BUCBaseTableViewController
#pragma mark - overrided methods
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _postDic = [[NSMutableDictionary alloc] init];
        [_postDic setObject:@"POST" forKey:@"method"];
        _postDataDic = [[NSMutableDictionary alloc] init];
        [_postDic setObject:_postDataDic forKey:@"dataDic"];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    BUCAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    BUCEventInterceptWindow *window = (BUCEventInterceptWindow *)delegate.window;
    self.mainController = (BUCMainViewController *)window.rootViewController;
    
    BUCUser *user = [BUCUser sharedInstance];
    [user addObserver:self forKeyPath:@"username" options:NSKeyValueObservingOptionNew context:NULL];
    [user addObserver:self forKeyPath:@"session" options:NSKeyValueObservingOptionNew context:NULL];
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Loading..."];
    
    self.refreshControl = refresh;
    [refresh addTarget:self action:@selector(getData) forControlEvents:UIControlEventValueChanged];
    
    [self.mainController displayLoading];
}

#pragma mark - public methods
- (IBAction)displayMenu:(id)sender
{
    if (!self.mainController.loadingView.hidden) {
        [self.mainController hideLoading];
    }
    
    [self.mainController showIndex];
}

- (void)alertWithMessage:(NSString *)message
{
    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:nil
                                                       message:message
                                                      delegate:self
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
    [theAlert show];
}

- (void)getData
{
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    BUCBaseTableViewController * __weak weakSelf = self;
    
    if (!engine.hostIsOn) {
        [self alertWithMessage:@"无网络连接"];
        [self.mainController hideLoading];
        [self.refreshControl endRefreshing];
        return;
    }
    
    [engine processRequestDic:self.postDic sync:NO completionHandler:^(NSString *errorMessage) {
        if (engine.responseDic) {
            NSString *result = [engine.responseDic objectForKey:@"result"];
            if ([result isEqualToString:@"success"]) {
                id listData = [engine.responseDic objectForKey:self.listKey];
                if ([listData isKindOfClass:[NSArray class]]) {
                    self.list = (NSArray *)listData;
                } else { // temporary mother fucking forum list solution start
                    self.listDic = (NSDictionary *)listData;
                    NSMutableArray *tempList = [[NSMutableArray alloc] initWithObjects:@"2", @"166", @"16", @"13", @"129", nil];
                    NSDictionary *item;
                    
                    for (NSString *key in self.listDic) {
                        item = [self.listDic objectForKey:key];
                        if (![key length] || ([item count] == 1)) continue;
                        
                        switch ([key integerValue]) {
                            case 2:
                                [tempList setObject:item atIndexedSubscript:0];
                                break;
                            case 129:
                                [tempList setObject:item atIndexedSubscript:1];
                                break;
                            case 166:
                                [tempList setObject:item atIndexedSubscript:2];
                                break;
                            case 16:
                                [tempList setObject:item atIndexedSubscript:3];
                                break;
                            case 13:
                                [tempList setObject:item atIndexedSubscript:4];
                                break;
                            default:
                                break;
                        }
                    }
                    
                    NSMutableArray *sectionList = [[NSMutableArray alloc] init];
                    NSDictionary *section;
                    
                    NSMutableDictionary *forumInfo;
                    NSMutableArray *forumList;
                    NSArray *subforumList;

                    NSDictionary *stuff;
                    NSMutableDictionary *forum;
                    NSMutableDictionary *subforum;
                    
                    NSString *name;
                    
                    for (id item in tempList) {
                        if ([item isKindOfClass:[NSString class]]) continue;
                        
                        forumList = [[NSMutableArray alloc] init];
                        forumInfo = [[NSMutableDictionary alloc] initWithDictionary:[item objectForKey:@"main"]];
                        name = [forumInfo objectForKey:@"name"];
                        [forumInfo setObject:[name urldecode] forKey:@"name"];
                        
                        for (NSString *key in item) {
                            if (![key isEqualToString:@"main"]) {
                                stuff = [item objectForKey:key];
                                forum = [NSMutableDictionary dictionaryWithDictionary:[(NSArray *)[stuff objectForKey:@"main"] lastObject]];
                                name = [forum objectForKey:@"name"];
                                [forum setObject:[name urldecode] forKey:@"name"];
                                [forumList addObject:forum];
                                
                                if ([stuff count] > 1) {
                                    subforumList = [stuff objectForKey:@"sub"];
                                    for (NSDictionary *element in subforumList) {
                                        subforum = [NSMutableDictionary dictionaryWithDictionary:element];
                                        [subforum setObject:[NSString stringWithFormat:@"> %@", [[element objectForKey:@"name"] urldecode]] forKey:@"name"];
                                        [forumList addObject:subforum];
                                    }
                                }
                            }
                        }
                        
                        section = [[NSDictionary alloc] initWithObjectsAndKeys:forumInfo, @"info", forumList, @"forumList", nil];
                        [sectionList addObject:section];
                    }
                    self.list = (NSArray *)sectionList;
                } // temporary mother fucking forum list solution. it's a shame.

                [weakSelf.tableView reloadData];
            } else if ([result isEqualToString:@"fail"]) {
                // current session is expired, must get a new session string
                BUCUser *user = [BUCUser sharedInstance];
                [engine processRequestDic:user.loginDic sync:NO completionHandler:^(NSString *errorMessage) {
                    if (engine.responseDic) {
                        NSString *result = [engine.responseDic objectForKey:@"result"];
                        if ([result isEqualToString:@"success"]) {
                            [weakSelf getData];
                        } else if ([result isEqualToString:@"fail"]) {
                            [weakSelf.mainController displayLoginWithMessage:@"当前密码已失效，请重新登录"];
                        }
                    }
                }];
                
                return;
            }
        } else if (errorMessage) {
            [weakSelf alertWithMessage:errorMessage];
        } else {
            [weakSelf alertWithMessage:@"未知错误"];
        }
        
        [weakSelf.mainController hideLoading];
        [weakSelf.refreshControl endRefreshing];
    }];
}

#pragma mark - Table view data source and delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.list count];
}

#pragma mark - key value observation handler methods
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"username"]) {
        [self.postDataDic setObject:[change objectForKey:NSKeyValueChangeNewKey] forKey:@"username"];
    }
    
    if ([keyPath isEqual:@"session"]) {
        [self.postDataDic setObject:[change objectForKey:NSKeyValueChangeNewKey] forKey:@"session"];
        [self.mainController displayLoading];
        [self getData];
    }
}

@end
