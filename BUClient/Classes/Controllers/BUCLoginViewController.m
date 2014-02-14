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

@interface BUCLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;

@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property (weak, nonatomic) BUCEventInterceptWindow *window;

@property (weak, nonatomic) UITextField *curTextField;
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
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    self.window.eventInterceptDelegate = nil;
}

#pragma mark - IBAction methods
- (IBAction)login:(id)sender {
    [self.curTextField resignFirstResponder];
    
    NSString *alertMessage;
    BOOL ready = YES;
    
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    if (!engine.hostIsOn) {
        alertMessage = @"无网络连接";
        ready = NO;
    }
    
    NSString *username = self.username.text;
    NSString *password = self.password.text;
    if ([username length] == 0 || [password length] == 0) {
        alertMessage = @"请输入用户名与密码";
        ready = NO;
    }
    
    if (!ready) {
        [self alertWithMessage:alertMessage];
        return;
    }
    
    BUCUser *user = [BUCUser sharedInstance];
    NSMutableDictionary *loginDataDic = user.loginJsonDic;
    [loginDataDic setObject:username forKey:@"username"];
    [loginDataDic setObject:password forKey:@"password"];
    
    NSMutableDictionary *loginDic = user.loginDic;
    
    [self.activityView startAnimating];
    self.loadingView.hidden = NO;
    self.loginButton.enabled = NO;
    
    BUCLoginViewController * __weak weakSelf = self;
    
    [engine processAsyncRequest:loginDic completionHandler:^(NSString *errorMessage) {
        weakSelf.loadingView.hidden = YES;
        [weakSelf.activityView stopAnimating];
        weakSelf.loginButton.enabled = YES;
        
        if (engine.responseDic) {
            NSString *result = [engine.responseDic objectForKey:@"result"];
            if ([result isEqualToString:@"success"]) {
                user.username = username;
                user.password = password;
                user.session = [engine.responseDic objectForKey:@"session"];
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:username forKey:@"currentUser"];
                NSMutableArray *userList = [defaults objectForKey:@"userList"];
                if (!userList) {
                    userList = [[NSMutableArray alloc] init];
                    [userList addObject:username];
                } else if (![userList containsObject:username]) {
                    userList = [NSMutableArray arrayWithArray:userList];
                    [userList addObject:username];
                }
                [defaults setObject:userList forKey:@"userList"];
                
                NSString *loadImage = [defaults objectForKey:@"loadImage"];
                if ([loadImage length]) {
                    user.loadImage = loadImage;
                } else {
                    user.loadImage = @"no";
                    [defaults setObject:@"no" forKey:@"loadImage"];
                }
                
                [defaults synchronize];
                
                
                [user setNewPassword:password];
                
                if (user.isLoggedIn) { // if user is already logged in with a valid account, then unwind to the user list
                    [self performSegueWithIdentifier:@"unwindToUserList" sender:nil];
                    return;
                }
                
                user.isLoggedIn = YES; // if user has not logged in before, set isLoggedIn to YES and bring up the front page 
                
                weakSelf.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                [weakSelf performSegueWithIdentifier:@"unwindToContent" sender:nil];
            } else if ([result isEqualToString:@"fail"]) {
                errorMessage = @"用户名与密码不匹配或积分为负无法登录，请联系联盟管理员，或重新尝试";
                [weakSelf alertWithMessage:errorMessage];
                return;
            }
        } else if (errorMessage) {
            if (![errorMessage length]) return;
            
            [weakSelf alertWithMessage:errorMessage];
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
    UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:nil
                                                       message:message
                                                      delegate:self
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
    [theAlert show];
}

- (void)cancelLogin
{
    BUCNetworkEngine *engine = [BUCNetworkEngine sharedInstance];
    [engine cancelCurrentTask];
}

@end
