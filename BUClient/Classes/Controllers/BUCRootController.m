#import "BUCRootController.h"
#import "BUCDataManager.h"
#import "BUCPostListController.h"
#import "BUCForumListController.h"
#import "BUCAppDelegate.h"


@interface BUCRootController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSString *path;
@property (nonatomic) NSMutableArray *list;
@property (nonatomic) BOOL listChanged;

@property (strong, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) IBOutlet UIView *alertWindow;
@property (weak, nonatomic) IBOutlet UIView *alertView;
@property (weak, nonatomic) IBOutlet UILabel *alertLabel;
@property (weak, nonatomic) IBOutlet UIButton *alertButton;

@property (strong, nonatomic) IBOutlet UIView *actionSheetWindow;
@property (weak, nonatomic) IBOutlet UIView *actionSheet;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *actionSheetBottomSpace;
@property (weak, nonatomic) IBOutlet UIButton *logOut;
@property (weak, nonatomic) IBOutlet UIButton *cancel;

@property (nonatomic) BUCAppDelegate *appDelegate;

@end


@implementation BUCRootController
#pragma mark - setup
- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.appDelegate = (BUCAppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.loadingView.layer.cornerRadius = 10.0f;
    self.loadingView.layer.masksToBounds = YES;
    self.loadingView.translatesAutoresizingMaskIntoConstraints = YES;
    self.loadingView.center = self.appDelegate.window.center;
    self.appDelegate.loadingView = self.loadingView;
    self.appDelegate.activityIndicator = self.activityIndicator;
    [self.appDelegate.window addSubview:self.loadingView];
    
    self.alertWindow.translatesAutoresizingMaskIntoConstraints = YES;
    self.alertWindow.frame = self.appDelegate.window.frame;
    self.alertView.layer.cornerRadius = 8.0f;
    self.alertView.layer.masksToBounds = YES;
    self.appDelegate.alertViewWindow = self.alertWindow;
    self.appDelegate.alertLabel = self.alertLabel;
    [self.alertButton addTarget:self.appDelegate action:@selector(hideAlert) forControlEvents:UIControlEventTouchUpInside];
    [self.appDelegate.window addSubview:self.alertWindow];
    
    self.logOut.layer.cornerRadius = 4.0f;
    self.logOut.layer.masksToBounds = YES;
    [self.logOut addTarget:self action:@selector(commitLogOut) forControlEvents:UIControlEventTouchUpInside];
    self.cancel.layer.cornerRadius = 4.0f;
    self.cancel.layer.masksToBounds = YES;
    [self.cancel addTarget:self action:@selector(cancelLogout) forControlEvents:UIControlEventTouchUpInside];
    self.actionSheetWindow.translatesAutoresizingMaskIntoConstraints = YES;
    self.actionSheetWindow.frame = self.appDelegate.window.frame;
    self.appDelegate.actionSheetWindow = self.actionSheetWindow;
    self.appDelegate.actionSheet = self.actionSheet;
    self.appDelegate.actionSheetBottomSpace = self.actionSheetBottomSpace;
    [self.appDelegate.window addSubview:self.actionSheetWindow];
    
    self.path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingString:@"/BUCFavoriteList.plist"];
    NSString *readPath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.path]) {
        readPath = self.path;
    } else {
        readPath = [self.nibBundle pathForResource:@"data/BUCFavoriteList" ofType:@"plist"];
    }
    self.list = [NSMutableArray arrayWithContentsOfFile:readPath];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.tableView reloadData];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![BUCDataManager sharedInstance].loggedIn) {
        [self performSegueWithIdentifier:@"segueToLogin" sender:nil];
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:NO];
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
}


#pragma mark - table view data source and delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.list.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (indexPath.row == 0) {
        cell.textLabel.textColor = [UIColor orangeColor];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    }

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
- (IBAction)unwindToRoot:(UIStoryboardSegue*)sender {
    if ([sender.identifier isEqualToString:@"addNewForum"]) {
        BUCForumListController *forumList = (BUCForumListController *)sender.sourceViewController;
        if (forumList.selected && ![self duplicate:forumList.selected]) {
            [self.list addObject:forumList.selected];
            [self.list writeToFile:self.path atomically:YES];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathWithIndex:self.list.count]] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}


- (void)commitLogOut {
    [[BUCDataManager sharedInstance] logOut];
    [self.navigationController popViewControllerAnimated:NO];
    [self.appDelegate hideActionSheet];
}


- (void)cancelLogout {
    [self.appDelegate hideActionSheet];
}


- (BOOL)duplicate:(NSDictionary *)forum {
    NSString *newFid = [forum objectForKey:@"fid"];
    for (NSDictionary *item in self.list) {
        NSString *fid = [item objectForKey:@"fid"];
        if (fid && [fid isEqualToString:newFid]) {
            return YES;
        }
    }
    
    return NO;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (![segue.identifier isEqualToString:@"segueToPostList"]) {
        return;
    }
    
    NSIndexPath *indexpath = self.tableView.indexPathForSelectedRow;
    [self.tableView deselectRowAtIndexPath:indexpath animated:NO];
    BUCPostListController *listController = (BUCPostListController *)segue.destinationViewController;
    NSDictionary *forum = [self.list objectAtIndex:indexpath.row];
    NSString *fid = [forum objectForKey:@"fid"];
    NSString *name = [forum objectForKey:@"name"];
    listController.fname = name;
    listController.fid = fid;
}


@end
