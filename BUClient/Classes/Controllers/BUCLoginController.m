#import "BUCLoginController.h"
#import "BUCDataManager.h"
#import "BUCConstants.h"
#import "BUCAppDelegate.h"


@interface BUCLoginController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topSpace;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *viewTapRecognizer;


@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (weak, nonatomic) UITextField *currentTextField;

@property (nonatomic) NSDictionary *userList;
@property (nonatomic) NSString *currentUser;

@property (nonatomic) BUCAppDelegate *appDelegate;


@end


@implementation BUCLoginController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([[UIScreen mainScreen] bounds].size.height < 568.0f) {
        self.topSpace.constant = 100.0f;
    }
    
    self.loginButton.layer.cornerRadius = 4.0f;
    self.loginButton.layer.masksToBounds = YES;
    
    self.loadingView.layer.cornerRadius = 8.0f;
    self.loadingView.layer.masksToBounds = YES;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (self.navigationController) {
        [self.username becomeFirstResponder];
        self.userList = [defaults dictionaryForKey:@"userList"];
    } else {
        self.currentUser = [defaults stringForKey:@"username"];
        self.username.text = self.currentUser;
        if (self.currentUser) {
            [self.password becomeFirstResponder];
        } else {
            [self.username becomeFirstResponder];
        }
    }
    
    self.appDelegate = [UIApplication sharedApplication].delegate;
}


#pragma mark - IBAction methods
- (IBAction)login:(id)sender {
    BUCLoginController * __weak weakSelf = self;
    NSString *username = self.username.text;
    NSString *password = self.password.text;
    [self.currentTextField resignFirstResponder];
    
    if ([username length] == 0 || [password length] == 0) {
        [self.appDelegate alertWithMessage:@"用户名与密码不能为空"];
        return;
    } else if (self.navigationController) {
        NSString *userKey = [username lowercaseString];
        if ([userKey isEqualToString:self.currentUser] || [self.userList objectForKey:userKey]) {
            [self.appDelegate alertWithMessage:@"该帐号已添加"];
            return;
        }
    }
    
    [self displayLoading];
    [[BUCDataManager sharedInstance]
     
     loginWithUsername:username
     
     password:password
     
     onSuccess:^{
         [weakSelf hideLoading];
         if (weakSelf.presentingViewController) {
             [weakSelf.presentingViewController dismissViewControllerAnimated:YES completion:nil];
         } else {
             [weakSelf performSegueWithIdentifier:@"addNewAccount" sender:nil];
         }
     }
     
     onFail:^(NSError *error) {
         [weakSelf hideLoading];
         [weakSelf.appDelegate alertWithMessage:error.localizedDescription];
     }];
}


- (IBAction)dissmissTextfield:(id)sender {
    [self.currentTextField resignFirstResponder];
}


- (void)displayLoading {
    self.loadingView.hidden = NO;
    [self.activityIndicator startAnimating];
    self.view.userInteractionEnabled = NO;
}


- (void)hideLoading {
    self.loadingView.hidden = YES;
    [self.activityIndicator stopAnimating];
    self.view.userInteractionEnabled = YES;
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





















