#import "BUCSettingsController.h"
#import "BUCConstants.h"
#import "BUCEditorController.h"
#import "BUCRootController.h"

@interface BUCSettingsController ()

@property (nonatomic) NSMutableDictionary *userList;
@property (nonatomic) NSMutableArray *list;

@property (nonatomic) NSString *currentUser;
@property (nonatomic) NSString *password;
@property (nonatomic) NSString *uid;
@property (nonatomic) NSString *signature;
@property (nonatomic) NSMutableDictionary *userSettings;

@property (nonatomic) BOOL loginStateChanged;
@property (nonatomic) BOOL userListChanged;
@property (nonatomic) BOOL signatureChanged;
@property (nonatomic) NSInteger currentUserRow;

@property (nonatomic) BUCRootController *rootController;


@end

@implementation BUCSettingsController
#pragma mark - setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.rootController = (BUCRootController *)[self.navigationController.viewControllers objectAtIndex:0];
    
    [self setup];
    [self.tableView reloadData];
}


- (void)setup {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userList = [defaults objectForKey:@"userList"];
    self.userList = [NSMutableDictionary dictionaryWithDictionary:userList];
    self.list = [NSMutableArray arrayWithArray:[userList allValues]];
    self.currentUser = [defaults stringForKey:@"username"];
    self.password = [defaults stringForKey:@"password"];
    self.uid = [defaults stringForKey:@"uid"];
    self.signature = [defaults stringForKey:@"signature"];
    self.userSettings = [NSMutableDictionary dictionaryWithDictionary:[self.userList objectForKey:[self.currentUser lowercaseString]]];
}


#pragma mark - editing
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if (!editing) {
        if (self.userListChanged || self.loginStateChanged) {
            [self updateUserSettings];
            [self updateAccountList];
        }
    }
}


- (void)updateUserSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (self.loginStateChanged) {
        [defaults setObject:self.currentUser forKey:@"username"];
        [defaults setObject:self.password forKey:@"password"];
        [defaults setObject:self.uid forKey:@"uid"];
        if (self.signature) {
            [defaults setObject:self.signature forKey:@"signature"];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:BUCLoginStateNotification object:nil];
        self.loginStateChanged = NO;
    }
    
    if (self.userListChanged) {
        if (self.signatureChanged) {
            [defaults setObject:self.signature forKey:@"signature"];
            [self.userSettings setObject:self.signature forKey:@"signature"];
            [self.userList setObject:self.userSettings forKey:[self.currentUser lowercaseString]];
            self.signatureChanged = NO;
        }
        [defaults setObject:self.userList forKey:@"userList"];
        self.userListChanged = NO;
    }
    
    [defaults synchronize];
}


- (void)updateAccountList {
    NSIndexSet *index = [NSIndexSet indexSetWithIndex:0];
    [self.tableView reloadSections:index withRowAnimation:UITableViewRowAnimationNone];
}


- (void)updateSignature {
    NSIndexSet *index = [NSIndexSet indexSetWithIndex:2];
    [self.tableView reloadSections:index withRowAnimation:UITableViewRowAnimationNone];
}


#pragma mark - Table view data source and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.list.count;
    }
    
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier;
    UITableViewCell *cell;
    if (indexPath.section == 0) {
        cellIdentifier = @"cell";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        NSDictionary *userSettings = [self.list objectAtIndex:indexPath.row];
        cell.textLabel.text = [userSettings objectForKey:@"username"];
        NSNumber *uidNumber = [userSettings objectForKey:@"uid"];
        NSString *uid = [uidNumber stringValue];
        if ([uid isEqualToString:self.uid]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            self.currentUserRow = indexPath.row;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else if (indexPath.section == 1) {
        cellIdentifier = @"cell1";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.textLabel.text = @"添加帐号...";
    } else if (indexPath.section == 2) {
        cellIdentifier = @"cell2";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.textLabel.text = self.signature;
    } else {
        cellIdentifier = @"cell3";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.textLabel.text = @"登出";
    }
    
    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"帐号列表";
    } else if (section == 2) {
        return @"个性签名";
    }
    
    return nil;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != 0 || self.list.count == 1) {
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
            self.loginStateChanged = YES;
            [self updateAccountList];
        } else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        self.userListChanged = YES;
        [self updateUserSettings];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        if (indexPath.row == self.currentUserRow) {
            return;
        }
        
        NSDictionary *user = [self.list objectAtIndex:indexPath.row];
        self.currentUser = [user objectForKey:@"username"];
        self.password = [user objectForKey:@"password"];
        self.uid = ((NSNumber *)[user objectForKey:@"uid"]).stringValue;
        self.signature = [user objectForKey:@"signature"];
        self.loginStateChanged = YES;
        [self updateUserSettings];
        [self updateAccountList];
        [self updateSignature];
    } else if (indexPath.section == 3) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        [self.rootController displayLogout];
    }
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"settingsToEditor"]) {
        BUCEditorController *editor = (BUCEditorController *)segue.destinationViewController;
        editor.content = self.signature;
        editor.unwindIdentifier = @"editorToSettings";
        editor.lengthLimit = 100;
        editor.navigationItem.title = @"个性签名";
    }
}


- (IBAction)unwindToSettings:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"loginToSettings"]) {
        [self setup];
        [self updateAccountList];
        [self updateSignature];
    } else if ([segue.identifier isEqualToString:@"editorToSettings"]) {
        BUCEditorController *editor = (BUCEditorController *)segue.sourceViewController;
        self.signature = editor.content;
        self.signatureChanged = YES;
        self.userListChanged = YES;
        [self updateUserSettings];
        [self updateSignature];
    }
}


@end
