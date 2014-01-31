//
//  IBULoginViewController.m
//  iBU
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCLoginViewController.h"
#import "BUCUser.h"
#import "Reachability.h"
#import "BUCLoginButtonView.h"

@interface BUCLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet BUCLoginButtonView *loginButton;

@end

@implementation BUCLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.loadingView.layer.cornerRadius = 10.0;
    
    BUCEventInterceptWindow *window = (BUCEventInterceptWindow *)[UIApplication sharedApplication].keyWindow;
    window.eventInterceptDelegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBAction methods
- (IBAction)login:(id)sender {
    [self.username resignFirstResponder];
    [self.password resignFirstResponder];
    NSString *alertMessage;
    BOOL ready = YES;
    
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
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
    user.username = username;
    user.password = password;
    
    [self.activityView startAnimating];
    self.loadingView.hidden = NO;
    
    BUCLoginViewController * __weak weakSelf = self;
    [user loginCompletionHandler:^(NSString *errorMessage){
        weakSelf.loadingView.hidden = YES;
        [weakSelf.activityView stopAnimating];
        
        if (user.loginSuccess) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:username forKey:@"username"];
            [defaults synchronize];
            
            [user setNewPassword:password];
            weakSelf.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        } else {
            if (errorMessage) [weakSelf alertWithMessage:errorMessage];
        }
    }];
}

#pragma mark - textfield delegate methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
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
            
            BUCUser *user = [BUCUser sharedInstance];
            [user cancelLogin];
        }
    } else {
        [self.username resignFirstResponder];
        [self.password resignFirstResponder];
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

@end
