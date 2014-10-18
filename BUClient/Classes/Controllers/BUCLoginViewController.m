//
//  IBULoginViewController.m
//  iBU
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCLoginViewController.h"
#import "BUCUser.h"
#import "BUCNetworkEngine.h"
#import "NSObject+BUCTools.h"

@interface BUCLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;

@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *viewTapRecognizer;

@property (weak, nonatomic) UITextField *curTextField;
@end

@implementation BUCLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.loadingView.layer.cornerRadius = 10.0;
    
    self.loginButton.layer.cornerRadius = 3;
    self.loginButton.layer.masksToBounds = YES;
}

#pragma mark - IBAction methods
- (IBAction)login:(id)sender {
    [self.curTextField resignFirstResponder];
    
    NSString *username = self.username.text;
    NSString *password = self.password.text;
    if ([username length] == 0 || [password length] == 0) {
        [self alertWithMessage:@"请输入用户名与密码"];
        return;
    }
    
    BUCUser *user = [BUCUser sharedInstance];    
    NSMutableDictionary *json = user.json;
    [json setObject:@"login" forKey:@"action"];
    [json setObject:username forKey:@"username"];
    [json setObject:password forKey:@"password"];

    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    NSString *url = [NSString stringWithFormat:engine.baseUrl, @"logging"];
    NSURLRequest *req = [self requestWithUrl:url json:json];
    if (!req) {
        return [self alertWithMessage:@"未知错误"];
    }
    
    BUCLoginViewController * __weak weakSelf = self;
    self.view.userInteractionEnabled = NO;
    
    [engine processRequest:req completionHandler:^(NSData *data, NSError *error) {
        [weakSelf hideLoading];
        weakSelf.view.userInteractionEnabled = YES;
        if (error) {
            [weakSelf alertWithMessage:error.localizedDescription];
            return;
        }
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (!json) {
            [weakSelf alertWithMessage:@"未知错误"];
            return;
        }
        
        NSString *result = [json objectForKey:@"result"];
        if ([result isEqualToString:@"success"]) {
            user.username = username;
            user.password = password;
            user.session = [json objectForKey:@"session"];
            [user.json setObject:username forKey:@"username"];
            [user.json setObject:user.session forKey:@"session"];
            user.req = req;
            [user setNewPassword:password];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:username forKey:@"currentUser"];
            [defaults synchronize];
            
            if (user.isLoggedIn) {
                [weakSelf performSegueWithIdentifier:@"unwindToUserList" sender:nil];
                return;
            }
            // if user is already logged in with a valid account, then unwind to the user list
            
            // if user has not logged in before, set isLoggedIn to YES and bring up the front page
            user.isLoggedIn = YES;
            weakSelf.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [weakSelf performSegueWithIdentifier:@"unwindToContent" sender:nil];
        } else {
            [weakSelf alertWithMessage:@"登录失败，请检查帐号状态"];
        }
    }];
    
    [self displaLoading];
}

- (IBAction)dissmissTextfield:(id)sender {
    [self.curTextField resignFirstResponder];
}

#pragma mark - textfield delegate methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.curTextField = textField;
}

#pragma mark - private methods
- (void)alertWithMessage:(NSString *)message
{
    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:nil
                                                       message:message
                                                      delegate:self
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
    [theAlert show];
}

- (void)displaLoading
{
    [self.activityView startAnimating];
    self.loadingView.hidden = NO;
    self.loginButton.enabled = NO;
}

- (void)hideLoading
{
    self.loadingView.hidden = YES;
    [self.activityView stopAnimating];
    self.loginButton.enabled = YES;
}

@end





















