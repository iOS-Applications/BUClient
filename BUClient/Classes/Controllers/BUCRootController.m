#import "BUCRootController.h"
#import "BUCDataManager.h"
#import "BUCPostListController.h"
#import "BUCForumListController.h"


@interface BUCRootController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSString *path;
@property (nonatomic) NSMutableArray *list;


@end


@implementation BUCRootController
#pragma mark - setup
- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    self.path = [self.nibBundle pathForResource:@"BUCFavouriteList" ofType:@"plist"];
    self.list = [NSMutableArray arrayWithContentsOfFile:self.path];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.tableView reloadData];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![BUCDataManager sharedInstance].loggedIn) {
        [self performSegueWithIdentifier:@"segueToLogin" sender:nil];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:NO animated:YES];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:YES];
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if (!editing) {
        [self.list writeToFile:self.path atomically:YES];
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
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.list writeToFile:self.path atomically:YES];
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
}


#pragma mark - actions and transition
- (IBAction)unwindToRoot:(UIStoryboardSegue*)sender {
    if ([sender.identifier isEqualToString:@"addNewForum"]) {
        BUCForumListController *forumList = (BUCForumListController *)sender.sourceViewController;
        if (forumList.selected && ![self duplicate:forumList.selected]) {
            [self.list addObject:forumList.selected];
            [self.list writeToFile:self.path atomically:YES];
            [self.tableView reloadData];
        }
    }
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
