#import "BUCForumListController.h"
#import "BUCPostListController.h"

@interface BUCForumListController ()
@property (nonatomic) NSArray *sectionList;
@end

@implementation BUCForumListController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.sectionFooterHeight = 0.0f;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"BUCForumList" ofType:@"plist"];
    self.sectionList = [NSArray arrayWithContentsOfFile:path];
    [self.tableView reloadData];
}


- (IBAction)cancel:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view data source and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *forumSction = [self.sectionList objectAtIndex:section];
    NSArray *forumList = [forumSction objectForKey:@"list"];
    return forumList.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *forumSction = [self.sectionList objectAtIndex:section];
    return [forumSction objectForKey:@"name"];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BUCForumListCell" forIndexPath:indexPath];
    NSDictionary *forumSction = [self.sectionList objectAtIndex:indexPath.section];
    NSArray *forumList = [forumSction objectForKey:@"list"];
    NSDictionary *forum = [forumList objectAtIndex:indexPath.row];
    NSString *name = [forum objectForKey:@"display"];
    if (!name) {
        name = [forum objectForKey:@"name"];
    }
    cell.textLabel.text = name;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    BUCPostListController *postListController = [self.storyboard instantiateViewControllerWithIdentifier:@"BUCPostListController"];
    NSDictionary *forumSction = [self.sectionList objectAtIndex:indexPath.section];
    NSArray *forumList = [forumSction objectForKey:@"list"];
    NSDictionary *forum = [forumList objectAtIndex:indexPath.row];
    postListController.fid = [forum objectForKey:@"fid"];
    postListController.fname = [forum objectForKey:@"name"];
    [(UINavigationController *)self.parentViewController pushViewController:postListController animated:YES];
}


@end




