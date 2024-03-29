#import "BUCSettingsController.h"
#import "BUCConstants.h"
#import "BUCEditorController.h"
#import "BUCRootController.h"
#import "UIImage+BUCImageCategory.h"

@interface BUCSettingsController () <UITextViewDelegate>

@property (nonatomic) BOOL rotateFlag;

@property (nonatomic) NSMutableDictionary *userList;
@property (nonatomic) NSMutableArray *list;

@property (nonatomic) NSString *currentUser;
@property (nonatomic) NSString *password;
@property (nonatomic) NSString *uid;
@property (nonatomic) NSString *signature;
@property (nonatomic) NSMutableDictionary *userSettings;

@property (nonatomic) BUCRootController *rootController;


@property (weak, nonatomic) IBOutlet UIButton *addAccountButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UITextView *signatureEditor;
@property (weak, nonatomic) IBOutlet UISwitch *campusNetwork;
@property (weak, nonatomic) IBOutlet UISwitch *internetImage;

@end

@implementation BUCSettingsController
#pragma mark - setup
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    if ([self.signatureEditor isFirstResponder]) {
        [self.signatureEditor resignFirstResponder];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    [UIViewController attemptRotationToDeviceOrientation];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.sectionHeaderHeight = 0.0f;
    self.tableView.sectionFooterHeight = 0.0f;
    
    [self.addAccountButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRed:217.0f/255.0f green:217.0f/255.0f blue:217.0f/255.0f alpha:1.0f]] forState:UIControlStateHighlighted];
    [self.logoutButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRed:217.0f/255.0f green:217.0f/255.0f blue:217.0f/255.0f alpha:1.0f]] forState:UIControlStateHighlighted];
    
    self.signatureEditor.layer.borderWidth = 0.5f;
    self.signatureEditor.layer.borderColor = [UIColor lightGrayColor].CGColor;

    self.rootController = (BUCRootController *)[self.navigationController.viewControllers objectAtIndex:0];
    
    [self loadUserData];
    [self.tableView reloadData];
}


- (void)loadUserData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userList = [defaults objectForKey:@"userList"];
    self.userList = [userList mutableCopy];
    self.list = [[userList allValues] mutableCopy];
    self.currentUser = [defaults stringForKey:@"username"];
    self.password = [defaults stringForKey:@"password"];
    self.uid = [defaults stringForKey:@"uid"];
    self.signature = [defaults stringForKey:@"signature"];
    self.userSettings = [[self.userList objectForKey:[self.currentUser lowercaseString]] mutableCopy];
    self.campusNetwork.on = [defaults boolForKey:BUCCampusNetworkSetting];
    self.internetImage.on = [defaults boolForKey:BUCInternetImageSetting];
    self.signatureEditor.text = self.signature;
}


#pragma mark - rotate handling
- (BOOL)shouldAutorotate {
    if (self.rotateFlag) {
        return NO;
    } else {
        self.rotateFlag = YES;
        return YES;
    }
}

#pragma mark - keyboard and text view management
- (void)keyboardWasShown:(NSNotification *)notification {
    if ([self.signatureEditor isFirstResponder]) {
        CGRect frame = [self.tableView.tableFooterView convertRect:self.signatureEditor.frame toView:self.tableView];
        CGPoint offset = self.tableView.contentOffset;
        offset.y = frame.origin.y - BUCDefaultMargin;
        [self.tableView setContentOffset:offset];
        [self textViewDidChange:self.signatureEditor];
    }
}


- (void)textViewDidChange:(UITextView *)textView {
    NSRange selectedRange = textView.selectedRange;
    if (selectedRange.length == 0) {
        selectedRange.length = 1;
    }
    if (selectedRange.location == textView.textStorage.length) {
        selectedRange.location = selectedRange.location - 1;
    }
    CGRect frame = [textView.layoutManager boundingRectForGlyphRange:selectedRange inTextContainer:textView.textContainer];
    CGFloat bottom = ceilf(CGRectGetMaxY(frame)) + textView.textContainerInset.top + textView.textContainerInset.bottom;
    if (CGRectGetMaxY(textView.bounds) < bottom) {
        [textView setContentOffset:CGPointMake(0.0f, bottom - CGRectGetHeight(textView.bounds))];
    }
}


#pragma mark - data management
- (void)changeCurrentUser {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:self.currentUser forKey:@"username"];
    [defaults setObject:self.password forKey:@"password"];
    [defaults setObject:self.uid forKey:@"uid"];
    if (self.signature) {
        [defaults setObject:self.signature forKey:@"signature"];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:BUCLoginStateNotification object:nil];
    [defaults synchronize];
}

- (void)updateSignature {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (!self.signature || self.signature.length == 0) {
        self.signature = @"";
    }
    [defaults setObject:self.signature forKey:@"signature"];
    [self.userSettings setObject:self.signature forKey:@"signature"];
    [self.userList setObject:self.userSettings forKey:[self.currentUser lowercaseString]];
    [defaults setObject:self.userList forKey:@"userList"];
    
    [defaults synchronize];
}

- (IBAction)updateNetworkSetting:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:BUCCampusNetworkSetting];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:BUCNetworkSettingChangedNotification object:nil];
}

- (IBAction)updateInternetImageSetting:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:BUCInternetImageSetting];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:BUCInternetImageSettingChangedNotification object:nil];
}

- (void)updateUserList {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:self.userList forKey:@"userList"];
    
    [defaults synchronize];
}

- (IBAction)resotreSignature:(id)sender {
    [self.signatureEditor resignFirstResponder];
    self.signatureEditor.text = self.signature;
}
- (IBAction)doneUpdateSignature:(id)sender {
    self.signature = self.signatureEditor.text;
    [self updateSignature];
    [self.signatureEditor resignFirstResponder];
}

#pragma mark - Table view data source and delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.list.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    NSDictionary *userSettings = [self.list objectAtIndex:indexPath.row];
    cell.textLabel.text = [userSettings objectForKey:@"username"];
    NSNumber *uidNumber = [userSettings objectForKey:@"uid"];
    NSString *uid = [uidNumber stringValue];
    if ([uid isEqualToString:self.uid]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.list.count == 1) {
        return NO;
    }
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *user = [self.list objectAtIndex:indexPath.row];
        NSString *userKey = [[user objectForKey:@"username"] lowercaseString];
        NSString *uid = ((NSNumber *)[user objectForKey:@"uid"]).stringValue;
        [self.userList removeObjectForKey:userKey];
        [self.list removeObjectAtIndex:indexPath.row];
        if ([uid isEqualToString:self.uid]) {
            NSDictionary *newUser = [self.list firstObject];
            self.currentUser = [newUser objectForKey:@"username"];
            self.password = [newUser objectForKey:@"password"];
            self.uid = ((NSNumber *)[newUser objectForKey:@"uid"]).stringValue;
            self.signature = [newUser objectForKey:@"signature"];
            [self changeCurrentUser];
            [tableView reloadData];
        } else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        [self updateUserList];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        return;
    }
    
    NSDictionary *user = [self.list objectAtIndex:indexPath.row];
    self.currentUser = [user objectForKey:@"username"];
    self.password = [user objectForKey:@"password"];
    self.uid = ((NSNumber *)[user objectForKey:@"uid"]).stringValue;
    self.signature = [user objectForKey:@"signature"];
    self.signatureEditor.text = self.signature;
    [self changeCurrentUser];
    
    [tableView reloadData];
}


#pragma mark - Navigation
- (IBAction)unwindToSettings:(UIStoryboardSegue *)segue {
    [self loadUserData];
    [self.tableView reloadData];
}

- (IBAction)logout:(id)sender {
    [self.rootController displayLogout];
}

@end
