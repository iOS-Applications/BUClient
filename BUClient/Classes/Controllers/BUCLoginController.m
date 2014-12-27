#import "BUCLoginController.h"
#import "BUCDataManager.h"
#import "BUCConstants.h"
#import "BUCAppDelegate.h"


@interface BUCLoginController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UISwitch *campus;

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
    
    self.loginButton.layer.cornerRadius = 4.0f;
    self.loginButton.layer.masksToBounds = YES;
    
    self.loadingView.layer.cornerRadius = 8.0f;
    self.loadingView.layer.masksToBounds = YES;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (self.navigationController) {
        [self.username becomeFirstResponder];
        self.userList = [defaults dictionaryForKey:@"userList"];
        self.navigationItem.title = @"添加帐号";
    } else {
        self.currentUser = [defaults stringForKey:@"username"];
        self.username.text = self.currentUser;
        if (self.currentUser) {
            [self.password becomeFirstResponder];
        } else {
            [self.username becomeFirstResponder];
        }
    }
    
    self.campus.on = [[NSUserDefaults standardUserDefaults] boolForKey:BUCCampusNetworkSetting];
    
    self.appDelegate = [UIApplication sharedApplication].delegate;
}


- (BOOL)shouldAutorotate {
    return NO;
}


#pragma mark - IBAction methods
- (IBAction)login:(id)sender {
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
         [self hideLoading];
         if (self.presentingViewController) {
             [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
         } else {
             [self performSegueWithIdentifier:@"loginToSettings" sender:nil];
         }
     }
     
     onFail:^(NSString *errorMsg) {
         [self hideLoading];
         [self.appDelegate alertWithMessage:errorMsg];
     }];
}

- (IBAction)hostChanged:(UISwitch *)sender {    
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:BUCCampusNetworkSetting];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:BUCNetworkSettingChangedNotification object:nil];
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





















