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

@property (weak, nonatomic) BUCEventInterceptWindow *window;

@property (weak, nonatomic) UITextField *curTextField;

@property (nonatomic) BUCNetworkEngine *engine;
@property (nonatomic) BUCUser *user;
@property (nonatomic) NSMutableDictionary *json;
@property (nonatomic) NSURLSessionDataTask *curTask;

@property (nonatomic) NSString *url;
@end

@implementation BUCLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.loadingView.layer.cornerRadius = 10.0;
    
    self.loginButton.layer.cornerRadius = 3;
    self.loginButton.layer.masksToBounds = YES;
    
    self.window = (BUCEventInterceptWindow *)[UIApplication sharedApplication].keyWindow;
    self.window.eventInterceptDelegate = self;
    
    self.engine = [BUCNetworkEngine sharedInstance];
    self.user = [BUCUser sharedInstance];
    self.json = self.user.json;
    
    self.url = [NSString stringWithFormat:self.engine.baseUrl, @"logging"];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.window.eventInterceptDelegate = nil;
}

#pragma mark - IBAction methods
- (IBAction)login:(id)sender {
    [self.curTextField resignFirstResponder];
    
    NSString *username = self.username.text;
    NSString *password = self.password.text;
    if (![self validateUsername:username password:password]) return;
    
    BUCUser *user = self.user;
    BUCNetworkEngine *engine = self.engine;
    BUCLoginViewController * __weak weakSelf = self;
    
    NSMutableDictionary *json = self.json;
    [json setObject:@"login" forKey:@"action"];
    [json setObject:username forKey:@"username"];
    [json setObject:password forKey:@"password"];
    
    NSURLRequest *req = [self requestWithUrl:self.url json:json];
    if (!req) return [self alertWithMessage:@"未知错误"];
    
    [self displaLoading];
    self.curTask = [engine processRequest:req completionHandler:^(NSData *data, NSError *error) {
        [weakSelf hideLoading];
        if (error) return [weakSelf alertWithMessage:error.localizedDescription];
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        if (!json) return [weakSelf alertWithMessage:@"未知错误"];
        
        NSString *result = [json objectForKey:@"result"];
        if ([result isEqualToString:@"success"]) {
            user.username = username;
            user.password = password;
            user.session = [json objectForKey:@"session"];
            [user.json setObject:username forKey:@"username"];
            [user.json setObject:user.session forKey:@"session"];
            user.req = req;
            [user setNewPassword:password];
            [weakSelf saveUserDefault:username];
            
            if (user.isLoggedIn) return [weakSelf performSegueWithIdentifier:@"unwindToUserList" sender:nil];
            // if user is already logged in with a valid account, then unwind to the user list
            
            // if user has not logged in before, set isLoggedIn to YES and bring up the front page
            user.isLoggedIn = YES;
            weakSelf.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [weakSelf performSegueWithIdentifier:@"unwindToContent" sender:nil];
        } else {
            [weakSelf alertWithMessage:@"登录失败，请检查帐号状态"];
        }
    }];
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

#pragma mark - EventInterceptWindow delegate methods
- (void)interceptEvent:(UIEvent *)event
{
    NSSet *touches = [event touchesForView:self.view];
    if ([touches count] == 0) {
        touches = [event touchesForView:(UIView *)self.loginButton];
        if ([touches count] != 0) return;
        
        if (!self.loadingView.hidden) {
            self.loadingView.hidden = YES;
            [self.activityView stopAnimating];
            
            [self cancelLogin];
        }
    } else {
        [self.curTextField resignFirstResponder];
    }
}

#pragma mark - private methods
- (void)alertWithMessage:(NSString *)message
{
    if (![message length]) return;

    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:nil
                                                       message:message
                                                      delegate:self
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
    [theAlert show];
}

- (void)cancelLogin
{
    [self.curTask cancel];
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

- (BOOL)validateUsername:(NSString *)username password:(NSString *)password
{
    if ([username length] == 0 || [password length] == 0) {
        [self alertWithMessage:@"请输入用户名与密码"];
        return NO;
    }
    
    return YES;
}

- (void)saveUserDefault:(NSString *)username
{
    BUCUser *user = self.user;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:username forKey:@"currentUser"];
    NSMutableDictionary *userDic = [defaults objectForKey:@"userDic"];
    if (![userDic objectForKey:username]) {
        userDic = [NSMutableDictionary dictionaryWithDictionary:userDic];
        [userDic setObject:@{@"signature": @""} forKey:username];
        [defaults setObject:userDic forKey:@"userDic"];
    }
    
    NSString *loadImage = [defaults objectForKey:@"loadImage"];
    if ([loadImage length]) {
        user.loadImage = loadImage;
    } else {
        user.loadImage = @"no";
        [defaults setObject:@"no" forKey:@"loadImage"];
    }
    
    [defaults synchronize];

}
@end
