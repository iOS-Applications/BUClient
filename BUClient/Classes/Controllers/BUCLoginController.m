//
//  IBULoginViewController.m
//  iBU
//
//  Created by Joe Jeong on 1/8/14.
//  Copyright (c) 2014 Jox. All rights reserved.
//

#import "BUCLoginController.h"
#import "BUCAuthManager.h"


@interface BUCLoginController ()


@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;

@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *viewTapRecognizer;

@property (weak, nonatomic) UITextField *currentTextField;


@end


@implementation BUCLoginController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.loadingView.center = self.view.center;
    self.loadingView.layer.cornerRadius = 10.0f;

    self.loginButton.layer.cornerRadius = 3;
    self.loginButton.layer.masksToBounds = YES;
    
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    CGRect frame = self.username.frame;
    CGFloat textfieldHeight = CGRectGetHeight(frame);
    CGFloat borderAOriginY = CGRectGetMinY(frame) + textfieldHeight;
    UIColor *borderColor = [UIColor colorWithRed:217.0f/255.0f green:217.0f/255.0f blue:217.0f/255.0f alpha:1.0f];
    
    UIView *borderA = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(frame), borderAOriginY, CGRectGetWidth(frame), 1.0f)];
    borderA.backgroundColor = borderColor;
    [self.view addSubview:borderA];
    
    UIView *borderB = [[UIView alloc] initWithFrame:CGRectZero];
    borderB.frame = CGRectOffset(borderA.frame, 0.0f, textfieldHeight);
    borderB.backgroundColor = borderColor;

    [self.view addSubview:borderB];
}


#pragma mark - IBAction methods
- (IBAction)login:(id)sender {
    BUCLoginController * __weak weakSelf = self;
    NSString *username = self.username.text;
    NSString *password = self.password.text;
    [self.currentTextField resignFirstResponder];
    
    if ([username length] == 0 || [password length] == 0) {
        [self alertMessage:@"请输入用户名与密码"];
        return;
    }
    

    [[BUCAuthManager sharedInstance]
     
     loginWithUsername:username
     
     andPassword:password
     
     onSuccess:^(void) {
         [weakSelf hideLoading];
         [weakSelf performSegueWithIdentifier:weakSelf.unwindIdentifier sender:nil];
     }
     
     onFail:^(NSError *error) {
         [weakSelf hideLoading];
         [weakSelf alertMessage:error.localizedDescription];
     }];
    
    [self displayLoading];
}

- (IBAction)dissmissTextfield:(id)sender {
    [self.currentTextField resignFirstResponder];
}

#pragma mark - textfield delegate methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.currentTextField = textField;
}

#pragma mark - private methods
- (void)alertMessage:(NSString *)message {
    [[[UIAlertView alloc]
     initWithTitle:nil
     message:message
     delegate:self
     cancelButtonTitle:@"OK"
     otherButtonTitles:nil] show];
}

- (void)displayLoading {
    [self.activityView startAnimating];
    self.loadingView.hidden = NO;
    self.view.userInteractionEnabled = NO;
}

- (void)hideLoading {
    self.loadingView.hidden = YES;
    [self.activityView stopAnimating];
    self.view.userInteractionEnabled = YES;
}

@end





















