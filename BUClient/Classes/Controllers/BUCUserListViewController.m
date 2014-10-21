//
//  BUCUserListViewController.m
//  BUClient
//
//  Created by Joe Jeong on 2/10/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCUserListViewController.h"
#import "BUCUser.h"
#import "BUCNetworkEngine.h"
#import "BUCAppDelegate.h"
#import "BUCRootViewController.h"
#import "BUCContentViewController.h"
#import "BUCLoginViewController.h"
#import "NSObject+BUCTools.h"

@interface BUCUserListViewController ()
@property (nonatomic) NSMutableArray *list;
@property (nonatomic) NSUserDefaults *defaults;
@property (nonatomic )NSInteger selectedRow;
@property (nonatomic) NSString *currentUser;

@property (weak, nonatomic) BUCContentViewController *contentController;
@property (weak, nonatomic) BUCRootViewController *mainController;

@end

@implementation BUCUserListViewController
#pragma mark - overrided methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.defaults = [NSUserDefaults standardUserDefaults];
    self.list = [[NSMutableArray alloc] init];
    NSDictionary *userDic = [self.defaults objectForKey:@"userDic"];
    for (NSString *key in userDic) {
        [self.list addObject:key];
    }
    
    self.contentController = self.mainController.contentController;
    
    self.currentUser = [BUCUser sharedInstance].username;
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.mainController enableMenu];
}

#pragma mark - action methods
- (IBAction)unwindToUserList:(UIStoryboardSegue *)segue
{
    self.currentUser = [BUCUser sharedInstance].username;

    if (![self.list containsObject:self.currentUser]) {
        [self.list addObject:self.currentUser];
        [self.tableView reloadData];
    }
    
    [self.mainController disableMenu];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.list count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"userCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSString *username = [self.list objectAtIndex:indexPath.row];
    cell.textLabel.text = username;
    
    if ([username isEqualToString:self.currentUser]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.userInteractionEnabled = NO;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.userInteractionEnabled = YES;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *username = [self.list objectAtIndex:indexPath.row];
        [self.list removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        NSMutableArray *userList = [NSMutableArray arrayWithArray:[self.defaults objectForKey:@"userList"]];
        [userList removeObject:username];
        [self.defaults setObject:userList forKey:@"userList"];
        [self.defaults synchronize];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedRow = indexPath.row;
    [self alertWithMessage:[NSString stringWithFormat:@"切换至用户: %@ 确定吗？ ", [self.list objectAtIndex:self.selectedRow]]];
}

#pragma mark - alert view delegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView numberOfButtons] == 1 || buttonIndex == 1) return;
        
    [self changeUser];
}

#pragma mark - private methods
- (void)alertWithMessage:(NSString *)message
{

    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:nil
                                                       message:message
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
    
    NSRange r = (NSRange)[message rangeOfString:@"吗"];
    if (r.length) {
        theAlert.delegate = self;
        [theAlert addButtonWithTitle:@"Cancel"];
    }
    
    [theAlert show];
}

- (void)changeUser
{
    NSString *username = [self.list objectAtIndex:self.selectedRow];
    BUCUser *user = [BUCUser sharedInstance];
    user.username = username;
    NSString *password = [user getPassword];
    
    NSMutableDictionary *json = user.json;
    [json setObject:@"login" forKey:@"action"];
    [json setObject:username forKey:@"username"];
    [json setObject:password forKey:@"password"];
    
    static NSString *url = @"logging";
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    NSError *error;
    NSURLRequest *req = [self requestWithUrl:[NSString stringWithFormat:engine.baseUrl, url] json:json error:&error];
    
    [self displayLoading];
    
    BUCUserListViewController __weak *weakSelf = self;
    [engine processRequest:req completionHandler:^(NSData *data, NSError *error) {
        [weakSelf hideLoading];
        if (error) return [weakSelf alertWithMessage:error.localizedDescription];
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (!json) return [weakSelf alertWithMessage:@"未知错误"];

        NSString *result = [json objectForKey:@"result"];
        if ([result isEqualToString:@"success"]) {
            user.username = username;
            user.password = password;
            user.session = [json objectForKey:@"session"];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:username forKey:@"currentUser"];
            [defaults synchronize];
            
            [user setNewPassword:password];
            weakSelf.currentUser = username;
            [weakSelf.tableView reloadData];
        } else if ([result isEqualToString:@"fail"]) {
            [weakSelf alertWithMessage:@"当前密码已失效，请手动登录"];
            return [self performSegueWithIdentifier:@"segueToLogin" sender:nil];
        }

    }];
}

- (void)displayLoading
{
    [self.contentController displayLoading];
}

- (void)hideLoading
{
    [self.contentController hideLoading];
}
@end






















