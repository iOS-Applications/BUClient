#import "BUCLoginController.h"
#import "BUCAuthManager.h"


@interface BUCLoginController ()

@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSpace;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *viewTapRecognizer;

@property (weak, nonatomic) UITextField *currentTextField;


@end


@implementation BUCLoginController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([[UIScreen mainScreen] bounds].size.height < 568.0f) {
        self.topSpace.constant = 100.0f;
    }
    
    self.loginButton.layer.cornerRadius = 3;
    self.loginButton.layer.masksToBounds = YES;
    
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
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
     
     password:password
     
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


@end





















