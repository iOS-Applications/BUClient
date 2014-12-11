#import "BUCSettingsController.h"
#import "BUCConstants.h"
#import "BUCAppDelegate.h"

@interface BUCSettingsController ()

@property (nonatomic) NSMutableDictionary *userList;
@property (nonatomic) NSMutableArray *list;
@property (nonatomic) NSString *currentUser;
@property (nonatomic) NSString *uid;
@property (nonatomic) NSString *signature;
@property (nonatomic) BOOL loginStateChanged;
@property (nonatomic) BOOL userListChanged;

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
    self.currentUser = [defaults stringForKey:BUCCurrentUserDefaultKey];
    self.uid = [defaults stringForKey:BUCUidDefaultKey];
    self.signature = [defaults stringForKey:BUCUserSignatureDefaultKey];
    NSDictionary *userList = [defaults objectForKey:BUCUserListDefaultKey];
    self.userList = [NSMutableDictionary dictionaryWithDictionary:userList];
    self.list = [NSMutableArray arrayWithArray:[userList allValues]];
    [self.tableView reloadData];
}


- (void)updateState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (self.loginStateChanged) {
        [defaults setObject:self.currentUser forKey:BUCCurrentUserDefaultKey];
        [defaults setObject:self.uid forKey:BUCUidDefaultKey];
        if (self.signature) {
            [defaults setObject:self.signature forKey:BUCUserSignatureDefaultKey];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:BUCLoginStateNotification object:nil];
        self.loginStateChanged = NO;
        [self updateUI];
    }
    
    if (self.userListChanged) {
        [defaults setObject:self.userList forKey:BUCUserListDefaultKey];
        self.userListChanged = NO;
    }
    [defaults synchronize];
}


- (IBAction)unwindToSettings:(UIStoryboardSegue *)segue {
    if ([segue.identifier isEqualToString:@"addNewAccount"]) {
        [self setup];
    }
    [self.tableView reloadData];
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if (!editing) {
        if (self.userListChanged || self.loginStateChanged) {
            [self updateState];
        }
    }
}


- (void)updateUI {
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSetWithIndex:0];
    [indexSet addIndex:2];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
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
        NSDictionary *userDiction = [self.list objectAtIndex:indexPath.row];
        cell.textLabel.text = [userDiction objectForKey:BUCUserNameDefaultKey];
        NSNumber *uidNumber = [userDiction objectForKey:BUCUidDefaultKey];
        NSString *uid = [uidNumber stringValue];
        if ([uid isEqualToString:self.uid]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
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
        NSString *usernameKey = [[user objectForKey:BUCUserNameDefaultKey] lowercaseString];
        NSString *uid = ((NSNumber *)[user objectForKey:BUCUidDefaultKey]).stringValue;
        [self.userList removeObjectForKey:usernameKey];
        [self.list removeObjectAtIndex:indexPath.row];
        if ([uid isEqualToString:self.uid]) {
            NSDictionary *newUser = [self.list firstObject];
            self.currentUser = [newUser objectForKey:BUCUserNameDefaultKey];
            self.uid = ((NSNumber *)[newUser objectForKey:BUCUidDefaultKey]).stringValue;
            self.signature = [newUser objectForKey:BUCUserSignatureDefaultKey];
            self.loginStateChanged = YES;
        } else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        self.userListChanged = YES;
        [self updateState];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        NSDictionary *user = [self.list objectAtIndex:indexPath.row];
        self.currentUser = [user objectForKey:BUCUserNameDefaultKey];
        self.uid = ((NSNumber *)[user objectForKey:BUCUidDefaultKey]).stringValue;
        self.signature = [user objectForKey:BUCUserSignatureDefaultKey];
        self.loginStateChanged = YES;
        [self updateState];
    } else if (indexPath.section == 3) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        [self.appDelegate displayActionSheet];
    }
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {


}


@end
