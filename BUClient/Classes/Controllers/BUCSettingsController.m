#import "BUCSettingsController.h"
#import "BUCConstants.h"
#import "BUCAppDelegate.h"
#import "BUCEditorController.h"

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

@property (nonatomic) BUCAppDelegate *appDelegate;

@end

@implementation BUCSettingsController
#pragma mark - setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.appDelegate = (BUCAppDelegate *)[UIApplication sharedApplication].delegate;
    
    [self setup];
    [self.tableView reloadData];
}


- (void)setup {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userList = [defaults objectForKey:BUCUserListDefaultKey];
    self.userList = [NSMutableDictionary dictionaryWithDictionary:userList];
    self.list = [NSMutableArray arrayWithArray:[userList allValues]];
    self.currentUser = [defaults stringForKey:BUCCurrentUserDefaultKey];
    self.password = [defaults stringForKey:BUCUserPasswordDefaultKey];
    self.uid = [defaults stringForKey:BUCUidDefaultKey];
    self.signature = [defaults stringForKey:BUCUserSignatureDefaultKey];
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
        [defaults setObject:self.currentUser forKey:BUCCurrentUserDefaultKey];
        [defaults setObject:self.password forKey:BUCUserPasswordDefaultKey];
        [defaults setObject:self.uid forKey:BUCUidDefaultKey];
        if (self.signature) {
            [defaults setObject:self.signature forKey:BUCUserSignatureDefaultKey];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:BUCLoginStateNotification object:nil];
        self.loginStateChanged = NO;
    }
    
    if (self.userListChanged) {
        if (self.signatureChanged) {
            [defaults setObject:self.signature forKey:BUCUserSignatureDefaultKey];
            [self.userSettings setObject:self.signature forKey:BUCUserSignatureDefaultKey];
            [self.userList setObject:self.userSettings forKey:[self.currentUser lowercaseString]];
            self.signatureChanged = NO;
        }
        [defaults setObject:self.userList forKey:BUCUserListDefaultKey];
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
        cell.textLabel.text = [userSettings objectForKey:BUCUserNameDefaultKey];
        NSNumber *uidNumber = [userSettings objectForKey:BUCUidDefaultKey];
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
        cell.textLabel.text = @"Add Account";
    } else if (indexPath.section == 2) {
        cellIdentifier = @"cell2";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.textLabel.text = self.signature;
    } else {
        cellIdentifier = @"cell3";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.textLabel.text = @"Log Out";
    }
    
    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Account List";
    } else if (section == 2) {
        return @"Signature";
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
        NSString *userKey = [[user objectForKey:BUCUserNameDefaultKey] lowercaseString];
        NSString *uid = ((NSNumber *)[user objectForKey:BUCUidDefaultKey]).stringValue;
        [self.userList removeObjectForKey:userKey];
        [self.list removeObjectAtIndex:indexPath.row];
        if ([uid isEqualToString:self.uid]) {
            NSDictionary *newUser = [self.list firstObject];
            self.currentUser = [newUser objectForKey:BUCUserNameDefaultKey];
            self.password = [newUser objectForKey:BUCUserPasswordDefaultKey];
            self.uid = ((NSNumber *)[newUser objectForKey:BUCUidDefaultKey]).stringValue;
            self.signature = [newUser objectForKey:BUCUserSignatureDefaultKey];
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
        self.currentUser = [user objectForKey:BUCUserNameDefaultKey];
        self.password = [user objectForKey:BUCUserPasswordDefaultKey];
        self.uid = ((NSNumber *)[user objectForKey:BUCUidDefaultKey]).stringValue;
        self.signature = [user objectForKey:BUCUserSignatureDefaultKey];
        self.loginStateChanged = YES;
        [self updateUserSettings];
        [self updateAccountList];
        [self updateSignature];
    } else if (indexPath.section == 3) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        [self.appDelegate displayActionSheet];
    }
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"editSignature"]) {
        BUCEditorController *editor = (BUCEditorController *)segue.destinationViewController;
        editor.content = self.signature;
        editor.unwindIdentifier = @"newSignature";
        editor.lengthLimit = 100;
    }
}


- (IBAction)unwindToSettings:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"addNewAccount"]) {
        [self setup];
        [self updateAccountList];
        [self updateSignature];
    } else if ([segue.identifier isEqualToString:@"newSignature"]) {
        BUCEditorController *editor = (BUCEditorController *)segue.sourceViewController;
        self.signature = editor.content;
        self.signatureChanged = YES;
        self.userListChanged = YES;
        [self updateUserSettings];
        [self updateSignature];
    }
}


@end
