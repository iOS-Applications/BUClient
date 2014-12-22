#import "BUCRootController.h"
#import "BUCDataManager.h"
#import "BUCPostListController.h"
#import "BUCForumListController.h"
#import "UIImage+BUCImageCategory.h"
#import "BUCAppDelegate.h"


@interface BUCRootController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) BUCAppDelegate *appDelegate;

@property (nonatomic) NSString *path;
@property (nonatomic) NSMutableArray *list;
@property (nonatomic) NSMutableSet *forumSet;
@property (nonatomic) BOOL listChanged;

@property (strong, nonatomic) IBOutlet UIView *logoutWindow;
@property (weak, nonatomic) IBOutlet UIView *logoutSheet;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoutBottomSpace;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelLogout;

@end


@implementation BUCRootController
#pragma mark - setup
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.logoutButton.layer.cornerRadius = 4.0f;
    self.logoutButton.layer.masksToBounds = YES;
    [self.logoutButton setBackgroundImage:[UIImage imageWithColor:[UIColor darkGrayColor]] forState:UIControlStateHighlighted];
    self.cancelLogout.layer.cornerRadius = 4.0f;
    self.cancelLogout.layer.masksToBounds = YES;
    [self.cancelLogout setBackgroundImage:[UIImage imageWithColor:[UIColor darkGrayColor]] forState:UIControlStateHighlighted];
    self.logoutBottomSpace.constant = -CGRectGetHeight(self.logoutSheet.frame);
    self.logoutWindow.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    [window addSubview:self.logoutWindow];
    NSDictionary *views = @{@"logoutWindow": self.logoutWindow};
    [window addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[logoutWindow]|" options:0 metrics:nil views:views]];
    [window addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[logoutWindow]|" options:0 metrics:nil views:views]];
    
    self.path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingString:@"/BUCFavoriteList.plist"];
    NSString *readPath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.path]) {
        readPath = self.path;
    } else {
        readPath = [self.nibBundle pathForResource:@"data/BUCFavoriteList" ofType:@"plist"];
    }
    self.list = [NSMutableArray arrayWithContentsOfFile:readPath];
    self.forumSet = [[NSMutableSet alloc] init];
    for (NSDictionary *forum in self.list) {
        [self.forumSet addObject:[forum objectForKey:@"name"]];
    }
    
    self.editButtonItem.title = @"编辑";
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    [self.tableView reloadData];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:NO animated:NO];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![BUCDataManager sharedInstance].loggedIn && !self.navigationController.presentedViewController) {
        [self.navigationController performSegueWithIdentifier:@"rootToLogin" sender:nil];
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:NO];
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if (!editing && self.listChanged) {
        [self.list writeToFile:self.path atomically:YES];
        self.listChanged = NO;
    }
    if (editing) {
        self.editButtonItem.title = @"完成";
    } else {
        self.editButtonItem.title = @"编辑";
    }
}


#pragma mark - table view data source and delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.list.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    NSString *cellIdentifier;
    if (indexPath.row == 0) {
        cellIdentifier = @"cell";
    } else {
        cellIdentifier = @"cell1";
    }
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    NSDictionary *forum = [self.list objectAtIndex:indexPath.row];
    NSString *name = [forum objectForKey:@"name"];
    cell.textLabel.text = name;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.list removeObjectAtIndex:indexPath.row];
        self.listChanged = YES;
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return NO;
    }
    return YES;
}


- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (proposedDestinationIndexPath.row == 0) {
        return [NSIndexPath indexPathForRow:1 inSection:0];
    }
    
    return proposedDestinationIndexPath;
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSDictionary *forum = [self.list objectAtIndex:fromIndexPath.row];
    [self.list removeObjectAtIndex:fromIndexPath.row];
    [self.list insertObject:forum atIndex:toIndexPath.row];
    self.listChanged = YES;
}


#pragma mark - actions and transition
- (void)displayLogout {
    self.logoutBottomSpace.constant = 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.logoutWindow.alpha = 1.0f;
        [self.logoutWindow layoutIfNeeded];
    }];
}

- (IBAction)logout {
    [self hideLogout];
    [[BUCDataManager sharedInstance] logout];
    [self.navigationController popViewControllerAnimated:NO];
}


- (IBAction)hideLogout {
    self.logoutBottomSpace.constant = -CGRectGetHeight(self.logoutSheet.frame);
    [UIView animateWithDuration:0.3 animations:^{
        self.logoutWindow.alpha = 0.0f;
        [self.logoutWindow layoutIfNeeded];
    }];
}

- (IBAction)gestureHideLogout:(UIGestureRecognizer *)recognizer {
    CGPoint location = [recognizer locationInView:self.logoutSheet];
    if ([self.logoutSheet pointInside:location withEvent:nil]) {
        return;
    } else {
        [self hideLogout];
    }
}


#pragma mark - navigation
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"rootToPostList" sender:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"rootToForumList"]) {
        BUCForumListController *forumList = (BUCForumListController *)(((UINavigationController *)segue.destinationViewController).topViewController);
        forumList.unwindIdentifier = @"forumListToRoot";
    } else if ([segue.identifier isEqualToString:@"rootToPostList"]) {
        NSIndexPath *indexpath = self.tableView.indexPathForSelectedRow;
        [self.tableView deselectRowAtIndexPath:indexpath animated:NO];
        BUCPostListController *postList = (BUCPostListController *)segue.destinationViewController;
        NSDictionary *forum = [self.list objectAtIndex:indexpath.row];
        NSString *fid = [forum objectForKey:@"fid"];
        NSString *name = [forum objectForKey:@"name"];
        postList.fname = name;
        postList.fid = fid;
    }
}


- (IBAction)unwindToRoot:(UIStoryboardSegue*)segue {
    if ([segue.identifier isEqualToString:@"forumListToRoot"]) {
        BUCForumListController *forumList = (BUCForumListController *)segue.sourceViewController;
        NSString *name = [forumList.selected objectForKey:@"name"];
        if (![self.forumSet containsObject:name]) {
            [self.list addObject:forumList.selected];
            [self.forumSet addObject:name];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.list.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            [self.list writeToFile:self.path atomically:YES];
        }
    }
}


@end
