//
//  IBULoginViewController.m
//  iBU
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCLoginViewController.h"
#import "BUCAuthManager.h"

@interface BUCLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;

@property (strong, nonatomic) IBOutlet UIView *loadingView;
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
    
    UIView *borderA = [[UIView alloc]
                       initWithFrame:CGRectMake(self.username.frame.origin.x,
                                                self.username.frame.origin.y +
                                                self.username.frame.size.height + 2.0f - 0.5f,
                                                self.username.frame.size.width,
                                                0.5f)];
    borderA.backgroundColor = [UIColor colorWithRed:160.0f/255.0f
                                              green:160.0f/255.0f
                                               blue:160.0f/255.0f
                                              alpha:1.0f];
    [self.view addSubview:borderA];
    
    UIView *borderB = [[UIView alloc]
                       initWithFrame:CGRectMake(self.password.frame.origin.x,
                                                self.password.frame.origin.y +
                                                self.password.frame.size.height + 2.0f - 0.5f,
                                                self.password.frame.size.width,
                                                0.5f)];
    borderB.backgroundColor = [UIColor colorWithRed:160.0f/255.0f
                                              green:160.0f/255.0f
                                               blue:160.0f/255.0f
                                              alpha:1.0f];
    [self.view addSubview:borderB];
}

#pragma mark - IBAction methods
- (IBAction)login:(id)sender
{
    [self.curTextField resignFirstResponder];
    
    NSString *username = self.username.text;
    NSString *password = self.password.text;
    if ([username length] == 0 || [password length] == 0)
    {
        [self alertWithMessage:@"请输入用户名与密码"];
        return;
    }
    
    BUCAuthManager *authManager = [BUCAuthManager sharedInstance];
    BUCLoginViewController * __weak weakSelf = self;
    
    [authManager
     loginWithUsername:username
     
     andPassword:password
     
     onSuccess:^(void)
     {
         [weakSelf hideLoading];
         weakSelf.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
         [weakSelf performSegueWithIdentifier:@"unwindToContent" sender:nil];
     }
     
     onFail:^(NSError *error)
     {
         [weakSelf hideLoading];
         [weakSelf alertWithMessage:error.localizedDescription];
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
    [self.view addSubview:self.loadingView];
    self.view.userInteractionEnabled = NO;
}

- (void)hideLoading
{
    [self.loadingView removeFromSuperview];
    [self.activityView stopAnimating];
    self.view.userInteractionEnabled = YES;
}

@end





















